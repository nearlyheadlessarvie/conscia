import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';

const html = readFileSync(new URL('../dist/index.html', import.meta.url), 'utf8');

test('homepage uses the new Journey-tone headline and store-style platform badges', () => {
  assert.match(html, /Your money has a story/);
  assert.match(html, /Personal finance/);
  assert.match(html, /aria-label="Open on iOS"/);
  assert.match(html, /aria-label="Open on Android"/);
  assert.match(html, /Download on the/);
  assert.match(html, /App Store/);
  assert.match(html, /Get it on/);
  assert.match(html, /Google Play/);
  assert.doesNotMatch(html, /Your financial conscience/);
  assert.doesNotMatch(html, /Meet the inner voices/);
});

test('homepage metadata and badges use production icon and store links', () => {
  assert.match(html, /https:\/\/apps\.apple\.com\/app\/id6771674327/);
  assert.match(html, /https:\/\/play\.google\.com\/store\/apps\/details\?id=com\.getconscia\.app\.ai/);
  assert.match(html, /rel="icon" type="image\/svg\+xml" href="\/images\/app_icon\.svg"/);
  assert.match(html, /rel="icon" type="image\/png" href="\/images\/app_icon\.png"/);
  assert.match(html, /property="og:image" content="\/images\/app_icon\.png"/);
});

test('homepage renders the three redesigned chapters in order', () => {
  assert.match(html, /Log the moment/);
  assert.match(html, /Reflect without shame/);
  assert.match(html, /See the patterns/);
  assert.doesNotMatch(html, /Catch the moment/);
  assert.doesNotMatch(html, /Build better habits/);
});

test('homepage includes How it works section', () => {
  assert.match(html, /How it works/);
  assert.match(html, /Pause before you spend/);
  assert.match(html, /Log every moment/);
  assert.match(html, /Reflect and notice/);
});

test('homepage contains no mascot references', () => {
  assert.doesNotMatch(html, /aria-label="Devil mascot"/);
  assert.doesNotMatch(html, /aria-label="Angel mascot"/);
  assert.doesNotMatch(html, /aria-label="Receipt mascot"/);
  assert.doesNotMatch(html, /mascot-sprite/);
  assert.doesNotMatch(html, /hero-battle-scene/);
});

test('footer uses dark navy design with tagline', () => {
  assert.match(html, /Small choices, big freedom/);
  assert.match(html, /\/privacy/);
  assert.match(html, /\/terms/);
});
