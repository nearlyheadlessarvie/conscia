import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, resolve } from 'node:path';

const testDir = dirname(fileURLToPath(import.meta.url));
const callbackHtml = readFileSync(
  resolve(testDir, '../dist/open/auth/callback/index.html'),
  'utf8',
);
const logoutHtml = readFileSync(
  resolve(testDir, '../dist/open/auth/logout/index.html'),
  'utf8',
);

test('auth callback page hands control back to the app', () => {
  assert.match(callbackHtml, /Returning you to Conscia/);
  assert.match(callbackHtml, /conscia:\/\/auth\/callback/);
  assert.match(callbackHtml, /Open Conscia/);
  assert.match(callbackHtml, /<meta name="robots" content="noindex, nofollow"/);
  assert.doesNotMatch(callbackHtml, /window\.setTimeout/);
  assert.doesNotMatch(callbackHtml, /window\.location\.replace/);
});

test('auth logout page hands control back to the app', () => {
  assert.match(logoutHtml, /You are signed out/);
  assert.match(logoutHtml, /conscia:\/\/auth\/logout/);
  assert.match(logoutHtml, /Back to Conscia/);
  assert.match(logoutHtml, /<meta name="robots" content="noindex, nofollow"/);
  assert.doesNotMatch(logoutHtml, /window\.setTimeout/);
  assert.doesNotMatch(logoutHtml, /window\.location\.replace/);
});
