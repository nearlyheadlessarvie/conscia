import { readFileSync } from 'node:fs';

function loadAtlas(relativePath, imagePath) {
  const file = new URL(relativePath, import.meta.url);
  const atlas = JSON.parse(readFileSync(file, 'utf8'));
  const frameMap = new Map(atlas.sprites.map((sprite) => [sprite.fileName, sprite]));

  return {
    imagePath,
    sheetWidth: atlas.spriteSheetWidth,
    sheetHeight: atlas.spriteSheetHeight,
    frameMap,
  };
}

const atlases = {
  angel: loadAtlas('../data/mascots/angel.json', '/images/mascots/angel/sprite_sheet.png'),
  devil: loadAtlas('../data/mascots/devil.json', '/images/mascots/devil/sprite_sheet.png'),
  money: loadAtlas('../data/mascots/money.json', '/images/mascots/money/sprite_sheet.png'),
};

export function getMascotFrame(kind, fileName) {
  const atlas = atlases[kind];

  if (!atlas) {
    throw new Error(`Unknown mascot atlas: ${kind}`);
  }

  const frame = atlas.frameMap.get(fileName);

  if (!frame) {
    throw new Error(`Unknown mascot frame: ${kind}/${fileName}`);
  }

  return {
    ...frame,
    imagePath: atlas.imagePath,
    sheetWidth: atlas.sheetWidth,
    sheetHeight: atlas.sheetHeight,
  };
}
