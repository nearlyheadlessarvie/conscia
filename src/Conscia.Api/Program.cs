using System.Text;
using Amazon.BedrockRuntime;
using Amazon.DynamoDBv2;
using Amazon.Lambda;
using Amazon.S3;
using Amazon.SQS;
using Conscia.AI.Services;
using Conscia.Api.Endpoints;
using Conscia.Api.Health;
using System.Threading.RateLimiting;
using Microsoft.AspNetCore.RateLimiting;
using Conscia.Api.Middleware;
using Conscia.Application.Interfaces;
using Conscia.Application.Services;
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
    var dynamoConfig = new AmazonDynamoDBConfig
    {
        ServiceURL = builder.Configuration["AWS:DynamoDB:ServiceURL"]
    };
    builder.Services.AddSingleton<IAmazonDynamoDB>(new AmazonDynamoDBClient(dynamoConfig));

    var s3Config = new AmazonS3Config
    {
        ServiceURL = builder.Configuration["AWS:S3:ServiceURL"],
        ForcePathStyle = builder.Configuration.GetValue<bool>("AWS:S3:ForcePathStyle")
    };
    builder.Services.AddSingleton<IAmazonS3>(new AmazonS3Client(s3Config));

    var sqsConfig = new AmazonSQSConfig
    {
        ServiceURL = builder.Configuration["AWS:SQS:ServiceURL"]
    };
    builder.Services.AddSingleton<IAmazonSQS>(new AmazonSQSClient(sqsConfig));
}
else
{
    builder.Services.AddAWSService<IAmazonDynamoDB>();
    builder.Services.AddAWSService<IAmazonS3>();
    builder.Services.AddAWSService<IAmazonSQS>();
}

// --- EF Core + DB Repositories ---
if (builder.Environment.IsDevelopment())
{
    builder.Services.AddDbContext<ConsciaDbContext>(options =>
        options.UseNpgsql(builder.Configuration.GetConnectionString("PostgreSQL")));

    builder.Services.AddScoped<IUserRepository, UserRepository>();
    builder.Services.AddScoped<IBudgetRepository, BudgetRepository>();
    builder.Services.AddScoped<IReceiptRepository, ReceiptRepository>();
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
}
builder.Services.AddScoped<ITransactionRepository, TransactionRepository>();
builder.Services.AddScoped<IOutboxEventRepository, OutboxEventRepository>();
builder.Services.AddScoped<IAIInteractionRepository, AIInteractionRepository>();
builder.Services.AddScoped<IBehaviorProfileRepository, BehaviorProfileRepository>();
builder.Services.AddScoped<IInAppAlertRepository, InAppAlertRepository>();
builder.Services.AddScoped<ISessionCacheRepository, SessionCacheRepository>();

// --- Services ---
builder.Services.AddSingleton<IS3StorageService, S3StorageService>();
builder.Services.AddSingleton<ISqsQueueService, SqsQueueService>();
builder.Services.AddScoped<IUserService, UserService>();
builder.Services.AddScoped<IBudgetService, BudgetService>();
builder.Services.AddScoped<ITransactionService, TransactionService>();
builder.Services.AddScoped<ISubscriptionService, SubscriptionService>();
builder.Services.AddScoped<IReceiptService, ReceiptService>();

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

// --- Background Services ---
builder.Services.AddHostedService<OutboxProcessor>();

// --- Auth ---
var useMockAuth = builder.Configuration.GetValue<bool>("Auth:UseMock");

if (useMockAuth)
{
    var mockAuth = new MockAuthService(builder.Configuration);
    mockAuth.SeedUser("a1b2c3d4-0001-4000-8000-000000000001", "alice@example.com", "password123", "Premium");
    mockAuth.SeedUser("a1b2c3d4-0002-4000-8000-000000000002", "bob@example.com", "password123", "Free");
    mockAuth.SeedUser("a1b2c3d4-0003-4000-8000-000000000003", "carol@example.com", "password123", "Premium");
    builder.Services.AddSingleton<IAuthService>(mockAuth);

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
    builder.Services.AddSingleton<IAuthService, CognitoAuthService>();

    builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
        .AddJwtBearer(options =>
        {
            var region = builder.Configuration["AWS:Region"] ?? "us-east-1";
            var userPoolId = builder.Configuration["Auth:Cognito:UserPoolId"]!;
            options.Authority = $"https://cognito-idp.{region}.amazonaws.com/{userPoolId}";
            options.TokenValidationParameters = new TokenValidationParameters
            {
                ValidateIssuerSigningKey = true,
                ValidateAudience = false
            };
        });
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
});

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

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
app.UseAuthentication();
app.UseAuthorization();
app.UseRateLimiter();
app.UseMiddleware<SubscriptionTierMiddleware>();

app.MapHealthChecks("/health/live", new HealthCheckOptions
{
    Predicate = check => check.Tags.Contains("live"),
    ResponseWriter = HealthResponseWriter.WriteAsync
});

app.MapHealthChecks("/health/ready", new HealthCheckOptions
{
    Predicate = check => check.Tags.Contains("ready"),
    ResponseWriter = HealthResponseWriter.WriteAsync
});

app.MapHealthChecks("/health", new HealthCheckOptions
{
    ResponseWriter = HealthResponseWriter.WriteAsync
});

app.MapGet("/api/v1", () => Results.Ok(new { version = "1.0", service = "Conscia API" }))
    .WithName("ApiRoot")
    .WithTags("System");

// --- API Endpoints ---
app.MapAuthEndpoints().RequireRateLimiting("standard");
app.MapUserEndpoints().RequireRateLimiting("standard");
app.MapTransactionEndpoints().RequireRateLimiting("standard");
app.MapBudgetEndpoints().RequireRateLimiting("standard");
app.MapSubscriptionEndpoints().RequireRateLimiting("standard");
app.MapAlertEndpoints().RequireRateLimiting("standard");
app.MapReceiptEndpoints().RequireRateLimiting("standard");
app.MapAIEndpoints().RequireRateLimiting("ai");

app.Run();

public partial class Program { }
