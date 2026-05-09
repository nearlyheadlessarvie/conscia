import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';

const html = readFileSync(new URL('../dist/index.html', import.meta.url), 'utf8');

test('homepage uses the mascot-led storytelling headline and app-first CTA', () => {
  assert.match(html, /Your financial conscience, in full color\./);
  assert.match(html, /Open the app/);
  assert.match(html, /See how it works/);
  assert.match(html, /Meet the inner voices/);
  assert.doesNotMatch(html, /Start with the free plan/);
  assert.doesNotMatch(html, /Join the beta/);
});

test('homepage renders the three storytelling chapters in order', () => {
  assert.match(html, /Catch the moment/);
  assert.match(html, /Reflect without shame/);
  assert.match(html, /Build better habits/);
  assert.match(html, /Pre-purchase assistant/);
  assert.match(html, /Reflection prompts/);
  assert.match(html, /Recurring transactions/);
});
