# Changelog

All notable changes to the Conscia project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and each component follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### API (v1.0.0)
- Initial release: ASP.NET 8 Minimal APIs with DynamoDB, PostgreSQL, S3, SQS
- Dual-AI personality system (Impulse/Reason) with Ollama (dev) and Bedrock (prod)
- Transaction CRUD with outbox pattern for cross-store consistency
- Budget management with warning triggers
- Receipt scanning (premium-only stub)
- JWT authentication with Cognito (prod) / mock auth (dev)
- OpenTelemetry tracing + metrics
- Health/liveness/readiness endpoints
- Serilog structured logging with correlation IDs
- Application-layer rate limiting

### Flutter App (v1.0.0+1)
- Initial release: Material 3 with Poppins/Inter typography
- Onboarding flow (welcome slides, sign-up, sign-in, setup)
- Dashboard with budget cards, regret prompts, recent transactions
- Transaction list with filters, detail view, add/edit form
- Pre-purchase AI assistant with devil/angel/neutral bubbles
- Budget management with health-colored progress bars
- Settings with currency/locale preferences
- Service status screen with health monitoring
- GoRouter navigation with auth guards

### Infrastructure (v1.0.0)
- AWS CDK (C#): 11 stacks (Network, Database, Storage, Auth, AI, Compute, DbAccess, Outbox, Observability, Web, CiCd)
- Split-Lambda pattern: non-VPC API Lambda + VPC DB Lambda
- DynamoDB (6 tables, PAY_PER_REQUEST) + PostgreSQL (db.t4g.micro)
- S3 + CloudFront for marketing site
- API Gateway REST API with rate limiting
- GitHub OIDC for zero-secret CI/CD

### Marketing Site (v1.0.0)
- Initial release: Astro static site for getconscia.com
- Landing page: hero, features, how it works, pricing, footer
- S3 + CloudFront hosting ($0/mo at low traffic)
