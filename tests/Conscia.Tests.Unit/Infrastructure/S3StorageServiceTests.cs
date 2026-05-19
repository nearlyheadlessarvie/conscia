using System.Net;
using Amazon.S3;
using Amazon.S3.Model;
using Conscia.Infrastructure.Services;
using Microsoft.Extensions.Configuration;
using Moq;

namespace Conscia.Tests.Unit.Infrastructure;

public class S3StorageServiceTests
{
    [Fact]
    public async Task GeneratePresignedUploadUrlAsync_CreatesBucket_WhenConfiguredAndMissing()
    {
        var s3 = new Mock<IAmazonS3>();
        s3.Setup(client => client.GetBucketAclAsync(
                It.Is<GetBucketAclRequest>(request => request.BucketName == "conscia-receipts"),
                It.IsAny<CancellationToken>()))
            .ThrowsAsync(new AmazonS3Exception("not found")
            {
                StatusCode = HttpStatusCode.NotFound
            });
        s3.Setup(client => client.PutBucketAsync(
                It.Is<PutBucketRequest>(request => request.BucketName == "conscia-receipts"),
                It.IsAny<CancellationToken>()))
            .ReturnsAsync(new PutBucketResponse());
        s3.Setup(client => client.GetPreSignedURL(It.IsAny<GetPreSignedUrlRequest>()))
            .Returns("http://localhost:9000/conscia-receipts/profile-pictures/avatar.png");

        var service = new S3StorageService(s3.Object, BuildConfig(
            ("AWS:S3:BucketName", "conscia-receipts"),
            ("AWS:S3:EnsureBucketExists", "true")));

        var url = await service.GeneratePresignedUploadUrlAsync(
            "profile-pictures/user/avatar.png",
            "image/png");

        Assert.Equal("http://localhost:9000/conscia-receipts/profile-pictures/avatar.png", url);
        s3.Verify(client => client.PutBucketAsync(
            It.Is<PutBucketRequest>(request => request.BucketName == "conscia-receipts"),
            It.IsAny<CancellationToken>()), Times.Once);
    }

    [Fact]
    public async Task GeneratePresignedUploadUrlAsync_DoesNotCreateBucket_WhenDisabled()
    {
        var s3 = new Mock<IAmazonS3>();
        s3.Setup(client => client.GetPreSignedURL(It.IsAny<GetPreSignedUrlRequest>()))
            .Returns("http://localhost:9000/conscia-receipts/profile-pictures/avatar.png");

        var service = new S3StorageService(s3.Object, BuildConfig(
            ("AWS:S3:BucketName", "conscia-receipts"),
            ("AWS:S3:EnsureBucketExists", "false")));

        await service.GeneratePresignedUploadUrlAsync(
            "profile-pictures/user/avatar.png",
            "image/png");

        s3.Verify(client => client.PutBucketAsync(
            It.IsAny<PutBucketRequest>(),
            It.IsAny<CancellationToken>()), Times.Never);
    }

    [Fact]
    public async Task UploadAsync_BuffersNonSeekableStreamsBeforePuttingObject()
    {
        var sawSeekableUploadStream = false;
        var s3 = new Mock<IAmazonS3>();
        s3.Setup(client => client.PutObjectAsync(
                It.IsAny<PutObjectRequest>(),
                It.IsAny<CancellationToken>()))
            .Callback<PutObjectRequest, CancellationToken>((request, _) =>
            {
                sawSeekableUploadStream = request.InputStream.CanSeek &&
                    request.InputStream.Length == 4 &&
                    request.InputStream.Position == 0;
            })
            .ReturnsAsync(new PutObjectResponse());

        var service = new S3StorageService(s3.Object, BuildConfig(
            ("AWS:S3:BucketName", "conscia-receipts"),
            ("AWS:S3:EnsureBucketExists", "false")));

        await using var stream = new NonSeekableReadStream([1, 2, 3, 4]);
        await service.UploadAsync(
            "profile-pictures/user/avatar.png",
            stream,
            "image/png");

        Assert.True(sawSeekableUploadStream);
    }

    private static IConfiguration BuildConfig(params (string Key, string Value)[] values)
    {
        return new ConfigurationBuilder()
            .AddInMemoryCollection(values.Select(value =>
                new KeyValuePair<string, string?>(value.Key, value.Value)))
            .Build();
    }

    private sealed class NonSeekableReadStream : MemoryStream
    {
        public NonSeekableReadStream(byte[] buffer) : base(buffer)
        {
        }

        public override bool CanSeek => false;

        public override long Length =>
            throw new NotSupportedException("This stream does not support seeking.");

        public override long Position
        {
            get => base.Position;
            set => throw new NotSupportedException("This stream does not support seeking.");
        }

        public override long Seek(long offset, SeekOrigin loc) =>
            throw new NotSupportedException("This stream does not support seeking.");
    }
}
