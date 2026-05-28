import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, readFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import path, { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawnSync } from 'node:child_process';

const testDir = dirname(fileURLToPath(import.meta.url));
const scriptPath = resolve(testDir, '../scripts/generate-passkey-associations.mjs');

test('passkey associations exclude legacy auth callback and logout paths', () => {
  const cwd = mkdtempSync(path.join(tmpdir(), 'conscia-passkeys-'));
  const result = spawnSync(process.execPath, [scriptPath], {
    cwd,
    env: {
      ...process.env,
      IOS_BUNDLE_ID: 'com.getconscia.app.ai',
      APPLE_TEAM_ID: 'ABCDE12345',
      GOOGLE_PLAY_PACKAGE_NAME: 'com.getconscia.app.ai',
      ANDROID_PASSKEY_SHA256_CERT_FINGERPRINTS: 'AA:BB:CC',
    },
    encoding: 'utf8',
  });

  assert.equal(result.status, 0, result.stderr || result.stdout);

  const associationPath = resolve(
    cwd,
    'public/.well-known/apple-app-site-association',
  );
  const association = JSON.parse(readFileSync(associationPath, 'utf8'));
  const components = association.applinks.details[0].components.map(
    (entry) => entry['/'],
  );

  assert.deepEqual(components, ['/open/family-invite*']);
});
