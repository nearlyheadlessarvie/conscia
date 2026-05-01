namespace Conscia.Application.Interfaces;

public interface ISqsQueueService
{
    Task<string> PublishAsync(string queueName, string messageBody, CancellationToken ct = default);
    Task<QueueMessage?> ReceiveAsync(string queueName, int waitTimeSeconds = 5, CancellationToken ct = default);
    Task DeleteAsync(string queueName, string receiptHandle, CancellationToken ct = default);
}

public record QueueMessage(string MessageId, string Body, string ReceiptHandle);
