# Release Dependency Matrix

## Component Dependencies

| Component | Depends On | Requirement |
|-----------|-----------|-------------|
| Flutter App (`app/`) | API | API contract `v=1` |
| API (`src/`) | Infrastructure | `infra >= 1.0.0` |
| Marketing Site (`web/`) | Infrastructure (WebStack) | `infra >= 1.0.0` |
| Infrastructure (`infra/`) | None | — |

## App/API Compatibility

| API Contract | Current Supported App | Previous Supported App |
|--------------|-----------------------|------------------------|
| `v=1` | `1.0.0+1` | `1.0.0+1` |

## Release Policy

- Releases are prepared as release PRs and only tagged after the release PR merges.
- Semver is driven by Conventional Commits.
- App builds declare their exact build version in `X-Conscia-App-Version`.
- The API contract stays coarse-grained at query version `v=1` until a real breaking contract change requires `v=2`.

## Deployment Order

1. **Infrastructure** (`infra/`) — deploy first when stack changes.
2. **API** (`src/`) — deploy after infra for compute/network/runtime changes.
3. **Marketing Site** (`web/`) — deploy independently after initial infra setup.
4. **Flutter App** (`app/`) — release independently through the stores.

## Breaking Changes Log

| Date | Component | Version | Breaking Change | Requires |
|------|-----------|---------|-----------------|----------|
| — | — | — | No breaking changes yet | — |

## Version History

| Release Date | API | App | Infra | Web |
|-------------|-----|-----|-------|-----|
| 2026-05-20 | 1.0.0 | 1.0.0+1 | 1.0.0 | 1.0.0 |
