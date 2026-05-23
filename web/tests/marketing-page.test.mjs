import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, resolve } from 'node:path';

const testDir = dirname(fileURLToPath(import.meta.url));
const html = readFileSync(resolve(testDir, '../dist/index.html'), 'utf8');

test('homepage follows the approved all-in-one money system story', () => {
  assert.match(html, /Your all-in-one money system\./);
  assert.match(
    html,
    /Track spending, reflect on purchases, manage budgets, scan receipts, surface patterns, and coordinate shared household planning/i,
  );
  assert.match(html, /Transactions that tell your story\./);
  assert.match(html, /Pause\. Reflect\. Decide with clarity\./);
  assert.match(html, /Budgets that keep you in control\./);
  assert.match(html, /Money is better together\./);
});

test('homepage metadata and badges use production icon and store links', () => {
  assert.match(html, /https:\/\/apps\.apple\.com\/app\/id6771674327/);
  assert.match(html, /https:\/\/play\.google\.com\/store\/apps\/details\?id=com\.getconscia\.app\.ai/);
  assert.match(html, /rel="icon" type="image\/svg\+xml" href="\/images\/app_icon\.svg"/);
  assert.match(html, /rel="icon" type="image\/png" href="\/images\/app_icon\.png"/);
  assert.match(html, /property="og:image" content="\/images\/app_icon\.png"/);
});

test('homepage presents the approved section story blocks', () => {
  assert.match(html, /Transactions that tell your story\./);
  assert.match(html, /Pause\. Reflect\. Decide with clarity\./);
  assert.match(html, /Budgets that keep you in control\./);
  assert.match(html, /Patterns (>|&gt;) reactions\./);
  assert.match(html, /Money is better together\./);
});

test('homepage hero includes the approved CTA rhythm', () => {
  assert.match(html, /Get Conscia/);
  assert.match(html, /See how it works/);
  assert.match(html, /Record every money moment/i);
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
