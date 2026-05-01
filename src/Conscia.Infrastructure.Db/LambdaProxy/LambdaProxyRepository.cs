using System.Text.Json;
using Amazon.Lambda;
using Amazon.Lambda.Model;

namespace Conscia.Infrastructure.Db.LambdaProxy;

public abstract class LambdaProxyRepository
{
    private readonly IAmazonLambda _lambda;
    private readonly string _functionName;

    protected LambdaProxyRepository(IAmazonLambda lambda, string functionName)
    {
        _lambda = lambda;
        _functionName = functionName;
    }

    protected async Task<T> InvokeAsync<T>(string action, object payload, CancellationToken ct = default)
    {
        var request = new InvokeRequest
        {
            FunctionName = _functionName,
            InvocationType = InvocationType.RequestResponse,
            Payload = JsonSerializer.Serialize(new { Action = action, Payload = payload })
        };

        var response = await _lambda.InvokeAsync(request, ct);
        using var reader = new StreamReader(response.Payload);
        var json = await reader.ReadToEndAsync(ct);

        if (response.FunctionError is not null)
            throw new InvalidOperationException($"DB Access Lambda error on '{action}': {json}");

        return JsonSerializer.Deserialize<T>(json, new JsonSerializerOptions { PropertyNameCaseInsensitive = true })!;
    }
}
