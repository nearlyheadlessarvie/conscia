using Amazon.CDK;
using Amazon.CDK.AWS.SES;
using Constructs;

namespace Conscia.Infra;

public class EmailStackProps : StackProps
{
    public DomainSettings? DomainSettings { get; set; }
    public string FromLocalPart { get; set; } = "invites";
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

        var configurationSet = new CfnConfigurationSet(this, "SesConfigurationSet", new CfnConfigurationSetProps
        {
            Name = "conscia-production"
        });

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
            }
        });

        identity.AddDependency(configurationSet);

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
    }
}
