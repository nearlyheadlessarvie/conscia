namespace Conscia.AI.Services;

public class BedrockOptions
{
    public const string SectionName = "AWS:Bedrock";

    public string ModelId { get; set; } = "anthropic.claude-3-haiku-20240307-v1:0";
    public int MaxTokens { get; set; } = 200;
}
