import test from 'node:test';
import assert from 'node:assert/strict';
import { existsSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, resolve } from 'node:path';

const testDir = dirname(fileURLToPath(import.meta.url));

test('auth callback fallback page is no longer published', () => {
  assert.equal(
    existsSync(resolve(testDir, '../src/pages/open/auth/callback.astro')),
    false,
  );
});

test('auth logout fallback page is no longer published', () => {
  assert.equal(
    existsSync(resolve(testDir, '../src/pages/open/auth/logout.astro')),
    false,
  );
});
