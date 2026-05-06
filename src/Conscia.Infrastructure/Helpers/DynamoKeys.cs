public static class DynamoKeys
{
    // ---------------- PK ----------------

    /// <summary>
    /// <c>USER#{userId}</c> - Primary key for user-centric data
    /// </summary>
    /// <param name="userId"></param>
    /// <returns></returns>
    public static string User(Guid userId)
        => $"USER#{userId}";

    /// <summary>
    /// <c>EVENT#{eventId}</c> - Primary key for event-centric data
    /// </summary>
    /// <param name="id"></param>
    /// <returns></returns>
    public static string Event(Guid id)
    => $"EVENT#{id}";

    /// <summary>
    /// <c>SESSION#{sessionId}</c> - Primary key for session-centric data
    /// </summary>
    /// <param name="key"></param>
    /// <returns></returns>
    public static string Session(string key)
        => $"SESSION#{key}";

    /// <summary>
    /// <c>AGG#{aggregateId}</c> - Primary key for aggregate-centric data (e.g. outbox events)
    /// </summary>
    /// <param name="aggregateId"></param>
    /// <returns></returns>
    public static string Outbox(Guid aggregateId)
        => $"AGG#{aggregateId}";    


    // ---------------- SK ----------------

    /// <summary>
    /// <c>EVENT#{date:O}</c> - Sort key for event-centric data sorted by creation date
    /// </summary>
    /// <param name="date"></param>
    /// <returns></returns>
    public static string EventCreatedAt(DateTime date)
        => $"EVENT#{date:O}";

    /// <summary>
    /// <c>TX#{id}</c> - Sort key for transaction-centric data (immutable)
    /// </summary>
    /// <param name="id"></param>
    /// <returns></returns>
    public static string Transaction(Guid id)
        => $"TX#{id}";

    /// <summary>
    /// <c>DATE#{date:O}</c> - Sort key for date-centric data (e.g. events, sessions)
    /// </summary>
    /// <param name="date"></param>
    /// <returns></returns>
    public static string DateRangeStart(DateTime date)
        => $"DATE#{date:O}";

    /// <summary>
    /// <c>DATE#{date:O}~</c> - Sort key for date-centric data range end (tilde ensures it sorts after all keys with the same date)
    /// </summary>
    /// <param name="date"></param>
    /// <returns></returns>
    public static string DateRangeEnd(DateTime date)
        => $"DATE#{date:O}~";

    /// <summary>
    /// <c>CATEGORY#{category}#DATE#{date:O}</c> - Sort key for category+date-centric data
    /// </summary>
    /// <param name="category"></param>
    /// <param name="date"></param>
    /// <returns></returns>
    public static string TransactionSortKey(string category, DateTime date)
        => $"CATEGORY#{category}#DATE#{date:O}";

    /// <summary>
    /// <c>WEEK#{date:yyyy-MM-dd}</c> - Sort key for week-based data
    /// </summary>
    /// <param name="date"></param>
    /// <returns></returns>
    public static string Week(DateTime date)
    {
        var start = date.Date.AddDays(-(int)date.DayOfWeek);
        return $"WEEK#{start:yyyy-MM-dd}";
    }

    /// <summary>
    /// <c>DATE#{createdAt:O}#AI#{id}</c> - Sort key for AI interaction-centric data (alternative format)
    /// </summary>
    /// <param name="createdAt"></param>
    /// <param name="id"></param>
    /// <returns></returns>
    public static string AIInteraction(DateTime createdAt, Guid id)
        => $"DATE#{createdAt:O}#AI#{id}";

    /// <summary>
    /// <c>ALERT#{date:O}</c> - Sort key for in-app alerts sorted by creation date
    /// </summary>
    /// <param name="date"></param>
    /// <returns></returns>
    public static string Alert(DateTime date)
        => $"ALERT#{date:O}";

    /// <summary>
    /// <c>SUMMARY</c> - Sort key for purchase pattern summary data
    /// </summary>
    /// <returns></returns>
    public static string PurchasePatternSummary()
        => "SUMMARY";

    /// <summary>
    /// <c>CAT#{category}</c> - Sort key for purchase pattern category-centric data
    /// </summary>
    /// <param name="category"></param>
    /// <returns></returns>
    public static string PurchasePatternCategory(string category)
        => $"CAT#{category.Trim().ToLowerInvariant()}";

    /// <summary>
    /// <c>MER#{merchant}</c> - Sort key for purchase pattern merchant-centric data
    /// </summary>
    /// <param name="merchant"></param>
    /// <returns></returns>
    public static string PurchasePatternMerchant(string merchant)
        => $"MER#{merchant.Trim().ToLowerInvariant()}";
}