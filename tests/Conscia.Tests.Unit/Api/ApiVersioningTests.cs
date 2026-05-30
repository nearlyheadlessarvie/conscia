using Conscia.Api.Configuration;
using System.Net;
using System.Net.Http.Headers;
using System.Text.Json;

namespace Conscia.Tests.Unit.Api;

public class ApiVersioningTests : IClassFixture<TestWebAppFactory>
{
    private readonly TestWebAppFactory _factory;

    public ApiVersioningTests(TestWebAppFactory factory)
    {
        _factory = factory;
    }

    [Fact]
    public async Task ApiRoot_ReturnsOk_WhenVersionIsProvidedByQuery()
    {
        using var client = _factory.CreateRawClient();

        var response = await client.GetAsync("/api?v=1");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    [Fact]
    public async Task ApiRoot_ReturnsBadRequest_WhenVersionIsMissing()
    {
        using var client = _factory.CreateRawClient();

        var response = await client.GetAsync("/api");

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task ApiRoot_ReturnsOk_WhenVersionIsProvidedByHeader()
    {
        using var client = _factory.CreateRawClient();
        using var request = new HttpRequestMessage(HttpMethod.Get, "/api");
        request.Headers.Add("X-Api-Version", "1");

        var response = await client.SendAsync(request);

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    [Fact]
    public async Task VersionJson_ReturnsPublishedMetadataFile_WithoutApiVersion()
    {
        var metadataPath = Path.Combine(AppContext.BaseDirectory, "version.json");
        var hadOriginal = File.Exists(metadataPath);
        var originalContents = hadOriginal ? await File.ReadAllTextAsync(metadataPath) : null;
        await File.WriteAllTextAsync(
            metadataPath,
            "{\"service\":\"conscia-api\",\"version\":\"1.2.3\",\"commitSha\":\"abc123def456\",\"deployedAt\":\"2026-05-27T12:34:56Z\"}");

        using var client = _factory.CreateRawClient();
        try
        {
            var response = await client.GetAsync("/version.json");

            Assert.Equal(HttpStatusCode.OK, response.StatusCode);

            using var payload = JsonDocument.Parse(await response.Content.ReadAsStringAsync());
            Assert.Equal("conscia-api", payload.RootElement.GetProperty("service").GetString());
            Assert.Equal("1.2.3", payload.RootElement.GetProperty("version").GetString());
            Assert.Equal("abc123def456", payload.RootElement.GetProperty("commitSha").GetString());
            Assert.Equal("2026-05-27T12:34:56Z", payload.RootElement.GetProperty("deployedAt").GetString());
        }
        finally
        {
            if (hadOriginal)
            {
                await File.WriteAllTextAsync(metadataPath, originalContents!);
            }
            else if (File.Exists(metadataPath))
            {
                File.Delete(metadataPath);
            }
        }
    }

    [Fact]
    public async Task VersionMetadataResolver_FallsBack_WhenMetadataFileIsEmpty()
    {
        var metadataPath = Path.Combine(AppContext.BaseDirectory, "version.json");
        var hadOriginal = File.Exists(metadataPath);
        var originalContents = hadOriginal ? await File.ReadAllTextAsync(metadataPath) : null;
        await File.WriteAllTextAsync(metadataPath, string.Empty);

        try
        {
            var metadata = VersionMetadataResolver.Resolve();

            Assert.Equal("conscia-api", metadata.Service);
            Assert.NotEmpty(metadata.Version);
        }
        finally
        {
            if (hadOriginal)
            {
                await File.WriteAllTextAsync(metadataPath, originalContents!);
            }
            else if (File.Exists(metadataPath))
            {
                File.Delete(metadataPath);
            }
        }
    }
}
