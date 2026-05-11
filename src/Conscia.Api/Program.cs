using System.IdentityModel.Tokens.Jwt;
using System.Text;
using System.Text.Json;
using System.Text.Json.Serialization;
using Amazon;
using Amazon.BedrockRuntime;
using Amazon.CognitoIdentityProvider;
using Amazon.DynamoDBv2;
using Amazon.Lambda;
using Amazon.Runtime;
using Amazon.S3;
using Amazon.SQS;
using Conscia.AI.Services;
using Conscia.Api.Endpoints;
using Conscia.Api.Health;
using System.Threading.RateLimiting;
using Microsoft.AspNetCore.RateLimiting;
using Conscia.Api.Middleware;
using Conscia.Application.Configuration;
using Conscia.Application.Interfaces;
using Conscia.Application.Services;
using Conscia.Application.Triggers;
using Conscia.Application.Validators;
using Conscia.Infrastructure.Db.LambdaProxy;
using Conscia.Infrastructure.Persistence;
using Conscia.Infrastructure.Repositories;
using Conscia.Infrastructure.Services;
using FluentValidation;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Diagnostics.HealthChecks;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Diagnostics.HealthChecks;
using Microsoft.IdentityModel.Tokens;
using OpenTelemetry.Metrics;
using OpenTelemetry.Trace;
using Serilog;
using Serilog.Formatting.Compact;

var builder = WebApplication.CreateBuilder(args);

builder.Host.UseSerilog((context, config) =>
{
    config
        .ReadFrom.Configuration(context.Configuration)
        .Enrich.FromLogContext()
        .Enrich.WithCorrelationId()
        .Enrich.WithProperty("ServiceName", "conscia-api")
        .Enrich.WithProperty("Environment", context.HostingEnvironment.EnvironmentName);

    if (context.HostingEnvironment.IsDevelopment())
        config.WriteTo.Console();
    else
        config.WriteTo.Console(new CompactJsonFormatter());
});

// --- OpenTelemetry ---
builder.Services.AddOpenTelemetry()
    .WithTracing(tracing =>
    {
        tracing
            .AddAspNetCoreInstrumentation()
            .AddHttpClientInstrumentation()
            .AddSource("Conscia.AI")
            .AddSource("Conscia.Transactions")
            .AddSource("Conscia.Budgets");

        if (builder.Environment.IsDevelopment())
            tracing.AddConsoleExporter();
        else
            tracing.AddOtlpExporter();
    })
    .WithMetrics(metrics =>
    {
        metrics
            .AddAspNetCoreInstrumentation()
            .AddHttpClientInstrumentation()
            .AddMeter("Conscia.Api");

        if (builder.Environment.IsDevelopment())
            metrics.AddConsoleExporter();
        else
            metrics.AddOtlpExporter();
    });

// --- AWS SDK clients ---
if (builder.Environment.IsDevelopment())
{
    var credentials = new BasicAWSCredentials("local", "local");

    var dynamoConfig = new AmazonDynamoDBConfig
    {
        ServiceURL = builder.Configuration["AWS:DynamoDB:ServiceURL"]
    };
    builder.Services.AddSingleton<IAmazonDynamoDB>(new AmazonDynamoDBClient(credentials, dynamoConfig));

    var s3Config = new AmazonS3Config
    {
        ServiceURL = builder.Configuration["AWS:S3:ServiceURL"],
        ForcePathStyle = builder.Configuration.GetValue<bool>("AWS:S3:ForcePathStyle")
    };
    builder.Services.AddSingleton<IAmazonS3>(new AmazonS3Client(credentials, s3Config));

    var sqsConfig = new AmazonSQSConfig
    {
        ServiceURL = builder.Configuration["AWS:SQS:ServiceURL"]
    };
    builder.Services.AddSingleton<IAmazonSQS>(new AmazonSQSClient(credentials, sqsConfig));
}
else
{
    builder.Services.AddAWSService<IAmazonDynamoDB>();
    builder.Services.AddAWSService<IAmazonS3>();
    builder.Services.AddAWSService<IAmazonSQS>();
    builder.Services.AddAWSService<IAmazonCognitoIdentityProvider>();
}

// --- EF Core + DB Repositories ---
if (builder.Environment.IsDevelopment())
{
    builder.Services.AddDbContext<ConsciaDbContext>(options =>
        options.UseNpgsql(builder.Configuration.GetConnectionString("PostgreSQL")));

    builder.Services.AddScoped<IUserRepository, UserRepository>();
    builder.Services.AddScoped<IBudgetRepository, BudgetRepository>();
    builder.Services.AddScoped<IReceiptRepository, ReceiptRepository>();
    builder.Services.AddScoped<IFamilySpaceRepository, FamilySpaceRepository>();
}
else
{
    builder.Services.AddAWSService<IAmazonLambda>();
    var dbFunctionName = builder.Configuration["AWS:Lambda:DbAccessFunctionName"] ?? "conscia-db-access";

    builder.Services.AddScoped<IBudgetRepository>(sp =>
        new LambdaProxyBudgetRepository(sp.GetRequiredService<IAmazonLambda>(), dbFunctionName));
    builder.Services.AddScoped<IUserRepository>(sp =>
        new LambdaProxyUserRepository(sp.GetRequiredService<IAmazonLambda>(), dbFunctionName));
    builder.Services.AddScoped<IReceiptRepository>(sp =>
        new LambdaProxyReceiptRepository(sp.GetRequiredService<IAmazonLambda>(), dbFunctionName));
    builder.Services.AddScoped<IFamilySpaceRepository>(sp =>
        new LambdaProxyFamilySpaceRepository(sp.GetRequiredService<IAmazonLambda>(), dbFunctionName));
}
builder.Services.AddScoped<ITransactionRepository, TransactionRepository>();
builder.Services.AddScoped<IRecurringScheduleRepository, RecurringScheduleRepository>();
builder.Services.AddScoped<IAIInteractionRepository, AIInteractionRepository>();
builder.Services.AddScoped<IWeeklyInsightsRepository, WeeklyInsightsRepository>();
builder.Services.AddScoped<IPurchasePatternRepository, PurchasePatternRepository>();
builder.Services.AddScoped<IInAppAlertRepository, InAppAlertRepository>();
builder.Services.AddScoped<IPushDeviceTokenRepository, PushDeviceTokenRepository>();
builder.Services.AddScoped<IOutboxEventRepository, OutboxEventRepository>();
builder.Services.AddScoped<IMonthlyCategorySpendRepository, MonthlyCategorySpendRepository>();
builder.Services.AddScoped<IConscienceJourneyRepository, ConscienceJourneyRepository>();

// --- Store Validation ---
builder.Services.Configure<AppleStoreOptions>(builder.Configuration.GetSection(AppleStoreOptions.SectionName));
builder.Services.Configure<GooglePlayOptions>(builder.Configuration.GetSection(GooglePlayOptions.SectionName));
builder.Services.AddHttpClient<IAppleReceiptValidator, AppleReceiptValidator>();
builder.Services.AddHttpClient<IGooglePlayValidator, GooglePlayValidator>();
builder.Services.AddHttpClient<IExternalSocialTokenVerifier, ExternalSocialTokenVerifier>();

// --- Services ---
builder.Services.AddSingleton<IS3StorageService, S3StorageService>();
builder.Services.AddSingleton<ISqsQueueService, SqsQueueService>();
builder.Services.AddScoped<IUserService, UserService>();
builder.Services.AddScoped<IBudgetService, BudgetService>();
builder.Services.AddScoped<ITransactionService, TransactionService>();
builder.Services.AddScoped<IRecurringScheduleService, RecurringScheduleService>();
builder.Services.AddScoped<ISubscriptionService, SubscriptionService>();
builder.Services.AddScoped<IReceiptService, ReceiptService>();
builder.Services.AddScoped<IFamilySpaceService, FamilySpaceService>();
builder.Services.AddScoped<IBehavioralInsightsService, BehavioralInsightsService>();
builder.Services.AddScoped<IPurchaseSuggestionService, PurchaseSuggestionService>();
builder.Services.AddScoped<IPurchasePatternService, PurchasePatternService>();
builder.Services.AddScoped<IAlertService, AlertService>();
builder.Services.AddScoped<IConscienceJourneyService, ConscienceJourneyService>();
builder.Services.AddSingleton<IRecurringScheduleGenerator, RecurringScheduleGenerator>();
builder.Services.AddScoped<ITriggerEvaluator, BudgetWarningEvaluator>();
builder.Services.AddScoped<ITriggerEvaluator, CoolingOffSuggestionEvaluator>();
builder.Services.AddScoped<ITriggerEvaluator, RepeatedRegretCounterpartyEvaluator>();
builder.Services.AddScoped<ITriggerEvaluator, RepeatedRegretCategoryEvaluator>();
builder.Services.AddScoped<ITriggerEvaluator, NotSureStreakEvaluator>();
builder.Services.AddScoped<ITriggerEvaluator, ReflectionFollowUpEvaluator>();

// --- Exchange Rates ---
builder.Services.AddMemoryCache();
builder.Services.AddHttpClient<IExchangeRateService, ExchangeRateService>(client =>
{
    client.BaseAddress = new Uri("https://open.er-api.com");
    client.Timeout = TimeSpan.FromSeconds(10);
});
builder.Services.AddScoped<IOcrService, StubOcrService>();

// --- AI Service ---
if (builder.Environment.IsDevelopment())
{
    builder.Services.AddHttpClient<IAIService, OllamaAIService>(client =>
    {
        client.BaseAddress = new Uri(builder.Configuration["Ollama:BaseUrl"] ?? "http://localhost:11434");
        client.Timeout = TimeSpan.FromSeconds(30);
    });
}
else
{
    builder.Services.Configure<BedrockOptions>(builder.Configuration.GetSection(BedrockOptions.SectionName));
    builder.Services.AddAWSService<IAmazonBedrockRuntime>();
    builder.Services.AddScoped<IAIService, BedrockAIService>();
}

// --- Validators ---
builder.Services.AddValidatorsFromAssemblyContaining<CreateTransactionValidator>();

// --- CORS ---
builder.Services.AddCors(options =>
{
    options.AddPolicy("DevelopmentPolicy", corsPolicyBuilder =>
    {
        corsPolicyBuilder
            .AllowAnyOrigin()
            .AllowAnyMethod()
            .AllowAnyHeader();
    });
});

// --- Background Services ---
builder.Services.AddHostedService<RecurringScheduleProcessor>();
builder.Services.AddHostedService<OutboxProcessor>();

// --- Auth ---
var useMockAuth = builder.Configuration.GetValue<bool>("Auth:UseMock");

if (useMockAuth)
{
    builder.Services.AddScoped<IAuthService, MockAuthService>();

    var signingKey = builder.Configuration["Auth:MockSigningKey"]!;
    builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
        .AddJwtBearer(options =>
        {
            options.TokenValidationParameters = new TokenValidationParameters
            {
                ValidateIssuer = true,
                ValidIssuer = "conscia-mock",
                ValidateAudience = true,
                ValidAudience = "conscia-api",
                ValidateLifetime = true,
                IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(signingKey)),
                ClockSkew = TimeSpan.FromMinutes(1)
            };
        });
}
else
{
    builder.Services.AddScoped<IAuthService, CognitoAuthService>();

    var appJwtSigningKey = builder.Configuration["Auth:AppJwtSigningKey"];
    var appJwtIssuer = builder.Configuration["Auth:AppJwtIssuer"] ?? "conscia-app";
    var appJwtAudience = builder.Configuration["Auth:AppJwtAudience"] ?? "conscia-api";
    var appJwtEnabled = !string.IsNullOrWhiteSpace(appJwtSigningKey);

    var authBuilder = builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
        .AddPolicyScheme(JwtBearerDefaults.AuthenticationScheme, "Cognito or app JWT", options =>
        {
            options.ForwardDefaultSelector = context =>
            {
                if (!appJwtEnabled)
                {
                    return "Cognito";
                }

                var header = context.Request.Headers.Authorization.ToString();
                const string bearer = "Bearer ";
                if (!header.StartsWith(bearer, StringComparison.OrdinalIgnoreCase))
                {
                    return "Cognito";
                }

                var token = header[bearer.Length..].Trim();
                try
                {
                    var issuer = new JwtSecurityTokenHandler().ReadJwtToken(token).Issuer;
                    return string.Equals(issuer, appJwtIssuer, StringComparison.Ordinal)
                        ? "AppJwt"
                        : "Cognito";
                }
                catch
                {
                    return "Cognito";
                }
            };
        })
        .AddJwtBearer("Cognito", options =>
        {
            var region = builder.Configuration["AWS:Region"] ?? "ap-southeast-1";
            var userPoolId = builder.Configuration["Auth:Cognito:UserPoolId"]!;
            options.Authority = $"https://cognito-idp.{region}.amazonaws.com/{userPoolId}";
            options.TokenValidationParameters = new TokenValidationParameters
            {
                ValidateIssuerSigningKey = true,
                ValidateAudience = false
            };
        });

    if (appJwtEnabled)
    {
        authBuilder.AddJwtBearer("AppJwt", options =>
        {
            options.TokenValidationParameters = new TokenValidationParameters
            {
                ValidateIssuerSigningKey = true,
                IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(appJwtSigningKey!)),
                ValidateIssuer = true,
                ValidIssuer = appJwtIssuer,
                ValidateAudience = true,
                ValidAudience = appJwtAudience,
                ValidateLifetime = true,
                ClockSkew = TimeSpan.FromMinutes(1)
            };
        });
    }
}

builder.Services.AddExceptionHandler<GlobalExceptionHandler>();
builder.Services.AddProblemDetails();

builder.Services.AddAuthorization();

builder.Services.AddRateLimiter(options =>
{
    options.RejectionStatusCode = StatusCodes.Status429TooManyRequests;

    options.AddFixedWindowLimiter("standard", opt =>
    {
        opt.PermitLimit = 60;
        opt.Window = TimeSpan.FromMinutes(1);
        opt.QueueLimit = 0;
    });

    options.AddFixedWindowLimiter("ai", opt =>
    {
        opt.PermitLimit = 10;
        opt.Window = TimeSpan.FromMinutes(1);
        opt.QueueLimit = 0;
    });

    options.AddFixedWindowLimiter("iap-verify", opt =>
    {
        opt.PermitLimit = 5;
        opt.Window = TimeSpan.FromMinutes(5);
        opt.QueueLimit = 0;
    });

    options.AddFixedWindowLimiter("auth", opt =>
    {
        opt.PermitLimit = 5;
        opt.Window = TimeSpan.FromMinutes(1);
        opt.QueueLimit = 0;
    });
});

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// --- JSON Serialization ---
builder.Services.ConfigureHttpJsonOptions(options =>
{
    options.SerializerOptions.PropertyNamingPolicy = JsonNamingPolicy.CamelCase;
    options.SerializerOptions.WriteIndented = false;
    options.SerializerOptions.Converters.Add(new JsonStringEnumConverter(JsonNamingPolicy.CamelCase));
});

// --- Health Checks ---
builder.Services.AddHttpClient();
var healthChecks = builder.Services.AddHealthChecks()
    .AddCheck("self", () => HealthCheckResult.Healthy(), tags: new[] { "live" })
    .AddCheck<DynamoDbHealthCheck>("dynamodb", tags: new[] { "ready", "db" })
    .AddCheck<AIServiceHealthCheck>("ai-service", tags: new[] { "ready" });

if (builder.Environment.IsDevelopment())
{
    healthChecks.AddNpgSql(
        connectionString: builder.Configuration.GetConnectionString("PostgreSQL") ?? "",
        name: "postgresql",
        tags: new[] { "ready", "db" });
}

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseMiddleware<CorrelationIdMiddleware>();
app.UseSerilogRequestLogging();
app.UseExceptionHandler();
app.UseHttpsRedirection();
app.UseMiddleware<ColdStartMiddleware>();

if (app.Environment.IsDevelopment())
{
    app.UseCors("DevelopmentPolicy");
}

app.UseAuthentication();
app.UseAuthorization();
app.UseRateLimiter();
app.UseMiddleware<SubscriptionTierMiddleware>();

app.MapHealthChecks("/health/live", new HealthCheckOptions
{
    Predicate = check => check.Tags.Contains("live"),
    ResponseWriter = HealthResponseWriter.WriteAsync
}).AllowAnonymous();

app.MapHealthChecks("/health/ready", new HealthCheckOptions
{
    Predicate = check => check.Tags.Contains("ready"),
    ResponseWriter = HealthResponseWriter.WriteAsync
}).AllowAnonymous();

app.MapHealthChecks("/health", new HealthCheckOptions
{
    ResponseWriter = HealthResponseWriter.WriteAsync
}).AllowAnonymous();

app.MapGet("/api/v1", () => Results.Ok(new { version = "1.0", service = "Conscia API" }))
    .WithName("ApiRoot")
    .WithTags("System");

// --- API Endpoints ---
app.MapAuthEndpoints().RequireRateLimiting("standard");
app.MapUserEndpoints().RequireRateLimiting("standard");
app.MapTransactionEndpoints().RequireRateLimiting("standard");
app.MapRecurringEndpoints().RequireRateLimiting("standard");
app.MapBudgetEndpoints().RequireRateLimiting("standard");
app.MapFamilySpaceEndpoints().RequireRateLimiting("standard");
app.MapSubscriptionEndpoints().RequireRateLimiting("standard");
app.MapAlertEndpoints().RequireRateLimiting("standard");
app.MapPushNotificationEndpoints().RequireRateLimiting("standard");
app.MapReceiptEndpoints().RequireRateLimiting("standard");
app.MapAIEndpoints().RequireRateLimiting("ai");
app.MapInsightsEndpoints().RequireRateLimiting("standard");
app.MapConscienceJourneyEndpoints().RequireRateLimiting("standard");
app.MapSuggestionEndpoints().RequireRateLimiting("standard");
app.MapExchangeRateEndpoints().RequireRateLimiting("standard");
app.MapUtteranceEndpoints().RequireRateLimiting("ai");

app.Run();

public partial class Program { }
