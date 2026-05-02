-- Conscia MVP Seed Data — RDS (PostgreSQL)
-- 3 users, 5 budgets, 10 receipts

-- Users
INSERT INTO users (
    "Id", "Email", "PreferredCurrency", "Locale", "CreatedAt"
) VALUES
    ('a1b2c3d4-0001-4000-8000-000000000001', 'alice@example.com', 'USD', 'en-US', '2026-01-15T10:00:00Z'),
    ('a1b2c3d4-0002-4000-8000-000000000002', 'bob@example.com',   'EUR', 'es-ES', '2026-02-01T09:30:00Z'),
    ('a1b2c3d4-0003-4000-8000-000000000003', 'carol@example.com', 'MXN', 'es-MX', '2026-03-10T14:00:00Z')
ON CONFLICT DO NOTHING;

-- User Identities
CREATE TABLE IF NOT EXISTS user_identities (
    "Id" UUID PRIMARY KEY,
    "UserId" UUID NOT NULL REFERENCES users("Id"),
    "Provider" VARCHAR(20) NOT NULL,
    "ProviderSub" VARCHAR(256) NOT NULL,
    "CreatedAt" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE ("Provider", "ProviderSub")
);
CREATE INDEX IF NOT EXISTS ix_user_identities_user_id ON user_identities ("UserId");

INSERT INTO user_identities (
    "Id", "UserId", "Provider", "ProviderSub", "CreatedAt"
) VALUES
    ('f1b2c3d4-0001-4000-8000-000000000001', 'a1b2c3d4-0001-4000-8000-000000000001', 'Email', 'cognito_alice_001', '2026-01-15T10:00:00Z'),
    ('f1b2c3d4-0002-4000-8000-000000000002', 'a1b2c3d4-0002-4000-8000-000000000002', 'Email', 'cognito_bob_002',   '2026-02-01T09:30:00Z'),
    ('f1b2c3d4-0003-4000-8000-000000000003', 'a1b2c3d4-0003-4000-8000-000000000003', 'Email', 'cognito_carol_003', '2026-03-10T14:00:00Z')
ON CONFLICT DO NOTHING;

-- User Subscriptions
INSERT INTO user_subscriptions (
    "Id", "UserId", "Tier", "Platform", "ExpiresAt", "OriginalTransactionId"
) VALUES
    ('b1b2c3d4-0001-4000-8000-000000000001', 'a1b2c3d4-0001-4000-8000-000000000001', 'Premium', 'iOS',     '2027-01-15T10:00:00Z', 'apple_txn_001'),
    ('b1b2c3d4-0002-4000-8000-000000000002', 'a1b2c3d4-0002-4000-8000-000000000002', 'Free',    'Android', NULL,                    NULL),
    ('b1b2c3d4-0003-4000-8000-000000000003', 'a1b2c3d4-0003-4000-8000-000000000003', 'Premium', 'Android', '2027-03-10T14:00:00Z', 'google_txn_001')
ON CONFLICT DO NOTHING;

-- Budgets (5 total across users)
INSERT INTO budgets (
    "Id", "UserId", "Category", "MonthlyLimit", "CurrentSpend", "CurrencyCode"
) VALUES
    ('c1b2c3d4-0001-4000-8000-000000000001', 'a1b2c3d4-0001-4000-8000-000000000001', 'Food',         500.00,  320.50, 'USD'),
    ('c1b2c3d4-0002-4000-8000-000000000002', 'a1b2c3d4-0001-4000-8000-000000000001', 'Entertainment', 200.00, 175.00, 'USD'),
    ('c1b2c3d4-0003-4000-8000-000000000003', 'a1b2c3d4-0002-4000-8000-000000000002', 'Food',         400.00,  150.25, 'EUR'),
    ('c1b2c3d4-0004-4000-8000-000000000004', 'a1b2c3d4-0002-4000-8000-000000000002', 'Transport',    150.00,   80.00, 'EUR'),
    ('c1b2c3d4-0005-4000-8000-000000000005', 'a1b2c3d4-0003-4000-8000-000000000003', 'Food',        8000.00, 4500.00, 'MXN')
ON CONFLICT DO NOTHING;

-- Receipts (10 total — only for premium users alice & carol)
INSERT INTO receipts (
    "Id", "TransactionId", "S3Key", "ExtractedData", "OcrConfidence", "NeedsReview", "Status", "CreatedAt"
) VALUES
    ('d1b2c3d4-0001-4000-8000-000000000001', 'e1b2c3d4-0001-4000-8000-000000000001', 'receipts/alice/r001.jpg', '{"merchant":"Whole Foods","total":45.99}',  0.95, false, 'Confirmed', '2026-04-01T12:00:00Z'),
    ('d1b2c3d4-0002-4000-8000-000000000002', 'e1b2c3d4-0002-4000-8000-000000000002', 'receipts/alice/r002.jpg', '{"merchant":"Netflix","total":15.99}',      0.98, false, 'Confirmed', '2026-04-02T08:30:00Z'),
    ('d1b2c3d4-0003-4000-8000-000000000003', 'e1b2c3d4-0003-4000-8000-000000000003', 'receipts/alice/r003.jpg', '{"merchant":"Uber","total":22.50}',         0.92, false, 'Confirmed', '2026-04-03T18:00:00Z'),
    ('d1b2c3d4-0004-4000-8000-000000000004', 'e1b2c3d4-0004-4000-8000-000000000004', 'receipts/alice/r004.jpg', '{"merchant":"Starbucks","total":6.75}',     0.88, true,  'ReviewRequired','2026-04-04T07:15:00Z'),
    ('d1b2c3d4-0005-4000-8000-000000000005', 'e1b2c3d4-0005-4000-8000-000000000005', 'receipts/alice/r005.jpg', NULL,                                         0.00, false, 'Pending',   '2026-04-05T14:30:00Z'),
    ('d1b2c3d4-0006-4000-8000-000000000006', 'e1b2c3d4-0006-4000-8000-000000000006', 'receipts/carol/r006.jpg', '{"merchant":"Oxxo","total":250.00}',        0.91, false, 'Confirmed', '2026-04-01T10:00:00Z'),
    ('d1b2c3d4-0007-4000-8000-000000000007', 'e1b2c3d4-0007-4000-8000-000000000007', 'receipts/carol/r007.jpg', '{"merchant":"Uber MX","total":180.50}',     0.89, true,  'ReviewRequired','2026-04-02T16:00:00Z'),
    ('d1b2c3d4-0008-4000-8000-000000000008', 'e1b2c3d4-0008-4000-8000-000000000008', 'receipts/carol/r008.jpg', '{"merchant":"Cinepolis","total":350.00}',   0.94, false, 'Confirmed', '2026-04-03T20:00:00Z'),
    ('d1b2c3d4-0009-4000-8000-000000000009', 'e1b2c3d4-0009-4000-8000-000000000009', 'receipts/carol/r009.jpg', '{"merchant":"Walmart MX","total":1200.00}', 0.96, false, 'Confirmed', '2026-04-04T11:00:00Z'),
    ('d1b2c3d4-0010-4000-8000-000000000010', 'e1b2c3d4-0010-4000-8000-000000000010', 'receipts/carol/r010.jpg', NULL,                                         0.00, false, 'Pending',   '2026-04-05T09:00:00Z')
ON CONFLICT DO NOTHING;
