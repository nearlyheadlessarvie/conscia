import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';

const html = readFileSync(new URL('../dist/index.html', import.meta.url), 'utf8');

test('homepage uses the mascot-led storytelling headline and store-style platform badges', () => {
  assert.match(html, /Your financial conscience\./);
  assert.match(html, /Meet the inner voices/);
  assert.match(html, /aria-label="Open on iOS"/);
  assert.match(html, /aria-label="Open on Android"/);
  assert.match(html, /Download on the/);
  assert.match(html, /App Store/);
  assert.match(html, /Get it on/);
  assert.match(html, /Google Play/);
  assert.doesNotMatch(html, /See how it works/);
  assert.doesNotMatch(html, /How it works/);
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

test('homepage removes the dead-end open app section and keeps the lighter footer', () => {
  assert.doesNotMatch(html, /Why the app first/);
  assert.doesNotMatch(html, /The app handles onboarding and account creation/);
  assert.doesNotMatch(html, />Open the app</);
  assert.match(html, /Send feedback/);
});

test('hero mascot sprites render at scaled dimensions instead of full atlas cell size', () => {
  assert.match(html, /aria-label="Devil mascot"/);
  assert.match(html, /width:275\.88px; height:275\.88px;/);
  assert.doesNotMatch(html, /aria-label="Devil mascot"[^>]*width:1254px; height:1254px;/);
});
