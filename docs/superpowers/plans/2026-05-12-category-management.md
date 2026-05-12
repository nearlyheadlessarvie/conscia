# Category Management Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make personal and family categories first-class managed records while keeping existing string-based transaction and budget flows compatible.

**Architecture:** Add a Postgres-backed `ManagedCategory` entity with repository, service, and `/api/v1/categories` endpoints. Flutter reads managed categories through a provider, exposes a Settings category manager, and uses managed categories in existing pickers while still allowing inline creation.

**Tech Stack:** .NET 8 minimal APIs, EF Core/Postgres, Flutter/Riverpod, widget tests, xUnit/Moq.

---

### Task 1: Backend Category Domain And API

**Files:**
- Create: `src/Conscia.Domain/Entities/ManagedCategory.cs`
- Create: `src/Conscia.Application/DTOs/CategoryDtos.cs`
- Create: `src/Conscia.Application/Interfaces/ICategoryRepository.cs`
- Create: `src/Conscia.Application/Interfaces/ICategoryService.cs`
- Create: `src/Conscia.Application/Services/CategoryService.cs`
- Create: `src/Conscia.Infrastructure/Persistence/Configurations/ManagedCategoryConfiguration.cs`
- Create: `src/Conscia.Infrastructure/Repositories/CategoryRepository.cs`
- Create: `src/Conscia.Api/Endpoints/CategoryEndpoints.cs`
- Modify: `src/Conscia.Infrastructure/Persistence/ConsciaDbContext.cs`
- Modify: `src/Conscia.Api/Program.cs`
- Test: `tests/Conscia.Tests.Unit/Application/CategoryServiceTests.cs`
- Test: `tests/Conscia.Tests.Unit/Api/CategoryEndpointTests.cs`

- [ ] Write service tests for list defaults, create, rename, archive, duplicate rejection, family owner-only writes.
- [ ] Run service tests and verify they fail because category types are missing.
- [ ] Implement entity, DTOs, repository, service, DI, and endpoints.
- [ ] Run service and endpoint tests and verify they pass.
- [ ] Commit as `feat: add managed category api`.

### Task 2: Flutter Category Manager

**Files:**
- Create: `app/lib/models/managed_category.dart`
- Create: `app/lib/providers/category_provider.dart`
- Create: `app/lib/screens/settings/category_management_screen.dart`
- Modify: `app/lib/core/constants/api_constants.dart`
- Modify: `app/lib/core/routing/app_router.dart`
- Modify: `app/lib/screens/settings/settings_screen.dart`
- Test: `app/test/screens/settings/category_management_screen_test.dart`

- [ ] Write widget/provider tests for rendering categories, adding one, renaming one, and archiving one.
- [ ] Run tests and verify they fail because the model/provider/screen are missing.
- [ ] Implement the model, provider actions, route, and Settings entry.
- [ ] Run Flutter tests and analyzer for touched files.
- [ ] Commit as `feat: add category management screen`.

### Task 3: Picker Integration

**Files:**
- Modify: `app/lib/screens/transactions/widgets/category_picker.dart`
- Modify: `app/lib/screens/transactions/widgets/quick_preset_chips.dart`
- Modify: `app/lib/screens/transactions/widgets/transaction_style_category_selector.dart`
- Modify: `app/lib/screens/transactions/transaction_form_screen.dart`
- Modify: `app/lib/screens/budgets/widgets/budget_form_sheet.dart`
- Modify: `app/lib/screens/assistant/pre_purchase_screen.dart`
- Test: existing picker/form tests plus new custom-category tests.

- [ ] Write tests showing the picker lists managed categories and can create a category from search text.
- [ ] Run tests and verify they fail before implementation.
- [ ] Replace generated-only category lists with managed category provider data plus default fallback suggestions.
- [ ] Record created/selected categories in recents so chips stay useful.
- [ ] Run Flutter tests/analyzer and backend focused tests.
- [ ] Commit as `feat: use managed categories in pickers`.
