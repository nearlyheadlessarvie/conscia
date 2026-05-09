import test from 'node:test';
import assert from 'node:assert/strict';

import { getMascotFrame } from '../src/utils/mascotFrames.js';

test('resolves devil whisper frame from sprite metadata', () => {
  const frame = getMascotFrame('devil', '8_whisper.png');

  assert.equal(frame.imagePath, '/images/mascots/devil/sprite_sheet.png');
  assert.equal(frame.x, 2508);
  assert.equal(frame.y, 1254);
  assert.equal(frame.width, 1254);
  assert.equal(frame.height, 1254);
});

test('throws for an unknown pose name', () => {
  assert.throws(() => getMascotFrame('angel', '404_missing.png'), /Unknown mascot frame/);
});
