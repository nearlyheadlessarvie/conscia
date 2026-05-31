import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, resolve } from 'node:path';

const testDir = dirname(fileURLToPath(import.meta.url));
const html = readFileSync(resolve(testDir, '../dist/index.html'), 'utf8');
const underDevelopmentHtml = readFileSync(resolve(testDir, '../dist/under-development/index.html'), 'utf8');

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

test('homepage metadata and badges use production icon and app development links', () => {
  assert.match(html, /href="\/under-development\?platform=ios"/);
  assert.match(html, /href="\/under-development\?platform=android"/);
  assert.match(html, /rel="icon" type="image\/svg\+xml" href="\/images\/app_icon\.svg"/);
  assert.match(html, /rel="icon" type="image\/png" href="\/images\/app_icon\.png"/);
  assert.match(html, /property="og:image" content="\/images\/app_icon\.png"/);
});

test('homepage presents the approved section story blocks', () => {
  assert.match(html, /Transactions that tell your story\./);
  assert.match(html, /Pause\. Reflect\. Decide with clarity\./);
  assert.match(html, /Scan receipts without losing the plot\./);
  assert.match(html, /Budgets that keep you in control\./);
  assert.match(html, /Patterns (>|&gt;) reactions\./);
  assert.match(html, /Money is better together\./);
});

test('homepage uses current product screenshots in the expected sections', () => {
  assert.match(html, /src="\/images\/marketing\/journey\.png"/);
  assert.match(html, /src="\/images\/marketing\/transactions\.png"/);
  assert.match(html, /src="\/images\/marketing\/purchase-assistant\.png"/);
  assert.match(html, /src="\/images\/marketing\/scan-receipt\.png"/);
  assert.match(html, /src="\/images\/marketing\/budget\.png"/);
  assert.match(html, /src="\/images\/marketing\/insights\.png"/);
  assert.match(html, /src="\/images\/marketing\/family\.png"/);
});

test('homepage hero keeps the current product screenshots focused', () => {
  assert.match(html, /hero-shot hero-shot-left/);
  assert.match(html, /hero-shot hero-shot-center/);
  assert.match(html, /hero-shot hero-shot-right/);
  assert.doesNotMatch(html, /hero-shot-back/);
});

test('homepage hero uses store badges as the primary actions', () => {
  assert.doesNotMatch(html, /Get Conscia/);
  assert.doesNotMatch(html, /See how it works/);
  assert.match(html, /Record every money moment/i);
  assert.match(html, /App Store/);
  assert.match(html, /Google Play/);
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

test('app store placeholder keeps visitors in the Conscia experience', () => {
  assert.match(underDevelopmentHtml, /Conscia is still getting ready/);
  assert.match(underDevelopmentHtml, /Small choices, big freedom/);
  assert.match(underDevelopmentHtml, /Back to Conscia/);
  assert.doesNotMatch(underDevelopmentHtml, /aria-label="Conscia home"/);
  assert.doesNotMatch(underDevelopmentHtml, /404/);
});
