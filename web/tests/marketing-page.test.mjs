import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, resolve } from 'node:path';

const testDir = dirname(fileURLToPath(import.meta.url));
const html = readFileSync(resolve(testDir, '../dist/index.html'), 'utf8');

test('homepage leads with the all-in-one money system message', () => {
  assert.match(html, /all-in-one money system/i);
  assert.match(html, /track spending/i);
  assert.match(html, /manage budgets/i);
  assert.match(html, /scan receipts/i);
  assert.match(html, /shared household/i);
  assert.doesNotMatch(html, /Your money has a story/);
});

test('homepage metadata and badges use production icon and store links', () => {
  assert.match(html, /https:\/\/apps\.apple\.com\/app\/id6771674327/);
  assert.match(html, /https:\/\/play\.google\.com\/store\/apps\/details\?id=com\.getconscia\.app\.ai/);
  assert.match(html, /rel="icon" type="image\/svg\+xml" href="\/images\/app_icon\.svg"/);
  assert.match(html, /rel="icon" type="image\/png" href="\/images\/app_icon\.png"/);
  assert.match(html, /property="og:image" content="\/images\/app_icon\.png"/);
});

test('homepage presents system sections in the new order', () => {
  assert.match(html, /Transactions and filters/);
  assert.match(html, /Reflection and purchase assistant/);
  assert.match(html, /Budgets and categories/);
  assert.match(html, /Insights and merchant signals/);
  assert.match(html, /Shared household and settings/);
});

test('homepage references current product surfaces instead of older journey-only framing', () => {
  assert.match(html, /receipt/i);
  assert.match(html, /purchase assistant/i);
  assert.match(html, /shared household/i);
  assert.match(html, /merchant/i);
  assert.doesNotMatch(html, /Three moments\. One loop\./);
});

test('homepage contains no mascot references', () => {
  assert.doesNotMatch(html, /aria-label="Devil mascot"/);
  assert.doesNotMatch(html, /aria-label="Angel mascot"/);
  assert.doesNotMatch(html, /aria-label="Receipt mascot"/);
  assert.doesNotMatch(html, /mascot-sprite/);
  assert.doesNotMatch(html, /hero-battle-scene/);
});

test('footer keeps the lockup while the homepage atmosphere shifts app-ward', () => {
  assert.match(html, /Small choices, big freedom/);
  assert.doesNotMatch(html, /Meet the inner voices/);
});
