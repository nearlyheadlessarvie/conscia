using Conscia.Application.DTOs;
using Conscia.Application.Validators;
using Conscia.Domain.Enums;

namespace Conscia.Tests.Unit.Application;

public class ValidatorTests
{
    // --- CreateTransactionValidator ---

    [Fact]
    public async Task CreateTransaction_ValidDto_Passes()
    {
        var validator = new CreateTransactionValidator();
        var dto = new CreateTransactionDto
        {
            Type = TransactionType.Expense,
            Amount = 42.50m,
            CurrencyCode = "USD",
            Category = "Food",
            Date = DateTime.UtcNow.AddHours(-1)
        };

        var result = await validator.ValidateAsync(dto);

        Assert.True(result.IsValid);
    }

    [Fact]
    public async Task CreateTransaction_ZeroAmount_Fails()
    {
        var validator = new CreateTransactionValidator();
        var dto = new CreateTransactionDto
        {
            Amount = 0, CurrencyCode = "USD", Category = "Food",
            Date = DateTime.UtcNow
        };

        var result = await validator.ValidateAsync(dto);

        Assert.False(result.IsValid);
        Assert.Contains(result.Errors, e => e.PropertyName == "Amount");
    }

    [Fact]
    public async Task CreateTransaction_InvalidCurrency_Fails()
    {
        var validator = new CreateTransactionValidator();
        var dto = new CreateTransactionDto
        {
            Amount = 10, CurrencyCode = "US", Category = "Food",
            Date = DateTime.UtcNow
        };

        var result = await validator.ValidateAsync(dto);

        Assert.False(result.IsValid);
        Assert.Contains(result.Errors, e => e.PropertyName == "CurrencyCode");
    }

    [Fact]
    public async Task CreateTransaction_EmptyCategory_Fails()
    {
        var validator = new CreateTransactionValidator();
        var dto = new CreateTransactionDto
        {
            Amount = 10, CurrencyCode = "USD", Category = "",
            Date = DateTime.UtcNow
        };

        var result = await validator.ValidateAsync(dto);

        Assert.False(result.IsValid);
        Assert.Contains(result.Errors, e => e.PropertyName == "Category");
    }

    [Fact]
    public async Task CreateTransaction_FutureDate_Fails()
    {
        var validator = new CreateTransactionValidator();
        var dto = new CreateTransactionDto
        {
            Amount = 10, CurrencyCode = "USD", Category = "Food",
            Date = DateTime.UtcNow.AddDays(5)
        };

        var result = await validator.ValidateAsync(dto);

        Assert.False(result.IsValid);
        Assert.Contains(result.Errors, e => e.PropertyName == "Date");
    }

    [Fact]
    public async Task CreateTransaction_InvalidLatitude_Fails()
    {
        var validator = new CreateTransactionValidator();
        var dto = new CreateTransactionDto
        {
            Amount = 10, CurrencyCode = "USD", Category = "Food",
            Date = DateTime.UtcNow, Latitude = 91
        };

        var result = await validator.ValidateAsync(dto);

        Assert.False(result.IsValid);
        Assert.Contains(result.Errors, e => e.PropertyName == "Latitude");
    }

    // --- CreateBudgetValidator ---

    [Fact]
    public async Task CreateBudget_ValidDto_Passes()
    {
        var validator = new CreateBudgetValidator();
        var dto = new CreateBudgetDto { Category = "Food", MonthlyLimit = 500, CurrencyCode = "USD" };

        var result = await validator.ValidateAsync(dto);

        Assert.True(result.IsValid);
    }

    [Fact]
    public async Task CreateBudget_ZeroLimit_Fails()
    {
        var validator = new CreateBudgetValidator();
        var dto = new CreateBudgetDto { Category = "Food", MonthlyLimit = 0, CurrencyCode = "USD" };

        var result = await validator.ValidateAsync(dto);

        Assert.False(result.IsValid);
    }

    // --- UpdateBudgetValidator ---

    [Fact]
    public async Task UpdateBudget_NoFieldsProvided_Fails()
    {
        var validator = new UpdateBudgetValidator();
        var dto = new UpdateBudgetDto();

        var result = await validator.ValidateAsync(dto);

        Assert.False(result.IsValid);
    }

    [Fact]
    public async Task UpdateBudget_OnlyLimit_Passes()
    {
        var validator = new UpdateBudgetValidator();
        var dto = new UpdateBudgetDto { MonthlyLimit = 600 };

        var result = await validator.ValidateAsync(dto);

        Assert.True(result.IsValid);
    }

    // --- UpdateTransactionValidator ---

    [Fact]
    public async Task UpdateTransaction_NegativeAmount_Fails()
    {
        var validator = new UpdateTransactionValidator();
        var dto = new UpdateTransactionDto { Amount = -5 };

        var result = await validator.ValidateAsync(dto);

        Assert.False(result.IsValid);
    }

    [Fact]
    public async Task UpdateTransaction_ValidPartialUpdate_Passes()
    {
        var validator = new UpdateTransactionValidator();
        var dto = new UpdateTransactionDto { Category = "Dining" };

        var result = await validator.ValidateAsync(dto);

        Assert.True(result.IsValid);
    }

    // --- UserProfileUpdateValidator ---

    [Fact]
    public async Task UserProfileUpdate_ValidCurrency_Passes()
    {
        var validator = new UserProfileUpdateValidator();
        var dto = new UserProfileUpdateDto { PreferredCurrency = "EUR" };

        var result = await validator.ValidateAsync(dto);

        Assert.True(result.IsValid);
    }

    [Fact]
    public async Task UserProfileUpdate_UnsupportedCurrency_Fails()
    {
        var validator = new UserProfileUpdateValidator();
        var dto = new UserProfileUpdateDto { PreferredCurrency = "XYZ" };

        var result = await validator.ValidateAsync(dto);

        Assert.False(result.IsValid);
    }

    [Fact]
    public async Task UserProfileUpdate_NoFieldsProvided_Fails()
    {
        var validator = new UserProfileUpdateValidator();
        var dto = new UserProfileUpdateDto();

        var result = await validator.ValidateAsync(dto);

        Assert.False(result.IsValid);
    }

    // --- PrePurchaseRequestValidator ---

    [Fact]
    public async Task PrePurchaseRequest_ValidDto_Passes()
    {
        var validator = new PrePurchaseRequestValidator();
        var dto = new PrePurchaseRequestDto
        {
            Description = "New headphones",
            Amount = 299.99m,
            CurrencyCode = "USD",
            Category = "Electronics"
        };

        var result = await validator.ValidateAsync(dto);

        Assert.True(result.IsValid);
    }

    [Fact]
    public async Task PrePurchaseRequest_EmptyDescription_Fails()
    {
        var validator = new PrePurchaseRequestValidator();
        var dto = new PrePurchaseRequestDto
        {
            Description = "",
            Amount = 10, CurrencyCode = "USD", Category = "Food"
        };

        var result = await validator.ValidateAsync(dto);

        Assert.False(result.IsValid);
    }
}
