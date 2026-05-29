using System.Text;
using Amazon.Lambda.DynamoDBEvents;
using Amazon.Lambda.Serialization.SystemTextJson;

namespace Conscia.Tests.Unit.Lambda;

public class DynamoDbStreamEventSerializationTests
{
    [Fact]
    public void DefaultSerializer_DeserializesDynamoDbStreamEvent()
    {
        const string payload = """
        {
          "Records": [
            {
              "eventID": "1",
              "eventName": "INSERT",
              "eventVersion": "1.1",
              "eventSource": "aws:dynamodb",
              "awsRegion": "ap-southeast-1",
              "dynamodb": {
                "Keys": {
                  "PK": { "S": "OUTBOX#event-1" },
                  "SK": { "S": "META" }
                },
                "SequenceNumber": "111",
                "SizeBytes": 42,
                "StreamViewType": "NEW_AND_OLD_IMAGES"
              },
              "eventSourceARN": "arn:aws:dynamodb:ap-southeast-1:123456789012:table/conscia-prod/stream/2026-05-29T00:00:00.000"
            }
          ]
        }
        """;

        using var stream = new MemoryStream(Encoding.UTF8.GetBytes(payload));
        var serializer = new DefaultLambdaJsonSerializer();

        var dynamoEvent = serializer.Deserialize<DynamoDBEvent>(stream);

        var record = Assert.Single(dynamoEvent.Records);
        Assert.Equal("INSERT", record.EventName);
    }
}
