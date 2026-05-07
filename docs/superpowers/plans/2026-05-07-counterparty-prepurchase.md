# Counterparty and Pre-Purchase Alignment Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rename transaction `merchant` to `counterparty` across the stack, rename location `merchantName` to `placeName`, make transaction UI labels type-aware, align Pre-Purchase Assistant category UX with transaction entry, and fix optimistic budget reconciliation plus free-tier category visibility.

**Architecture:** Keep the user-facing wording contextual while normalizing the underlying transaction model around `Counterparty` and `PlaceName`. Reuse the transaction form’s category-selection pattern inside Pre-Purchase Assistant instead of maintaining a separate dropdown flow. Extend the existing optimistic budget provider so transaction create, update, and delete all mutate local budget state consistently before background reconciliation.

**Tech Stack:** Flutter, Riverpod, Dio, GoRouter, .NET 8, ASP.NET Minimal APIs, EF Core, DynamoDB repository mapping, xUnit, Flutter test.

---

## File Structure

### Flutter app

- `app/lib/services/transaction_service.dart`
  - Rename app DTO/model payloads from `merchant` to `counterparty`.
- `app/lib/screens/transactions/transaction_form_screen.dart`
  - Switch field label between `Merchant` and `Source`.
  - Use the renamed DTO field.
- `app/lib/screens/assistant/pre_purchase_screen.dart`
  - Replace dropdown category control with shared category selection behavior.
- `app/lib/screens/transactions/widgets/category_picker.dart`
  - Reuse for assistant category selection.
- `app/lib/providers/budget_providers.dart`
  - Extend optimistic budget reconciliation to update and delete flows.
- `app/lib/screens/transactions/transaction_detail_screen.dart`
  - Ensure delete invalidates/reconciles budgets immediately.
- `app/lib/services/budget_service.dart`
  - No schema rename here, but tests may need to reflect mutation behavior.
- `app/lib/core/constants/generated/app_constants.g.dart`
  - Free-tier category-count constant source if needed for UI gating.
- `app/test/...`
  - Widget/provider/service tests for rename, label switching, assistant category UX, and budget mutation behavior.

### Backend

- `src/Conscia.Domain/Entities/Transaction.cs`
  - Rename `Merchant` to `Counterparty`; `Location.MerchantName` to `PlaceName`.
- `src/Conscia.Application/DTOs/CreateTransactionDto.cs`
- `src/Conscia.Application/DTOs/UpdateTransactionDto.cs`
- `src/Conscia.Application/Services/TransactionService.cs`
- `src/Conscia.Api/Endpoints/TransactionEndpoints.cs`
  - Rename payload fields and response shape.
- `src/Conscia.Infrastructure/Repositories/TransactionRepository.cs`
  - Rename Dynamo mapping keys and backwards-compatible read fallback.
- `src/Conscia.Infrastructure/Migrations/...`
  - Add migration for transaction table column rename if present in relational storage.
- `tests/Conscia.Tests.Unit/...`
  - Update transaction service/repository/API tests to use `Counterparty` and `PlaceName`.

### Docs

- `docs/superpowers/specs/2026-05-07-counterparty-prepurchase-design.md`
  - Already approved; no further doc changes required unless implementation diverges.

---

### Task 1: Transaction Form UI Copy and Assistant Category UX

**Files:**
- Modify: `app/lib/screens/transactions/transaction_form_screen.dart`
- Modify: `app/lib/screens/assistant/pre_purchase_screen.dart`
- Modify: `app/lib/screens/transactions/widgets/category_picker.dart`
- Test: `app/test/screens/transactions/transaction_form_screen_test.dart`
- Test: `app/test/screens/assistant/pre_purchase_screen_test.dart`

- [ ] **Step 1: Write the failing transaction-form label test**

```dart
testWidgets('income transactions label counterparty field as Source', (tester) async {
  await tester.pumpWidget(await buildTransactionFormApp(tester));

  await tester.tap(find.text('Income'));
  await tester.pumpAndSettle();

  expect(find.text('Source (optional)'), findsOneWidget);
  expect(find.text('Merchant (optional)'), findsNothing);
});
```

- [ ] **Step 2: Write the failing assistant category UX test**

```dart
testWidgets('pre-purchase assistant shows quick category chips and more categories entrypoint', (tester) async {
  await tester.pumpWidget(await buildPrePurchaseApp(tester));

  expect(find.text('Salary'), findsNothing);
  expect(find.text('More categories'), findsOneWidget);
  expect(find.text('Health'), findsWidgets);
});
```

- [ ] **Step 3: Run tests to verify they fail**

Run:

```bash
flutter test test/screens/transactions/transaction_form_screen_test.dart test/screens/assistant/pre_purchase_screen_test.dart
```

Expected:

```text
FAIL ... Source (optional) not found
FAIL ... More categories not found / dropdown still rendered
```

- [ ] **Step 4: Implement the UI changes**

```dart
// transaction_form_screen.dart
InputDecoration(
  labelText: _isExpense ? 'Merchant (optional)' : 'Source (optional)',
)

// pre_purchase_screen.dart
Row(
  children: [
    Text('Category', style: textTheme.titleSmall),
    const Spacer(),
    TextButton.icon(
      onPressed: _showCategoryPickerSheet,
      icon: const Icon(Icons.add, size: 16),
      label: const Text('More categories'),
    ),
  ],
);

if (_selectedCategory != null) {
  InputChip(...);
} else {
  QuickPresetChips(
    selectedCategory: _selectedCategory,
    isExpense: true,
    onCategorySelected: (cat) => setState(() => _selectedCategory = cat),
  );
}
```

- [ ] **Step 5: Run tests to verify they pass**

Run:

```bash
flutter test test/screens/transactions/transaction_form_screen_test.dart test/screens/assistant/pre_purchase_screen_test.dart
```

Expected:

```text
All tests passed!
```

- [ ] **Step 6: Commit**

```bash
git add app/lib/screens/transactions/transaction_form_screen.dart app/lib/screens/assistant/pre_purchase_screen.dart app/lib/screens/transactions/widgets/category_picker.dart app/test/screens/transactions/transaction_form_screen_test.dart app/test/screens/assistant/pre_purchase_screen_test.dart
git commit -m "feat: align transaction copy and prepurchase categories"
```

---

### Task 2: Flutter Counterparty and PlaceName Rename

**Files:**
- Modify: `app/lib/services/transaction_service.dart`
- Modify: `app/lib/models/transaction.dart`
- Modify: `app/lib/screens/dashboard/dashboard_screen.dart`
- Modify: `app/lib/screens/transactions/transaction_detail_screen.dart`
- Modify: `app/lib/screens/transactions/widgets/transaction_tile.dart`
- Test: `app/test/screens/transactions/transaction_detail_screen_test.dart`
- Test: `app/test/screens/transactions/transaction_form_screen_test.dart`

- [ ] **Step 1: Write the failing transaction JSON mapping test**

```dart
test('transaction json reads counterparty and placeName', () {
  final tx = Transaction.fromJson({
    'id': 'tx-1',
    'amount': 1000,
    'currencyCode': 'PHP',
    'category': 'Salary',
    'counterparty': 'ACME Corp',
    'type': 'Income',
    'date': '2026-05-07T00:00:00Z',
    'location': {
      'latitude': 14.55,
      'longitude': 121.02,
      'placeName': 'Home',
    },
  });

  expect(tx.description, 'ACME Corp');
});
```

- [ ] **Step 2: Run the focused test to verify it fails**

Run:

```bash
flutter test test/screens/transactions/transaction_form_screen_test.dart
```

Expected:

```text
FAIL ... counterparty key not mapped / merchant key still expected
```

- [ ] **Step 3: Implement the app-side rename**

```dart
// transaction_service.dart
description: json['counterparty'] as String? ??
    json['merchant'] as String? ??
    json['description'] as String? ?? '',

class CreateTransactionDto {
  final String counterparty;

  Map<String, dynamic> toJson() => {
    'counterparty': counterparty,
    'type': _capitalizeType(type),
    'date': date.toIso8601String(),
  };
}
```

- [ ] **Step 4: Update transaction form DTO usage**

```dart
final dto = CreateTransactionDto(
  amount: double.parse(_amountController.text),
  currencyCode: _currencyCode,
  category: _selectedCategory!,
  counterparty: _merchantController.text,
  type: _isExpense ? 'expense' : 'income',
  date: _selectedDate,
);
```

- [ ] **Step 5: Run Flutter tests**

Run:

```bash
flutter test test/screens/transactions/transaction_form_screen_test.dart test/screens/transactions/transaction_detail_screen_test.dart
flutter analyze lib/services/transaction_service.dart lib/screens/transactions/transaction_form_screen.dart
```

Expected:

```text
All tests passed!
No issues found!
```

- [ ] **Step 6: Commit**

```bash
git add app/lib/services/transaction_service.dart app/lib/models/transaction.dart app/lib/screens/dashboard/dashboard_screen.dart app/lib/screens/transactions/transaction_detail_screen.dart app/lib/screens/transactions/widgets/transaction_tile.dart app/test/screens/transactions/transaction_form_screen_test.dart app/test/screens/transactions/transaction_detail_screen_test.dart
git commit -m "refactor: rename merchant to counterparty in flutter"
```

---

### Task 3: Backend Counterparty and PlaceName Rename

**Files:**
- Modify: `src/Conscia.Domain/Entities/Transaction.cs`
- Modify: `src/Conscia.Application/DTOs/CreateTransactionDto.cs`
- Modify: `src/Conscia.Application/DTOs/UpdateTransactionDto.cs`
- Modify: `src/Conscia.Application/Services/TransactionService.cs`
- Modify: `src/Conscia.Api/Endpoints/TransactionEndpoints.cs`
- Modify: `src/Conscia.Infrastructure/Repositories/TransactionRepository.cs`
- Test: `tests/Conscia.Tests.Unit/Application/TransactionServiceTests.cs`
- Test: `tests/Conscia.Tests.Unit/Infrastructure/TransactionRepositoryMappingTests.cs`
- Test: `tests/Conscia.Tests.Unit/Api/TransactionEndpointTests.cs`

- [ ] **Step 1: Write the failing backend rename tests**

```csharp
[Fact]
public async Task CreateAsync_MapsCounterpartyAndPlaceName()
{
    var dto = new CreateTransactionDto
    {
        Category = "Salary",
        Counterparty = "ACME Corp",
        Latitude = 14.55,
        Longitude = 121.02,
        PlaceName = "Home",
    };

    var result = await _service.CreateAsync(userId, dto);

    Assert.Equal("ACME Corp", result.Counterparty);
    Assert.Equal("Home", result.Location!.PlaceName);
}
```

- [ ] **Step 2: Run the backend tests to verify they fail**

Run:

```bash
dotnet test tests/Conscia.Tests.Unit/Conscia.Tests.Unit.csproj --filter "FullyQualifiedName~TransactionServiceTests|FullyQualifiedName~TransactionRepositoryMappingTests"
```

Expected:

```text
FAIL ... CreateTransactionDto does not contain Counterparty
FAIL ... MerchantName still referenced
```

- [ ] **Step 3: Implement the backend rename**

```csharp
public class Transaction
{
    public string? Counterparty { get; set; }
}

public class Location
{
    public string? PlaceName { get; set; }
}

public class CreateTransactionDto
{
    public string? Counterparty { get; set; }
    public string? PlaceName { get; set; }
}
```

- [ ] **Step 4: Preserve read compatibility in Dynamo mapping**

```csharp
Counterparty = item.TryGetValue("Counterparty", out var c)
    ? c.S
    : item.TryGetValue("Merchant", out var m) ? m.S : null,

PlaceName = locationMap.TryGetValue("PlaceName", out var place)
    ? place.S
    : locationMap.TryGetValue("MerchantName", out var merchantName) ? merchantName.S : null,
```

- [ ] **Step 5: Update write mapping to emit only new keys**

```csharp
if (t.Counterparty is not null)
    item["Counterparty"] = new(t.Counterparty);

locationMap["PlaceName"] = new AttributeValue(location.PlaceName);
```

- [ ] **Step 6: Run backend verification**

Run:

```bash
dotnet test tests/Conscia.Tests.Unit/Conscia.Tests.Unit.csproj --filter "FullyQualifiedName~TransactionServiceTests|FullyQualifiedName~TransactionRepositoryMappingTests|FullyQualifiedName~TransactionEndpointTests"
dotnet build src/Conscia.Api/Conscia.Api.csproj
```

Expected:

```text
Passed!
Build succeeded.
```

- [ ] **Step 7: Commit**

```bash
git add src/Conscia.Domain/Entities/Transaction.cs src/Conscia.Application/DTOs/CreateTransactionDto.cs src/Conscia.Application/DTOs/UpdateTransactionDto.cs src/Conscia.Application/Services/TransactionService.cs src/Conscia.Api/Endpoints/TransactionEndpoints.cs src/Conscia.Infrastructure/Repositories/TransactionRepository.cs tests/Conscia.Tests.Unit/Application/TransactionServiceTests.cs tests/Conscia.Tests.Unit/Infrastructure/TransactionRepositoryMappingTests.cs tests/Conscia.Tests.Unit/Api/TransactionEndpointTests.cs
git commit -m "refactor: rename transaction merchant to counterparty"
```

---

### Task 4: Transaction Table Column Rename Migration

**Files:**
- Modify: `src/Conscia.Infrastructure/Persistence/*` if needed
- Create: `src/Conscia.Infrastructure/Migrations/<timestamp>_RenameMerchantToCounterparty.cs`
- Modify: `src/Conscia.Infrastructure/Migrations/ConsciaDbContextModelSnapshot.cs`
- Test: `tests/Conscia.Tests.Unit/Infrastructure/TransactionRepositoryMappingTests.cs`

- [ ] **Step 1: Scaffold the migration**

Run:

```bash
dotnet ef migrations add RenameTransactionMerchantToCounterparty --project src/Conscia.Infrastructure/Conscia.Infrastructure.csproj --startup-project src/Conscia.Api/Conscia.Api.csproj --output-dir Migrations
```

Expected:

```text
Done. To undo this action, use 'ef migrations remove'
```

- [ ] **Step 2: Adjust the migration to rename, not drop-and-add**

```csharp
protected override void Up(MigrationBuilder migrationBuilder)
{
    migrationBuilder.RenameColumn(
        name: "Merchant",
        table: "transactions",
        newName: "Counterparty");
}
```

- [ ] **Step 3: Verify migration snapshot matches the rename**

Run:

```bash
dotnet build src/Conscia.Api/Conscia.Api.csproj
```

Expected:

```text
Build succeeded.
```

- [ ] **Step 4: Commit**

```bash
git add src/Conscia.Infrastructure/Migrations
git commit -m "refactor: rename transaction merchant column"
```

---

### Task 5: Optimistic Budget Reconciliation for Create, Update, and Delete

**Files:**
- Modify: `app/lib/providers/budget_providers.dart`
- Modify: `app/lib/screens/transactions/transaction_form_screen.dart`
- Modify: `app/lib/screens/transactions/transaction_detail_screen.dart`
- Test: `app/test/providers/budget_providers_test.dart`
- Test: `app/test/screens/transactions/transaction_form_screen_test.dart`
- Test: `app/test/screens/transactions/transaction_detail_screen_test.dart`

- [ ] **Step 1: Write failing provider tests for update and delete budget adjustments**

```dart
test('optimistic update moves spend between categories', () {
  final next = notifier.applyOptimisticTransactionUpdate(
    previous: oldExpense,
    current: updatedExpense,
  );

  expect(readBudget('Dining').spent, 0);
  expect(readBudget('Shopping').spent, 1000);
});

test('optimistic delete removes budgeted expense spend', () {
  notifier.applyOptimisticTransactionDelete(expense);
  expect(readBudget('Shopping').spent, 0);
});
```

- [ ] **Step 2: Run tests to verify they fail**

Run:

```bash
flutter test test/providers/budget_providers_test.dart
```

Expected:

```text
FAIL ... applyOptimisticTransactionUpdate not defined
FAIL ... applyOptimisticTransactionDelete not defined
```

- [ ] **Step 3: Implement budget mutation helpers**

```dart
void applyOptimisticTransactionDelete(Transaction transaction) {
  if (transaction.type != 'expense') return;
  _adjustCategorySpend(transaction.category, -transaction.amount);
}

void applyOptimisticTransactionUpdate({
  required Transaction previous,
  required Transaction current,
}) {
  applyOptimisticTransactionDelete(previous);
  applyOptimisticTransaction(current);
}
```

- [ ] **Step 4: Wire update and delete flows**

```dart
// transaction_form_screen.dart
if (_isEditing) {
  ref.read(budgetListProvider.notifier).applyOptimisticTransactionUpdate(
    previous: originalTransaction,
    current: savedTransaction,
  );
}

// transaction_detail_screen.dart
await service.delete(widget.transactionId);
ref.read(budgetListProvider.notifier).applyOptimisticTransactionDelete(tx);
ref.read(budgetListProvider.notifier).scheduleRefreshInBackground();
```

- [ ] **Step 5: Run Flutter verification**

Run:

```bash
flutter test test/providers/budget_providers_test.dart test/screens/transactions/transaction_form_screen_test.dart test/screens/transactions/transaction_detail_screen_test.dart
flutter analyze lib/providers/budget_providers.dart lib/screens/transactions/transaction_form_screen.dart lib/screens/transactions/transaction_detail_screen.dart
```

Expected:

```text
All tests passed!
No issues found!
```

- [ ] **Step 6: Commit**

```bash
git add app/lib/providers/budget_providers.dart app/lib/screens/transactions/transaction_form_screen.dart app/lib/screens/transactions/transaction_detail_screen.dart app/test/providers/budget_providers_test.dart app/test/screens/transactions/transaction_form_screen_test.dart app/test/screens/transactions/transaction_detail_screen_test.dart
git commit -m "fix: reconcile budgets for transaction mutations"
```

---

### Task 6: Free-Tier Category Visibility Rules

**Files:**
- Modify: `app/lib/screens/transactions/widgets/category_picker.dart`
- Modify: `app/lib/screens/assistant/pre_purchase_screen.dart`
- Modify: `app/lib/screens/transactions/widgets/quick_preset_chips.dart`
- Modify: `app/lib/screens/budgets/widgets/budget_form_sheet.dart`
- Test: `app/test/screens/assistant/pre_purchase_screen_test.dart`
- Test: `app/test/screens/transactions/widgets/quick_preset_chips_test.dart`
- Test: `app/test/screens/budgets/budget_form_sheet_test.dart`

- [ ] **Step 1: Write failing free-tier visibility tests**

```dart
testWidgets('free users only see allowed budget categories', (tester) async {
  await tester.pumpWidget(await buildBudgetFormApp(isPremium: false));

  expect(find.text('Groceries'), findsOneWidget);
  expect(find.text('Travel'), findsNothing);
});
```

- [ ] **Step 2: Run tests to verify they fail**

Run:

```bash
flutter test test/screens/assistant/pre_purchase_screen_test.dart test/screens/transactions/widgets/quick_preset_chips_test.dart
```

Expected:

```text
FAIL ... unrestricted categories still visible
```

- [ ] **Step 3: Implement a shared visible-category rule**

```dart
List<String> visibleBudgetCategories({
  required bool isPremium,
  required List<String> categories,
}) {
  if (isPremium) return categories;
  return categories.take(FreemiumLimits.freeBudgetCategories).toList();
}
```

- [ ] **Step 4: Apply the shared rule in category surfaces**

```dart
final visibleCategories = visibleBudgetCategories(
  isPremium: isPremium,
  categories: expenseCategories,
);
```

- [ ] **Step 5: Run Flutter verification**

Run:

```bash
flutter test test/screens/assistant/pre_purchase_screen_test.dart test/screens/transactions/widgets/quick_preset_chips_test.dart
flutter analyze lib/screens/transactions/widgets/category_picker.dart lib/screens/assistant/pre_purchase_screen.dart lib/screens/transactions/widgets/quick_preset_chips.dart
```

Expected:

```text
All tests passed!
No issues found!
```

- [ ] **Step 6: Commit**

```bash
git add app/lib/screens/transactions/widgets/category_picker.dart app/lib/screens/assistant/pre_purchase_screen.dart app/lib/screens/transactions/widgets/quick_preset_chips.dart app/lib/screens/budgets/widgets/budget_form_sheet.dart app/test/screens/assistant/pre_purchase_screen_test.dart app/test/screens/transactions/widgets/quick_preset_chips_test.dart
git commit -m "fix: enforce free-tier category visibility in ui"
```

---

## Self-Review

- Spec coverage:
  - `Counterparty` rename: Tasks 2-4
  - `PlaceName` rename: Task 3
  - type-aware UI labels: Task 1
  - pre-purchase category alignment: Task 1
  - budget create/update/delete reconciliation: Task 5
  - freemium category visibility: Task 6
- Placeholder scan:
  - No `TODO`, `TBD`, or vague “handle appropriately” steps remain.
- Type consistency:
  - Uses `counterparty` and `placeName` consistently in app and backend tasks.

Plan complete and saved to `docs/superpowers/plans/2026-05-07-counterparty-prepurchase.md`. Two execution options:

**1. Subagent-Driven (recommended)** - I dispatch a fresh subagent per task, review between tasks, fast iteration

**2. Inline Execution** - Execute tasks in this session using executing-plans, batch execution with checkpoints

Which approach?
