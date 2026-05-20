using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Conscia.Application.Interfaces;
using Conscia.Application.Models;
using Conscia.Domain.Entities;
using Conscia.Domain.Enums;
using Conscia.Domain.ValueObjects;
using Conscia.Tests.Unit.Infrastructure;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.IdentityModel.Tokens;
using Moq;

namespace Conscia.Tests.Unit.Api;

public class TestWebAppFactory : WebApplicationFactory<Program>
{
    public Mock<IUserService> UserServiceMock { get; } = new();
    public Mock<IBudgetService> BudgetServiceMock { get; } = new();
    public Mock<ITransactionService> TransactionServiceMock { get; } = new();
    public Mock<IRecurringScheduleService> RecurringScheduleServiceMock { get; } = new();
    public Mock<IFamilySpaceService> FamilySpaceServiceMock { get; } = new();
    public Mock<ICategoryService> CategoryServiceMock { get; } = new();
    public Mock<IFamilySpaceRepository> FamilySpaceRepoMock { get; } = new();
    public Mock<ICategoryRepository> CategoryRepoMock { get; } = new();
    public Mock<IBudgetRepository> BudgetRepoMock { get; } = new();
    public Mock<ITransactionRepository> TransactionRepoMock { get; } = new();
    public Mock<IRecurringScheduleRepository> RecurringScheduleRepoMock { get; } = new();
    public Mock<ISubscriptionService> SubscriptionServiceMock { get; } = new();
    public Mock<IAIService> AIServiceMock { get; } = new();
    public Mock<IInAppAlertRepository> AlertRepoMock { get; } = new();
    public Mock<IAlertService> AlertServiceMock { get; } = new();
    public Mock<IPushDeviceTokenRepository> PushDeviceTokenRepoMock { get; } = new();
    public Mock<IAIInteractionRepository> AIInteractionRepoMock { get; } = new();
    public Mock<IExchangeRateService> ExchangeRateServiceMock { get; } = new();
    public Mock<IConscienceJourneyService> ConscienceJourneyServiceMock { get; } = new();
    public Mock<IConscienceJourneyRepository> ConscienceJourneyRepoMock { get; } = new();
    public Mock<IWeeklyInsightsRepository> WeeklyInsightsRepoMock { get; } = new();
    public Mock<IPurchasePatternRepository> PurchasePatternRepoMock { get; } = new();
    public Mock<IMonthlyCategorySpendRepository> MonthlyCategorySpendRepoMock { get; } = new();
    public Mock<IS3StorageService> S3StorageServiceMock { get; } = new();
    public InMemoryUserRepository UserRepo { get; } = new();

    private const string SigningKey = "this-is-a-test-signing-key-at-least-32-chars!!";

    public HttpClient CreateRawClient() => base.CreateClient();

    public new HttpClient CreateClient()
    {
        var client = CreateRawClient();
        client.DefaultRequestHeaders.Add("X-Api-Version", "1");
        client.DefaultRequestHeaders.Add("X-Conscia-App-Version", "1.0.0+1");
        return client;
    }

    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        builder.UseEnvironment("Development");

        builder.ConfigureServices(services =>
        {
            ReplaceService<IUserService>(services, UserServiceMock.Object);
            ReplaceService<IUserRepository>(services, UserRepo);
            ReplaceService<IBudgetService>(services, BudgetServiceMock.Object);
            ReplaceService<ITransactionService>(services, TransactionServiceMock.Object);
            ReplaceService<IRecurringScheduleService>(services, RecurringScheduleServiceMock.Object);
            ReplaceService<IFamilySpaceService>(services, FamilySpaceServiceMock.Object);
            ReplaceService<ICategoryService>(services, CategoryServiceMock.Object);
            ReplaceService<IFamilySpaceRepository>(services, FamilySpaceRepoMock.Object);
            ReplaceService<ICategoryRepository>(services, CategoryRepoMock.Object);
            ReplaceService<IBudgetRepository>(services, BudgetRepoMock.Object);
            ReplaceService<ITransactionRepository>(services, TransactionRepoMock.Object);
            ReplaceService<IRecurringScheduleRepository>(services, RecurringScheduleRepoMock.Object);
            ReplaceService<ISubscriptionService>(services, SubscriptionServiceMock.Object);
            ReplaceService<IAIService>(services, AIServiceMock.Object);
            ReplaceService<IInAppAlertRepository>(services, AlertRepoMock.Object);
            ReplaceService<IAlertService>(services, AlertServiceMock.Object);
            ReplaceService<IPushDeviceTokenRepository>(services, PushDeviceTokenRepoMock.Object);
            ReplaceService<IAIInteractionRepository>(services, AIInteractionRepoMock.Object);
            ReplaceService<IExchangeRateService>(services, ExchangeRateServiceMock.Object);
            ReplaceService<IConscienceJourneyService>(services, ConscienceJourneyServiceMock.Object);
            ReplaceService<IConscienceJourneyRepository>(services, ConscienceJourneyRepoMock.Object);
            ReplaceService<IWeeklyInsightsRepository>(services, WeeklyInsightsRepoMock.Object);
            ReplaceService<IPurchasePatternRepository>(services, PurchasePatternRepoMock.Object);
            ReplaceService<IMonthlyCategorySpendRepository>(services, MonthlyCategorySpendRepoMock.Object);
            ReplaceService<IS3StorageService>(services, S3StorageServiceMock.Object);
        });

        builder.UseSetting("Auth:UseMock", "true");
        builder.UseSetting("Auth:MockSigningKey", SigningKey);
        builder.UseSetting("AWS:DynamoDB:ServiceURL", "http://localhost:8000");
        builder.UseSetting("AWS:S3:ServiceURL", "http://localhost:9000");
        builder.UseSetting("AWS:S3:ForcePathStyle", "true");
        builder.UseSetting("AWS:SQS:ServiceURL", "http://localhost:9324");
        builder.UseSetting("AppCompatibility:CurrentSupportedAppVersion", "1.0.0+1");
        builder.UseSetting("AppCompatibility:PreviousSupportedAppVersion", "1.0.0+1");
    }

    public string GenerateTestToken(string userId = "a1b2c3d4-0001-4000-8000-000000000001",
        string email = "alice@example.com", string tier = "Premium")
    {
        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(SigningKey));
        var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);
        var claims = new[]
        {
            new Claim(ClaimTypes.NameIdentifier, userId),
            new Claim(ClaimTypes.Email, email),
            new Claim("tier", tier)
        };

        var token = new JwtSecurityToken(
            issuer: "conscia-mock",
            audience: "conscia-api",
            claims: claims,
            expires: DateTime.UtcNow.AddHours(1),
            signingCredentials: creds);

        return new JwtSecurityTokenHandler().WriteToken(token);
    }

    private static void ReplaceService<T>(IServiceCollection services, T implementation) where T : class
    {
        var descriptor = services.FirstOrDefault(d => d.ServiceType == typeof(T));
        if (descriptor is not null) services.Remove(descriptor);
        services.AddScoped(_ => implementation);
    }
}
