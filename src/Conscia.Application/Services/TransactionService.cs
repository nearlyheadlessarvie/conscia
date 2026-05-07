using System.Text.Json;
using Conscia.Application.DTOs;
using Conscia.Application.Interfaces;
using Conscia.Application.Models;
using Conscia.Domain.Entities;
using Conscia.Domain.Enums;
using Conscia.Domain.ValueObjects;
using Microsoft.Extensions.Logging;

namespace Conscia.Application.Services;

public class TransactionService : ITransactionService
{
    private readonly ITransactionRepository _repo;
    private readonly IExchangeRateService _exchangeRateService;
    private readonly ILogger<TransactionService> _logger;

    public TransactionService(ITransactionRepository repo, IExchangeRateService exchangeRateService, ILogger<TransactionService> logger)
    {
        _repo = repo;
        _exchangeRateService = exchangeRateService;
        _logger = logger;
    }

    public async Task<Transaction> CreateAsync(Guid userId, CreateTransactionDto dto, CancellationToken ct = default)
    {
        decimal? exchangeRate = dto.ExchangeRateOverride;

        if (exchangeRate is null
            && dto.BaseCurrencyCode is not null
            && !string.Equals(dto.CurrencyCode, dto.BaseCurrencyCode, StringComparison.OrdinalIgnoreCase))
        {
            exchangeRate = await _exchangeRateService.GetRateAsync(dto.CurrencyCode, dto.BaseCurrencyCode, ct);
        }

        var transaction = new Transaction
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            Type = dto.Type,
            Amount = new Money(dto.Amount, dto.CurrencyCode, exchangeRate),
            Category = dto.Category,
            Counterparty = dto.Counterparty,
            Date = dto.Date,
            CreatedAt = DateTime.UtcNow
        };

        if (dto.Latitude.HasValue && dto.Longitude.HasValue)
        {
            transaction.Location = new Location
            {
                Latitude = dto.Latitude.Value,
                Longitude = dto.Longitude.Value,
                PlaceName = dto.PlaceName
            };
        }

        var outboxEvent = new OutboxEvent
        {
            Id = Guid.NewGuid(),
            AggregateId = transaction.Id,
            EventType = OutboxEventType.TransactionCreated,
            Payload = JsonSerializer.Serialize(new
            {
                TransactionId = transaction.Id,
                UserId = userId,
                Amount = dto.Amount,
                CurrencyCode = dto.CurrencyCode,
                Category = dto.Category
            }),
            CreatedAt = DateTime.UtcNow
        };

        var result = await _repo.AddWithOutboxAsync(transaction, outboxEvent, ct);
        _logger.LogInformation("Creating transaction {TransactionId} for user {UserId}, amount {Amount} {Currency}",
            transaction.Id, userId, dto.Amount, dto.CurrencyCode);
        return result;
    }

    public Task<Transaction?> GetByIdAsync(Guid id, CancellationToken ct = default) =>
        _repo.GetByIdAsync(id, ct);

    public async Task<PagedResult<Transaction>> ListAsync(
        Guid userId, int page, int pageSize, string? category = null, CancellationToken ct = default)
    {
        var (items, nextToken) = await _repo.QueryByUserAsync(
            userId, null, null, category, pageSize, null, ct);

        return new PagedResult<Transaction>
        {
            Items = items,
            Page = page,
            PageSize = pageSize,
            TotalCount = items.Count
        };
    }

    public async Task<Transaction> UpdateAsync(Guid id, UpdateTransactionDto dto, CancellationToken ct = default)
    {
        var existing = await _repo.GetByIdAsync(id, ct);
        if (existing is null)
        {
            _logger.LogWarning("Transaction {TransactionId} not found", id);
            throw new KeyNotFoundException($"Transaction {id} not found");
        }

        if (dto.Type.HasValue) existing.Type = dto.Type.Value;
        if (dto.Amount.HasValue && dto.CurrencyCode is not null)
            existing.Amount = new Money(dto.Amount.Value, dto.CurrencyCode);
        else if (dto.Amount.HasValue)
            existing.Amount = new Money(dto.Amount.Value, existing.Amount.CurrencyCode);
        if (dto.Category is not null) existing.Category = dto.Category;
        if (dto.Counterparty is not null) existing.Counterparty = dto.Counterparty;
        if (dto.Date.HasValue) existing.Date = dto.Date.Value;

        await _repo.UpdateAsync(existing, ct);
        return existing;
    }

    public async Task DeleteAsync(Guid id, CancellationToken ct = default)
    {
        var existing = await _repo.GetByIdAsync(id, ct);
        if (existing is null)
        {
            _logger.LogWarning("Transaction {TransactionId} not found", id);
            throw new KeyNotFoundException($"Transaction {id} not found");
        }

        var outboxEvent = new OutboxEvent
        {
            Id = Guid.NewGuid(),
            AggregateId = id,
            EventType = OutboxEventType.TransactionDeleted,
            Payload = JsonSerializer.Serialize(new
            {
                TransactionId = id,
                UserId = existing.UserId,
                Amount = existing.Amount.Amount,
                CurrencyCode = existing.Amount.CurrencyCode,
                Category = existing.Category
            }),
            CreatedAt = DateTime.UtcNow
        };

        await _repo.DeleteWithOutboxAsync(id, outboxEvent, ct);
        _logger.LogInformation("Deleting transaction {TransactionId} for user {UserId}", id, existing.UserId);
    }

    public Task UpdateRegretLevelAsync(Guid id, RegretLevel level, CancellationToken ct = default) =>
        _repo.UpdateRegretLevelAsync(id, level, ct);
}
