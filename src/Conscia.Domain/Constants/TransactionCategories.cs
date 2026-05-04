namespace Conscia.Domain.Constants;

public static class TransactionCategories
{
    public static readonly IReadOnlyList<string> Expense = new[]
    {
        "Groceries", "Dining", "Transport", "Entertainment",
        "Games & Recreations", "Shopping", "Health", "Bills",
        "Education", "Travel", "Coffee", "Subscriptions", "Gift", "Other"
    };

    public static readonly IReadOnlyList<string> Income = new[]
    {
        "Salary", "Freelance", "Business", "Investment",
        "Rental Income", "Bonus", "Gift", "Other"
    };
}
