using Amazon.CDK;
using Amazon.CDK.AWS.S3;
using Constructs;

namespace Conscia.Infra;

public class StorageStackProps : StackProps
{
    public string[] AllowedCorsOrigins { get; set; } = ["*"];
}

public class StorageStack : Stack
{
    public IBucket ReceiptBucket { get; }

    public StorageStack(Construct scope, string id, StorageStackProps? props = null)
        : base(scope, id, props)
    {
        props ??= new StorageStackProps();

        ReceiptBucket = new Bucket(this, "ReceiptBucket", new BucketProps
        {
            BucketName = $"conscia-receipts-{Account}",
            Encryption = BucketEncryption.S3_MANAGED,
            BlockPublicAccess = BlockPublicAccess.BLOCK_ALL,
            RemovalPolicy = RemovalPolicy.RETAIN,
            AutoDeleteObjects = false,
            Cors =
            [
                new CorsRule
                {
                    AllowedMethods = [HttpMethods.PUT, HttpMethods.GET],
                    AllowedOrigins = props.AllowedCorsOrigins,
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
