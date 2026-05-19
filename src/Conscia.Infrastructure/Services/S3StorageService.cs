using Amazon.S3;
using Amazon.S3.Model;
using Conscia.Application.Interfaces;
using Microsoft.Extensions.Configuration;

namespace Conscia.Infrastructure.Services;

public class S3StorageService : IS3StorageService
{
    private readonly IAmazonS3 _s3;
    private readonly string _bucketName;
    private readonly bool _ensureBucketExists;
    private readonly SemaphoreSlim _bucketEnsureLock = new(1, 1);
    private bool _bucketReady;

    public S3StorageService(IAmazonS3 s3, IConfiguration config)
    {
        _s3 = s3;
        _bucketName = config["AWS:S3:BucketName"] ?? "conscia-receipts";
        _ensureBucketExists = bool.TryParse(
            config["AWS:S3:EnsureBucketExists"],
            out var ensureBucketExists) && ensureBucketExists;
    }

    public async Task<string> GeneratePresignedUploadUrlAsync(string key, string contentType, int expirationMinutes = 15, CancellationToken ct = default)
    {
        await EnsureBucketReadyAsync(ct);

        var request = new GetPreSignedUrlRequest
        {
            BucketName = _bucketName,
            Key = key,
            Verb = HttpVerb.PUT,
            Expires = DateTime.UtcNow.AddMinutes(expirationMinutes),
            ContentType = contentType
        };

        return _s3.GetPreSignedURL(request);
    }

    public async Task<string> GeneratePresignedDownloadUrlAsync(string key, int expirationMinutes = 60, CancellationToken ct = default)
    {
        await EnsureBucketReadyAsync(ct);

        var request = new GetPreSignedUrlRequest
        {
            BucketName = _bucketName,
            Key = key,
            Verb = HttpVerb.GET,
            Expires = DateTime.UtcNow.AddMinutes(expirationMinutes)
        };

        return _s3.GetPreSignedURL(request);
    }

    public async Task UploadAsync(string key, Stream content, string contentType, CancellationToken ct = default)
    {
        await EnsureBucketReadyAsync(ct);

        using var bufferedContent = await BufferIfNeededAsync(content, ct);
        var uploadStream = bufferedContent ?? content;

        await _s3.PutObjectAsync(new PutObjectRequest
        {
            BucketName = _bucketName,
            Key = key,
            InputStream = uploadStream,
            ContentType = contentType
        }, ct);
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

    private async Task EnsureBucketReadyAsync(CancellationToken ct)
    {
        if (!_ensureBucketExists || _bucketReady)
            return;

        await _bucketEnsureLock.WaitAsync(ct);
        try
        {
            if (_bucketReady)
                return;

            try
            {
                await _s3.GetBucketAclAsync(new GetBucketAclRequest
                {
                    BucketName = _bucketName
                }, ct);
            }
            catch (AmazonS3Exception ex) when (ex.StatusCode == System.Net.HttpStatusCode.NotFound)
            {
                await _s3.PutBucketAsync(new PutBucketRequest
                {
                    BucketName = _bucketName
                }, ct);
            }

            _bucketReady = true;
        }
        finally
        {
            _bucketEnsureLock.Release();
        }
    }

    private static async Task<MemoryStream?> BufferIfNeededAsync(Stream content, CancellationToken ct)
    {
        if (content.CanSeek)
            return null;

        var buffer = new MemoryStream();
        await content.CopyToAsync(buffer, ct);
        buffer.Position = 0;
        return buffer;
    }
}
