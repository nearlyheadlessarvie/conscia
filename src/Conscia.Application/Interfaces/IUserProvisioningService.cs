using Conscia.Application.DTOs;

namespace Conscia.Application.Interfaces;

public interface IUserProvisioningService
{
    Task<AdminUserLookupResponse> ProvisionReviewerAsync(ProvisionReviewerAccountRequest request, CancellationToken ct = default);
}
