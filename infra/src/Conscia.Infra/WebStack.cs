using Amazon.CDK;
using Amazon.CDK.AWS.S3;
using Amazon.CDK.AWS.CloudFront;
using Amazon.CDK.AWS.CloudFront.Origins;
using Constructs;

namespace Conscia.Infra;

public class WebStack : Stack
{
    public WebStack(Construct scope, string id, IStackProps? props = null)
        : base(scope, id, props)
    {
        var websiteBucket = new Bucket(this, "WebsiteBucket", new BucketProps
        {
            BucketName = $"conscia-website-{Account}",
            BlockPublicAccess = BlockPublicAccess.BLOCK_ALL,
            RemovalPolicy = RemovalPolicy.DESTROY,
            AutoDeleteObjects = true,
            Encryption = BucketEncryption.S3_MANAGED
        });

        var distribution = new Distribution(this, "WebsiteDistribution", new DistributionProps
        {
            DefaultBehavior = new BehaviorOptions
            {
                Origin = S3BucketOrigin.WithOriginAccessControl(websiteBucket),
                ViewerProtocolPolicy = ViewerProtocolPolicy.REDIRECT_TO_HTTPS,
                CachePolicy = CachePolicy.CACHING_OPTIMIZED,
                AllowedMethods = AllowedMethods.ALLOW_GET_HEAD,
                Compress = true
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
        });

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
}
