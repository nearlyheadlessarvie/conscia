using Amazon.CDK;
using Amazon.CDK.AWS.S3;
using Amazon.CDK.AWS.CertificateManager;
using Amazon.CDK.AWS.CloudFront;
using Amazon.CDK.AWS.CloudFront.Origins;
using Amazon.CDK.AWS.Route53;
using Amazon.CDK.AWS.Route53.Targets;
using Constructs;

namespace Conscia.Infra;

public class WebStackProps : StackProps
{
    public DomainSettings? DomainSettings { get; set; }
}

public class WebStack : Stack
{
    public WebStack(Construct scope, string id, WebStackProps? props = null)
        : base(scope, id, props)
    {
        props ??= new WebStackProps();

        var websiteBucket = new Bucket(this, "WebsiteBucket", new BucketProps
        {
            BucketName = $"conscia-website-{Account}",
            BlockPublicAccess = BlockPublicAccess.BLOCK_ALL,
            RemovalPolicy = RemovalPolicy.DESTROY,
            AutoDeleteObjects = true,
            Encryption = BucketEncryption.S3_MANAGED
        });

        var directoryIndexRewrite = new Function(this, "DirectoryIndexRewrite", new FunctionProps
        {
            Code = FunctionCode.FromInline(
                """
                function handler(event) {
                  var request = event.request;
                  var uri = request.uri;

                  if (uri.startsWith('/.well-known/')) {
                    return request;
                  }

                  if (uri.endsWith('/')) {
                    request.uri = uri + 'index.html';
                    return request;
                  }

                  if (!uri.includes('.')) {
                    request.uri = uri + '/index.html';
                  }

                  return request;
                }
                """)
        });

        var distributionProps = new DistributionProps
        {
            DefaultBehavior = new BehaviorOptions
            {
                Origin = S3BucketOrigin.WithOriginAccessControl(websiteBucket),
                ViewerProtocolPolicy = ViewerProtocolPolicy.REDIRECT_TO_HTTPS,
                CachePolicy = CachePolicy.CACHING_OPTIMIZED,
                AllowedMethods = AllowedMethods.ALLOW_GET_HEAD,
                Compress = true,
                FunctionAssociations =
                [
                    new FunctionAssociation
                    {
                        EventType = FunctionEventType.VIEWER_REQUEST,
                        Function = directoryIndexRewrite
                    }
                ]
            },
            DefaultRootObject = "index.html",
            ErrorResponses = new[]
            {
                new ErrorResponse
                {
                    HttpStatus = 404,
                    ResponseHttpStatus = 200,
                    ResponsePagePath = "/index.html",
                    Ttl = Duration.Seconds(0)
                },
                new ErrorResponse
                {
                    HttpStatus = 403,
                    ResponseHttpStatus = 200,
                    ResponsePagePath = "/index.html",
                    Ttl = Duration.Seconds(0)
                }
            },
            PriceClass = PriceClass.PRICE_CLASS_100,
            Comment = "Conscia Marketing Site (getconscia.com)"
        };

        IHostedZone? hostedZone = null;
        if (props.DomainSettings is not null)
        {
            hostedZone = HostedZone.FromHostedZoneAttributes(this, "HostedZone", new HostedZoneAttributes
            {
                HostedZoneId = props.DomainSettings.HostedZoneId,
                ZoneName = props.DomainSettings.RootDomainName
            });

            var certificate = new DnsValidatedCertificate(this, "WebsiteCertificate", new DnsValidatedCertificateProps
            {
                DomainName = props.DomainSettings.RootDomainName,
                SubjectAlternativeNames = [props.DomainSettings.WwwDomainName],
                HostedZone = hostedZone,
                Region = "us-east-1",
                CleanupRoute53Records = true
            });

            distributionProps.Certificate = certificate;
            distributionProps.DomainNames = props.DomainSettings.WebDomainNames;
        }

        var distribution = new Distribution(this, "WebsiteDistribution", distributionProps);

        if (hostedZone is not null && props.DomainSettings is not null)
        {
            foreach (var domainName in props.DomainSettings.WebDomainNames)
            {
                new ARecord(this, $"WebsiteAlias{SanitizeId(domainName)}", new ARecordProps
                {
                    Zone = hostedZone,
                    RecordName = domainName,
                    Target = RecordTarget.FromAlias(new CloudFrontTarget(distribution))
                });
            }
        }

        new CfnOutput(this, "WebsiteBucketName", new CfnOutputProps
        {
            Value = websiteBucket.BucketName,
            Description = "S3 bucket for marketing site",
            ExportName = "ConsciWebBucket"
        });

        new CfnOutput(this, "DistributionId", new CfnOutputProps
        {
            Value = distribution.DistributionId,
            Description = "CloudFront distribution ID",
            ExportName = "ConsciaWebDistributionId"
        });

        new CfnOutput(this, "DistributionDomainName", new CfnOutputProps
        {
            Value = distribution.DistributionDomainName,
            Description = "CloudFront domain name",
            ExportName = "ConsciaWebDomain"
        });
    }

    private static string SanitizeId(string value)
    {
        return value.Replace(".", string.Empty).Replace("-", string.Empty);
    }
}
