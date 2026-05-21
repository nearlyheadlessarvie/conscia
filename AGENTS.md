# AGENTS.md

## Behavioral Guidelines

### Think Before Coding

- State assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them; do not pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop, name what is confusing, and ask.

### Simplicity First

- Do not add features beyond what was asked.
- Do not add abstractions for single-use code.
- Do not add flexibility or configurability that was not requested.
- Do not add error handling for impossible scenarios.
- If a change becomes much larger than necessary, simplify before finishing.

### Surgical Changes

- Do not improve adjacent code, comments, or formatting unless required by the task.
- Do not refactor things that are not broken.
- Match existing style, even if you would do it differently.
- If you notice unrelated dead code, mention it instead of deleting it.
- Remove imports, variables, or functions that your changes made unused.
- Every changed line should trace directly to the user's request.

### Goal-Driven Execution

- Transform tasks into verifiable goals.
- For multi-step tasks, state a brief plan with verification steps.
- Prefer checks that prove the requested behavior, not just broad confidence checks.

## Commit And PR Rules

- Always create small, atomic commits.
- Use Conventional Commits: `type(scope): description`.
- Allowed types: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `chore`, `build`, `ci`, `revert`.
- Limit each commit to one logical change.
- Commit after completing a task or coherent file-change set.
- Use `git commit -m`; do not use interactive commit editors.
- Use GitHub CLI (`gh`) for PR lookup, creation, editing, and status checks.
- Never stage unrelated user changes silently. Inspect `git status -sb` and stage explicit paths when the worktree is mixed.

## Release Rules

- Release PRs are prepared by release-please from Conventional Commit history after changes merge to `main`.
- Release-please is configured for separate component PRs:
  - `app` -> tag format `app/vX.Y.Z`
  - `src/Conscia.Api` -> tag format `api/vX.Y.Z`
  - `infra/src/Conscia.Infra` -> tag format `infra/vX.Y.Z`
  - `web` -> tag format `web/vX.Y.Z`
- A PR alone does not deploy. Deploy workflows trigger only when the corresponding release tag is created:
  - `.github/workflows/release-app.yml` runs on `app/v*`
  - `.github/workflows/release-api.yml` runs on `api/v*`
  - `.github/workflows/release-infra.yml` runs on `infra/v*`
  - `.github/workflows/release-web.yml` runs on `web/v*`
- Use Conventional Commit scopes that match the component when a change should be releasable:
  - `feat(app): ...`, `fix(app): ...`, `ci(app): ...`
  - `feat(api): ...`, `fix(api): ...`, `ci(api): ...`
  - `feat(infra): ...`, `fix(infra): ...`, `ci(infra): ...`
  - `feat(web): ...`, `fix(web): ...`, `ci(web): ...`
- Release impact by type:
  - `feat(...)` creates a minor release for the affected component.
  - `fix(...)` creates a patch release for the affected component.
  - Breaking changes must use Conventional Commit breaking-change syntax and require explicit user confirmation before commit.
  - `docs`, `test`, `chore`, `ci`, `build`, `style`, and `refactor` may or may not be included in release notes depending on release-please config; do not rely on them to trigger a deployable product release unless verified.
- App release PRs also trigger the compatibility metadata sync workflow when the release PR updates `app/pubspec.yaml`.
- Do not create release tags manually unless the user explicitly asks for a release.

## Verification

- Before claiming completion, run the smallest relevant verification command(s) available.
- If a command cannot be run locally, state that clearly and explain what was checked instead.
- For workflow changes, at minimum parse/check the workflow file and inspect referenced secrets/variables when possible.
- For app identity/signing changes, check platform manifests/config files and any affected release documentation.
