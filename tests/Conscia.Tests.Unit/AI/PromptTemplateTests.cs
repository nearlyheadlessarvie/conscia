using Conscia.AI.Prompts;

namespace Conscia.Tests.Unit.AI;

public class PromptTemplateTests
{
    [Fact]
    public void BuildPrePurchaseUserPrompt_WithFullContext_IncludesAllFields()
    {
        var result = PromptTemplates.BuildPrePurchaseUserPrompt(49.99m, "USD", "Food", 72m, 3, 5);

        Assert.Contains("49.99 USD", result);
        Assert.Contains("Food", result);
        Assert.Contains("72%", result);
        Assert.Contains("3", result);
        Assert.Contains("5", result);
        Assert.Contains("considering a purchase", result);
    }

    [Fact]
    public void BuildPrePurchaseUserPrompt_WithMinimalContext_StillValid()
    {
        var result = PromptTemplates.BuildPrePurchaseUserPrompt(null, null, null, null, 0, 0);

        Assert.Contains("considering a purchase", result);
        Assert.DoesNotContain("Amount", result);
        Assert.DoesNotContain("Category", result);
        Assert.DoesNotContain("Budget used", result);
    }

    [Fact]
    public void BuildReflectionUserPrompt_WithFullContext_IncludesAllFields()
    {
        var result = PromptTemplates.BuildReflectionUserPrompt(120m, "EUR", "Entertainment", 85m, 2);

        Assert.Contains("120.00 EUR", result);
        Assert.Contains("Entertainment", result);
        Assert.Contains("85%", result);
        Assert.Contains("2", result);
        Assert.Contains("reflect", result);
    }

    [Fact]
    public void BuildNeutralSummary_OverBudget_IncludesExceededMessage()
    {
        var result = PromptTemplates.BuildNeutralSummary(50m, "GBP", "Dining", 105m);

        Assert.Contains("exceeded", result);
        Assert.Contains("105%", result);
    }

    [Fact]
    public void BuildNeutralSummary_ApproachingLimit_IncludesApproachingMessage()
    {
        var result = PromptTemplates.BuildNeutralSummary(50m, "GBP", "Dining", 85m);

        Assert.Contains("approaching", result);
        Assert.Contains("85%", result);
    }

    [Fact]
    public void BuildNeutralSummary_MidBudget_ShowsPercentUsed()
    {
        var result = PromptTemplates.BuildNeutralSummary(30m, "USD", "Food", 60m);

        Assert.Contains("60%", result);
    }

    [Fact]
    public void BuildNeutralSummary_LowBudget_ShowsPlentyOfRoom()
    {
        var result = PromptTemplates.BuildNeutralSummary(10m, "USD", "Coffee", 20m);

        Assert.Contains("plenty of room", result);
    }

    [Fact]
    public void BuildNeutralSummary_NoBudget_ShowsNoBudgetMessage()
    {
        var result = PromptTemplates.BuildNeutralSummary(25m, "USD", "Shopping", null);

        Assert.Contains("No budget is set", result);
    }

    [Fact]
    public void ImpulseSystemPrompt_ContainsExpectedCharacteristics()
    {
        var prompt = PromptTemplates.BuildImpulseSystemPrompt("balanced", false);

        Assert.Contains("Impulse", prompt);
        Assert.Contains("devil-on-the-left-shoulder", prompt);
    }

    [Fact]
    public void ReasonSystemPrompt_ContainsExpectedCharacteristics()
    {
        var prompt = PromptTemplates.BuildReasonSystemPrompt("balanced", false);

        Assert.Contains("Reason", prompt);
        Assert.Contains("angel-on-the-right-shoulder", prompt);
    }

    [Fact]
    public void ReflectionSystemPrompt_IntenseReflection_IsMoreCandid()
    {
        var prompt = PromptTemplates.BuildReflectionSystemPrompt("intense", true);

        Assert.Contains("Reflection", prompt);
        Assert.Contains("clear-eyed", prompt);
        Assert.Contains("bigger picture", prompt);
    }
}
