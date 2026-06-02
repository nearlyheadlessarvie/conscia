using Amazon.CDK;
using Amazon.CDK.AWS.Events;
using Amazon.CDK.AWS.Lambda;
using Amazon.CDK.AWS.Route53;
using Amazon.CDK.AWS.SES;
using Constructs;
using LambdaFunctionTarget = Amazon.CDK.AWS.Events.Targets.LambdaFunction;

namespace Conscia.Infra;

public class EmailStackProps : StackProps
{
    public DomainSettings? DomainSettings { get; set; }
    public string FromLocalPart { get; set; } = "invites";
    public IFunction? SesEventHandler { get; set; }
}

public class EmailStack : Stack
{
    public EmailStack(Construct scope, string id, EmailStackProps? props = null)
        : base(scope, id, props)
    {
        props ??= new EmailStackProps();

        if (props.DomainSettings is null)
        {
            new CfnOutput(this, "SesStatus", new CfnOutputProps
            {
                Value = "Domain settings not configured; SES identity skipped."
            });
            return;
        }

        var hostedZone = HostedZone.FromHostedZoneAttributes(this, "HostedZone", new HostedZoneAttributes
        {
            HostedZoneId = props.DomainSettings.HostedZoneId,
            ZoneName = props.DomainSettings.RootDomainName
        });

        var configurationSet = new CfnConfigurationSet(this, "SesConfigurationSet", new CfnConfigurationSetProps
        {
            Name = "conscia-production",
            SuppressionOptions = new CfnConfigurationSet.SuppressionOptionsProperty
            {
                SuppressedReasons = ["BOUNCE", "COMPLAINT"]
            }
        });
        var defaultEventBus = EventBus.FromEventBusName(this, "DefaultEventBus", "default");
        var eventDestination = new CfnConfigurationSetEventDestination(this, "SesBounceComplaintEventDestination", new CfnConfigurationSetEventDestinationProps
        {
            ConfigurationSetName = configurationSet.Name!,
            EventDestination = new CfnConfigurationSetEventDestination.EventDestinationProperty
            {
                Name = "ses-bounce-complaint-eventbridge",
                Enabled = true,
                MatchingEventTypes = ["BOUNCE", "COMPLAINT"],
                EventBridgeDestination = new CfnConfigurationSetEventDestination.EventBridgeDestinationProperty
                {
                    EventBusArn = defaultEventBus.EventBusArn
                }
            }
        });
        eventDestination.AddDependency(configurationSet);

        var identity = new CfnEmailIdentity(this, "SesDomainIdentity", new CfnEmailIdentityProps
        {
            EmailIdentity = props.DomainSettings.RootDomainName,
            ConfigurationSetAttributes = new CfnEmailIdentity.ConfigurationSetAttributesProperty
            {
                ConfigurationSetName = configurationSet.Name
            },
            DkimAttributes = new CfnEmailIdentity.DkimAttributesProperty
            {
                SigningEnabled = true
            },
            FeedbackAttributes = new CfnEmailIdentity.FeedbackAttributesProperty
            {
                EmailForwardingEnabled = true
            },
            MailFromAttributes = new CfnEmailIdentity.MailFromAttributesProperty
            {
                BehaviorOnMxFailure = "REJECT_MESSAGE",
                MailFromDomain = props.DomainSettings.SesMailFromDomain
            }
        });

        identity.AddDependency(configurationSet);
        ConfigureSesEventRouting(defaultEventBus, props.SesEventHandler);
        PublishSesDnsRecords(props.DomainSettings, hostedZone, identity);
        PublishInboxDnsRecords(props.DomainSettings, hostedZone);

        new CfnOutput(this, "SesIdentityName", new CfnOutputProps
        {
            Value = identity.EmailIdentity
        });

        new CfnOutput(this, "SesFromEmail", new CfnOutputProps
        {
            Value = $"{props.FromLocalPart}@{props.DomainSettings.RootDomainName}"
        });

        new CfnOutput(this, "SesConfigurationSetName", new CfnOutputProps
        {
            Value = configurationSet.Name!
        });

        new CfnOutput(this, "SesSuppressionStatus", new CfnOutputProps
        {
            Value = "Configuration set suppresses BOUNCE and COMPLAINT events. Also enable account-level suppression with SESv2 for regional account coverage."
        });

        new CfnOutput(this, "SesMailFromDomain", new CfnOutputProps
        {
            Value = props.DomainSettings.SesMailFromDomain
        });

        new CfnOutput(this, "IcloudInboxStatus", new CfnOutputProps
        {
            Value = HasIcloudInboxRecords(props.DomainSettings)
                ? "iCloud inbox DNS records are configured in Route53."
                : "iCloud inbox DNS records are not configured. Add ICLOUD_INBOX_*_RECORDS_JSON values from Apple Custom Email Domain setup before switching inbox delivery."
        });
    }

    private void PublishSesDnsRecords(
        DomainSettings domainSettings,
        IHostedZone hostedZone,
        CfnEmailIdentity identity)
    {
        CreateCnameRecord(hostedZone, "SesDkimRecord1", identity.GetAtt("DkimDNSTokenName1").ToString(), identity.GetAtt("DkimDNSTokenValue1").ToString());
        CreateCnameRecord(hostedZone, "SesDkimRecord2", identity.GetAtt("DkimDNSTokenName2").ToString(), identity.GetAtt("DkimDNSTokenValue2").ToString());
        CreateCnameRecord(hostedZone, "SesDkimRecord3", identity.GetAtt("DkimDNSTokenName3").ToString(), identity.GetAtt("DkimDNSTokenValue3").ToString());

        new CfnRecordSet(this, "SesMailFromMxRecord", new CfnRecordSetProps
        {
            HostedZoneId = hostedZone.HostedZoneId,
            Name = $"{domainSettings.SesMailFromDomain}.",
            Type = "MX",
            Ttl = "300",
            ResourceRecords =
            [
                $"10 feedback-smtp.{Region}.amazonses.com"
            ]
        });

        new CfnRecordSet(this, "SesMailFromSpfRecord", new CfnRecordSetProps
        {
            HostedZoneId = hostedZone.HostedZoneId,
            Name = $"{domainSettings.SesMailFromDomain}.",
            Type = "TXT",
            Ttl = "300",
            ResourceRecords =
            [
                "\"v=spf1 include:amazonses.com ~all\""
            ]
        });

        new CfnRecordSet(this, "DmarcPolicyRecord", new CfnRecordSetProps
        {
            HostedZoneId = hostedZone.HostedZoneId,
            Name = $"{domainSettings.DmarcRecordName}.{domainSettings.RootDomainName}.",
            Type = "TXT",
            Ttl = "300",
            ResourceRecords =
            [
                QuoteTxt(domainSettings.DmarcValue)
            ]
        });
    }

    private void ConfigureSesEventRouting(IEventBus eventBus, IFunction? sesEventHandler)
    {
        if (sesEventHandler is null)
            return;

        var rule = new Rule(this, "SesBounceComplaintRule", new RuleProps
        {
            EventBus = eventBus,
            EventPattern = new EventPattern
            {
                Source = ["aws.ses"],
                DetailType = ["Email Bounced", "Email Complaint Received"]
            }
        });

        rule.AddTarget(new LambdaFunctionTarget(sesEventHandler));
    }

    private void PublishInboxDnsRecords(DomainSettings domainSettings, IHostedZone hostedZone)
    {
        if (domainSettings.IcloudInboxMxRecords is { Count: > 0 })
        {
            new CfnRecordSet(this, "IcloudInboxMxRecord", new CfnRecordSetProps
            {
                HostedZoneId = hostedZone.HostedZoneId,
                Name = $"{domainSettings.RootDomainName}.",
                Type = "MX",
                Ttl = "300",
                ResourceRecords = domainSettings.IcloudInboxMxRecords
                    .Select(record => $"{record.Priority} {record.Host}")
                    .ToArray()
            });
        }

        if (domainSettings.IcloudInboxTxtRecords is { Count: > 0 })
        {
            var groupedTxtRecords = domainSettings.IcloudInboxTxtRecords
                .GroupBy(record => ToAbsoluteRecordName(record.Name, domainSettings.RootDomainName))
                .ToList();

            for (var index = 0; index < groupedTxtRecords.Count; index++)
            {
                var group = groupedTxtRecords[index];
                new CfnRecordSet(this, $"IcloudInboxTxtRecord{index + 1}", new CfnRecordSetProps
                {
                    HostedZoneId = hostedZone.HostedZoneId,
                    Name = group.Key,
                    Type = "TXT",
                    Ttl = "300",
                    ResourceRecords = group
                        .Select(record => QuoteTxt(record.Value))
                        .ToArray()
                });
            }
        }

        var validIcloudInboxCnameRecords = domainSettings.IcloudInboxCnameRecords?
            .Where(record => !string.IsNullOrWhiteSpace(record.Name) && !string.IsNullOrWhiteSpace(record.Value))
            .ToList();

        if (validIcloudInboxCnameRecords is { Count: > 0 })
        {
            for (var index = 0; index < validIcloudInboxCnameRecords.Count; index++)
            {
                var record = validIcloudInboxCnameRecords[index];
                CreateCnameRecord(
                    hostedZone,
                    $"IcloudInboxCnameRecord{index + 1}",
                    ToAbsoluteRecordName(record.Name, domainSettings.RootDomainName),
                    record.Value);
            }
        }
    }

    private void CreateCnameRecord(IHostedZone hostedZone, string id, string name, string value)
    {
        new CfnRecordSet(this, id, new CfnRecordSetProps
        {
            HostedZoneId = hostedZone.HostedZoneId,
            Name = EnsureTrailingDot(name),
            Type = "CNAME",
            Ttl = "300",
            ResourceRecords =
            [
                value
            ]
        });
    }

    private static bool HasIcloudInboxRecords(DomainSettings domainSettings)
    {
        var hasValidIcloudInboxCnameRecord = domainSettings.IcloudInboxCnameRecords?
            .Any(record => !string.IsNullOrWhiteSpace(record.Name) && !string.IsNullOrWhiteSpace(record.Value))
            ?? false;

        return domainSettings.IcloudInboxMxRecords is { Count: > 0 }
            || domainSettings.IcloudInboxTxtRecords is { Count: > 0 }
            || hasValidIcloudInboxCnameRecord;
    }

    private static string ToAbsoluteRecordName(string name, string rootDomainName)
    {
        if (string.IsNullOrWhiteSpace(name) || name == "@")
        {
            return $"{rootDomainName}.";
        }

        if (name.EndsWith($".{rootDomainName}", StringComparison.OrdinalIgnoreCase))
        {
            return EnsureTrailingDot(name);
        }

        return $"{name}.{rootDomainName}.";
    }

    private static string EnsureTrailingDot(string value)
    {
        return value.EndsWith(".", StringComparison.Ordinal) ? value : $"{value}.";
    }

    private static string QuoteTxt(string value)
    {
        var escaped = value.Replace("\"", "\\\"", StringComparison.Ordinal);
        return $"\"{escaped}\"";
    }
}
