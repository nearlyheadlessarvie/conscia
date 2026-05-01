namespace Conscia.Api.Middleware;

/// <summary>
/// Marker attribute for endpoints that require Premium subscription tier.
/// Applied via endpoint metadata, enforced by SubscriptionTierMiddleware.
/// </summary>
[AttributeUsage(AttributeTargets.Method | AttributeTargets.Class)]
public class RequirePremiumAttribute : Attribute;
