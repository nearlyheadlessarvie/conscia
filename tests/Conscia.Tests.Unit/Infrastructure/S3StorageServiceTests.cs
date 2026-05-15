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

    private static IConfiguration BuildConfig(params (string Key, string Value)[] values)
    {
        return new ConfigurationBuilder()
            .AddInMemoryCollection(values.Select(value =>
                new KeyValuePair<string, string?>(value.Key, value.Value)))
            .Build();
    }
}
