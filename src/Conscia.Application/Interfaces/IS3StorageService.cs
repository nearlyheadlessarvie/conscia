namespace Conscia.Application.Interfaces;

public interface IS3StorageService
{
    Task<string> GeneratePresignedUploadUrlAsync(string key, string contentType, int expirationMinutes = 15, CancellationToken ct = default);
    Task<string> GeneratePresignedDownloadUrlAsync(string key, int expirationMinutes = 60, CancellationToken ct = default);
    Task UploadAsync(string key, Stream content, string contentType, CancellationToken ct = default);
    Task<bool> FileExistsAsync(string key, CancellationToken ct = default);
}
