# Release Dependency Matrix

## Component Dependencies

| Component | Depends On | Min Version Required |
|-----------|-----------|---------------------|
| Flutter App (app/) | API | api >= 1.0.0 |
| API (src/) | Infrastructure | infra >= 1.0.0 |
| Marketing Site (web/) | Infrastructure (WebStack) | infra >= 1.0.0 |
| Infrastructure (infra/) | None | — |

## Deployment Order

1. **Infrastructure** (infra/) — must deploy first if stack changes
2. **API** (src/) — deploys after infra if compute/network changes
3. **Marketing Site** (web/) — independent after initial infra deploy
4. **Flutter App** (app/) — independent, distributed via app stores

## Breaking Changes Log

| Date | Component | Version | Breaking Change | Requires |
|------|-----------|---------|-----------------|----------|
| — | — | — | No breaking changes yet | — |

## Version History

| Release Date | API | App | Infra | Web |
|-------------|-----|-----|-------|-----|
| 2026-05-01 | 1.0.0 | 1.0.0+1 | 1.0.0 | 1.0.0 |
