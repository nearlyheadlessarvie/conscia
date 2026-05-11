using Conscia.Domain.Entities;

namespace Conscia.Application.Interfaces;

public interface IFamilySpaceService
{
    Task<FamilySpace> CreateAsync(Guid userId, string name, string currencyCode, CancellationToken ct = default);
}
