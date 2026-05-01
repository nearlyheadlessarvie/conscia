namespace Conscia.Domain.Enums;

public enum OutboxEventType
{
    TransactionCreated,
    TransactionDeleted,
    TransactionUpdated
}
