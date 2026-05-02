using Amazon.CDK;
using Amazon.CDK.AWS.S3;
using Constructs;

namespace Conscia.Infra;

public class StorageStack : Stack
{
    public IBucket ReceiptBucket { get; }

    public StorageStack(Construct scope, string id, IStackProps? props = null)
        : base(scope, id, props)
    {
        ReceiptBucket = new Bucket(this, "ReceiptBucket", new BucketProps
        {
            BucketName = $"conscia-receipts-{Account}",
            Encryption = BucketEncryption.S3_MANAGED,
            BlockPublicAccess = BlockPublicAccess.BLOCK_ALL,
            RemovalPolicy = RemovalPolicy.DESTROY,
            AutoDeleteObjects = true,
            Cors =
            [
                new CorsRule
                {
                    AllowedMethods = [HttpMethods.PUT, HttpMethods.GET],
                    AllowedOrigins = ["*"],
                    AllowedHeaders = ["*"],
                    MaxAge = 3600
                }
            ],
            LifecycleRules =
            [
                new LifecycleRule
                {
                    Id = "TransitionToIA",
                    Transitions =
                    [
                        new Transition
                        {
                            StorageClass = StorageClass.INFREQUENT_ACCESS,
                            TransitionAfter = Duration.Days(90)
                        }
                    ]
                },
                new LifecycleRule
                {
                    Id = "DeleteReceiptImages",
                    Prefix = "receipts/",
                    Expiration = Duration.Days(1)
                }
            ]
        });
    }
}
