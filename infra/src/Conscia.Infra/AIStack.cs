using Amazon.CDK;
using Amazon.CDK.AWS.SQS;
using Constructs;

namespace Conscia.Infra;

public class AIStack : Stack
{
    public IQueue AiQueue { get; }
    public IQueue AiDlq { get; }

    public AIStack(Construct scope, string id, IStackProps? props = null)
        : base(scope, id, props)
    {
        AiDlq = new Queue(this, "AiDlq", new QueueProps
        {
            QueueName = "conscia-ai-dlq",
            RetentionPeriod = Duration.Days(14),
            Encryption = QueueEncryption.SQS_MANAGED
        });

        AiQueue = new Queue(this, "AiQueue", new QueueProps
        {
            QueueName = "conscia-ai-queue",
            VisibilityTimeout = Duration.Seconds(90),
            RetentionPeriod = Duration.Days(7),
            Encryption = QueueEncryption.SQS_MANAGED,
            DeadLetterQueue = new DeadLetterQueue
            {
                Queue = AiDlq,
                MaxReceiveCount = 3
            }
        });
    }
}
