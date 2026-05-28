using System.Text;
using Amazon.Lambda.Serialization.SystemTextJson;
using Conscia.Application.Lambda;

namespace Conscia.Tests.Unit.Lambda;

public class ScheduledLambdaEventTests
{
    [Fact]
    public void Serializer_DeserializesScheduledEventPayload()
    {
        var json = """
            {
              "version": "0",
              "source": "aws.events",
              "detail-type": "Scheduled Event",
              "detail": {}
            }
            """;
        var serializer = new DefaultLambdaJsonSerializer();
        using var stream = new MemoryStream(Encoding.UTF8.GetBytes(json));

        var payload = serializer.Deserialize<ScheduledLambdaEvent>(stream);

        Assert.NotNull(payload);
    }
}
