import { mkdir, writeFile } from 'node:fs/promises';
import path from 'node:path';

const requireEnv = process.env.REQUIRE_PASSKEY_ASSOCIATIONS === 'true';

const iosBundleId = process.env.IOS_BUNDLE_ID?.trim();
const appleTeamId = process.env.APPLE_TEAM_ID?.trim();
const androidPackageName = process.env.GOOGLE_PLAY_PACKAGE_NAME?.trim();
const androidFingerprints = (process.env.ANDROID_PASSKEY_SHA256_CERT_FINGERPRINTS ?? '')
  .split(',')
  .map((value) => value.trim())
  .filter(Boolean);

const missing = [
  !iosBundleId && 'IOS_BUNDLE_ID',
  !appleTeamId && 'APPLE_TEAM_ID',
  !androidPackageName && 'GOOGLE_PLAY_PACKAGE_NAME',
  androidFingerprints.length === 0 && 'ANDROID_PASSKEY_SHA256_CERT_FINGERPRINTS',
].filter(Boolean);

if (missing.length > 0) {
  if (requireEnv) {
    throw new Error(
      `Missing passkey association environment values: ${missing.join(', ')}`,
    );
  }

  console.warn(
    `Skipping passkey association generation because these values are missing: ${missing.join(', ')}`,
  );
  process.exit(0);
}

const wellKnownDir = path.join(process.cwd(), 'public', '.well-known');
await mkdir(wellKnownDir, { recursive: true });

const appId = `${appleTeamId}.${iosBundleId}`;
const appleAssociation = {
  applinks: {
    details: [
      {
        appIDs: [appId],
        components: [
          {
            '/': '/open/family-invite*',
          },
          {
            '/': '/open/auth/callback*',
          },
          {
            '/': '/open/auth/logout*',
          },
        ],
      },
    ],
  },
  webcredentials: {
    apps: [appId],
  },
};

const assetLinks = [
  {
    relation: [
      'delegate_permission/common.handle_all_urls',
      'delegate_permission/common.get_login_creds',
    ],
    target: {
      namespace: 'android_app',
      package_name: androidPackageName,
      sha256_cert_fingerprints: androidFingerprints,
    },
  },
];

await writeFile(
  path.join(wellKnownDir, 'apple-app-site-association'),
  JSON.stringify(appleAssociation, null, 2),
);
await writeFile(
  path.join(wellKnownDir, 'assetlinks.json'),
  JSON.stringify(assetLinks, null, 2),
);

console.log('Generated passkey association files in public/.well-known');
