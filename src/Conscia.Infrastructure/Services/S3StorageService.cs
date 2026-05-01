using Amazon.S3;
using Amazon.S3.Model;
using Conscia.Application.Interfaces;
using Microsoft.Extensions.Configuration;

namespace Conscia.Infrastructure.Services;

public class S3StorageService : IS3StorageService
{
    private readonly IAmazonS3 _s3;
    private readonly string _bucketName;

    public S3StorageService(IAmazonS3 s3, IConfiguration config)
    {
        _s3 = s3;
        _bucketName = config["AWS:S3:BucketName"] ?? "conscia-receipts";
    }

    public Task<string> GeneratePresignedUploadUrlAsync(string key, string contentType, int expirationMinutes = 15, CancellationToken ct = default)
    {
        var request = new GetPreSignedUrlRequest
        {
            BucketName = _bucketName,
            Key = key,
            Verb = HttpVerb.PUT,
            Expires = DateTime.UtcNow.AddMinutes(expirationMinutes),
            ContentType = contentType
        };

        return Task.FromResult(_s3.GetPreSignedURL(request));
    }

    public Task<string> GeneratePresignedDownloadUrlAsync(string key, int expirationMinutes = 60, CancellationToken ct = default)
    {
        var request = new GetPreSignedUrlRequest
        {
            BucketName = _bucketName,
            Key = key,
            Verb = HttpVerb.GET,
            Expires = DateTime.UtcNow.AddMinutes(expirationMinutes)
        };

        return Task.FromResult(_s3.GetPreSignedURL(request));
    }

    public async Task<bool> FileExistsAsync(string key, CancellationToken ct = default)
    {
        try
        {
            await _s3.GetObjectMetadataAsync(_bucketName, key, ct);
            return true;
        }
        catch (AmazonS3Exception ex) when (ex.StatusCode == System.Net.HttpStatusCode.NotFound)
        {
            return false;
        }
    }
}
