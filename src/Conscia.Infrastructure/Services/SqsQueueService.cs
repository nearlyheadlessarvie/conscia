using Amazon.SQS;
using Amazon.SQS.Model;
using Conscia.Application.Interfaces;

namespace Conscia.Infrastructure.Services;

public class SqsQueueService : ISqsQueueService
{
    private readonly IAmazonSQS _sqs;

    public SqsQueueService(IAmazonSQS sqs) => _sqs = sqs;

    public async Task<string> PublishAsync(string queueName, string messageBody, CancellationToken ct = default)
    {
        var queueUrl = await GetQueueUrlAsync(queueName, ct);
        var response = await _sqs.SendMessageAsync(new SendMessageRequest
        {
            QueueUrl = queueUrl,
            MessageBody = messageBody
        }, ct);

        return response.MessageId;
    }

    public async Task<QueueMessage?> ReceiveAsync(string queueName, int waitTimeSeconds = 5, CancellationToken ct = default)
    {
        var queueUrl = await GetQueueUrlAsync(queueName, ct);
        var response = await _sqs.ReceiveMessageAsync(new ReceiveMessageRequest
        {
            QueueUrl = queueUrl,
            MaxNumberOfMessages = 1,
            WaitTimeSeconds = waitTimeSeconds
        }, ct);

        var msg = response.Messages.FirstOrDefault();
        if (msg is null) return null;

        return new QueueMessage(msg.MessageId, msg.Body, msg.ReceiptHandle);
    }

    public async Task DeleteAsync(string queueName, string receiptHandle, CancellationToken ct = default)
    {
        var queueUrl = await GetQueueUrlAsync(queueName, ct);
        await _sqs.DeleteMessageAsync(new DeleteMessageRequest
        {
            QueueUrl = queueUrl,
            ReceiptHandle = receiptHandle
        }, ct);
    }

    private async Task<string> GetQueueUrlAsync(string queueName, CancellationToken ct)
    {
        var response = await _sqs.GetQueueUrlAsync(new GetQueueUrlRequest { QueueName = queueName }, ct);
        return response.QueueUrl;
    }
}
