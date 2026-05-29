using Conscia.Application.Interfaces;
using Conscia.Domain.Entities;

namespace Conscia.Infrastructure.Services;

public sealed class NoOpUserIdentityDeletionService : IUserIdentityDeletionService
{
    public Task DeleteUserAsync(User user, CancellationToken ct = default) =>
        Task.CompletedTask;
}
