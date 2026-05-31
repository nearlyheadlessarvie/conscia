namespace Conscia.Application.Interfaces;

public interface IUserDataErasureService
{
    Task EraseUserDataAsync(Guid userId, CancellationToken ct = default);
}
