using Conscia.Application.DTOs;
using Conscia.Domain.Enums;

namespace Conscia.Application.Interfaces;

public interface ICategoryService
{
    Task<IReadOnlyList<CategoryDto>> ListAsync(
        Guid userId,
        RecordScope scope = RecordScope.Personal,
        Guid? familySpaceId = null,
        bool includeArchived = false,
        CancellationToken ct = default);

    Task<CategoryDto> CreateAsync(Guid userId, CreateCategoryDto dto, CancellationToken ct = default);
    Task<CategoryDto> UpdateAsync(Guid userId, Guid id, UpdateCategoryDto dto, CancellationToken ct = default);
    Task ArchiveAsync(Guid userId, Guid id, CancellationToken ct = default);
}
