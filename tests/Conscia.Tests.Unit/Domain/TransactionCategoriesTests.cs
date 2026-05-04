using Conscia.Domain.Constants;

namespace Conscia.Tests.Unit.Domain;

public class TransactionCategoriesTests
{
    [Fact]
    public void Expense_IsNotEmpty() => Assert.NotEmpty(TransactionCategories.Expense);

    [Fact]
    public void Income_IsNotEmpty() => Assert.NotEmpty(TransactionCategories.Income);

    [Fact]
    public void Expense_ContainsExpectedCategories()
    {
        Assert.Contains("Groceries", TransactionCategories.Expense);
        Assert.Contains("Dining", TransactionCategories.Expense);
        Assert.Contains("Transport", TransactionCategories.Expense);
    }

    [Fact]
    public void Income_ContainsExpectedCategories()
    {
        Assert.Contains("Salary", TransactionCategories.Income);
        Assert.Contains("Freelance", TransactionCategories.Income);
    }

    [Fact]
    public void Expense_DoesNotContainIncomeSalary() =>
        Assert.DoesNotContain("Salary", TransactionCategories.Expense);
}
