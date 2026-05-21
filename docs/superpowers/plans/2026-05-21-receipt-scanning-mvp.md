# Receipt Scanning MVP Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship real premium receipt scanning for MVP using AWS OCR/parsing instead of a stub or placeholder.

**Architecture:** The Flutter receipt scanner uploads an image to the authenticated receipts API. The API stores the original image in S3, extracts text with Textract, parses structured receipt fields with Bedrock, persists a reviewable receipt record, and requires the user to confirm details before creating the transaction.

**Tech Stack:** Flutter, Dio, ASP.NET Minimal APIs, AWS S3, AWS Textract, AWS Bedrock Runtime, xUnit, Moq.

---

### Task 1: Restore Honest App Entry Points

**Files:**
- Modify: `app/lib/widgets/speed_dial_fab.dart`
- Modify: `app/lib/screens/settings/settings_screen.dart`
- Modify: `app/lib/screens/settings/widgets/subscription_sheet.dart`
- Test: `app/test/widgets/speed_dial_fab_test.dart`

- [ ] **Step 1: Write failing UI expectation**

```dart
expect(find.text('Scan Receipt'), findsOneWidget);
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/widgets/speed_dial_fab_test.dart`
Expected: FAIL because the scan action was removed during the hardening audit.

- [ ] **Step 3: Restore the action**

Re-add a `SpeedDialChild` labelled `Scan Receipt` that navigates to `AppRoutes.scan`.

- [ ] **Step 4: Restore Premium copy**

Restore receipt scanning as an included Premium feature now that the backend will be real.

- [ ] **Step 5: Verify**

Run: `flutter test test/widgets/speed_dial_fab_test.dart test/screens/settings/subscription_sheet_test.dart`
Expected: PASS.

### Task 2: Add AWS Receipt OCR Service

**Files:**
- Create: `src/Conscia.AI/Services/AwsReceiptOcrService.cs`
- Modify: `src/Conscia.Api/Program.cs`
- Test: `tests/Conscia.Tests.Unit/Infrastructure/AwsReceiptOcrServiceTests.cs`

- [ ] **Step 1: Write failing tests**

Tests must prove the service:
- calls Textract with the configured S3 bucket and key,
- sends extracted text to Bedrock,
- parses strict JSON into `ReceiptScanResultDto`,
- returns null currency when absent instead of inventing USD.

- [ ] **Step 2: Run tests to verify failure**

Run: `dotnet test tests/Conscia.Tests.Unit --filter AwsReceiptOcrServiceTests --no-restore`
Expected: FAIL because `AwsReceiptOcrService` does not exist.

- [ ] **Step 3: Implement service**

Use `IAmazonTextract.DetectDocumentTextAsync` for OCR and `IAmazonBedrockRuntime.InvokeModelAsync` for JSON parsing. Parse Anthropic response `content[0].text` and deserialize the embedded JSON object.

- [ ] **Step 4: Register service in production**

Register `StubOcrService` only in development. Register AWS Textract and `AwsReceiptOcrService` outside development.

- [ ] **Step 5: Verify**

Run: `dotnet test tests/Conscia.Tests.Unit --filter AwsReceiptOcrServiceTests --no-restore`
Expected: PASS.

### Task 3: Final Verification

**Files:**
- All changed app/API files.

- [ ] **Step 1: Run app checks**

Run: `flutter analyze`
Expected: PASS.

Run: `flutter test`
Expected: PASS.

- [ ] **Step 2: Run backend checks**

Run: `dotnet test --no-build --verbosity minimal`
Expected: PASS for unit tests. If a local API process locks build outputs, do not kill it without confirmation; use `--no-build` and report the lock.

- [ ] **Step 3: Placeholder scan**

Run: `rg -n "TODO|FIXME|Coming soon|StubOcrService|Receipt Scanner" app/lib src/Conscia.Api src/Conscia.AI src/Conscia.Infrastructure`
Expected: no user-facing receipt scanner placeholders; `StubOcrService` remains only as development fail-closed fallback.
