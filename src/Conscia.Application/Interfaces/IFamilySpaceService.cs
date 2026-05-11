using Conscia.Application.DTOs;
using Conscia.Domain.Entities;

namespace Conscia.Application.Interfaces;

public interface IFamilySpaceService
{
    Task<FamilySpace> CreateAsync(Guid userId, string name, string currencyCode, CancellationToken ct = default);
    Task<FamilySpaceDto?> GetCurrentAsync(Guid userId, CancellationToken ct = default);
}
