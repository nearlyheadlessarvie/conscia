using Conscia.Domain.Entities;

namespace Conscia.Application.Interfaces;

public interface IEmailSuppressionRepository
{
    Task<bool> IsSuppressedAsync(string email, CancellationToken ct = default);
    Task UpsertAsync(EmailSuppression suppression, CancellationToken ct = default);
}
