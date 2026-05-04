using Amazon.DynamoDBv2;
using Amazon.DynamoDBv2.Model;

namespace Conscia.Infrastructure.Repositories;

public abstract class DynamoRepository
{
    protected readonly IAmazonDynamoDB Dynamo;

    protected DynamoRepository(IAmazonDynamoDB dynamo)
    {
        Dynamo = dynamo;
    }

    protected static Dictionary<string, AttributeValue> Key(string pk, string? sk = null)
    {
        var key = new Dictionary<string, AttributeValue>
        {
            ["PK"] = new(pk)
        };

        if (sk != null)
            key["SK"] = new(sk);

        return key;
    }
}