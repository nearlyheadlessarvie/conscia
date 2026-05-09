import angelAtlas from '../data/mascots/angel.json' with { type: 'json' };
import devilAtlas from '../data/mascots/devil.json' with { type: 'json' };
import moneyAtlas from '../data/mascots/money.json' with { type: 'json' };

function loadAtlas(atlas, imagePath) {
  const frameMap = new Map(atlas.sprites.map((sprite) => [sprite.fileName, sprite]));

  return {
    imagePath,
    sheetWidth: atlas.spriteSheetWidth,
    sheetHeight: atlas.spriteSheetHeight,
    frameMap,
  };
}

const atlases = {
  angel: loadAtlas(angelAtlas, '/images/mascots/angel/sprite_sheet.png'),
  devil: loadAtlas(devilAtlas, '/images/mascots/devil/sprite_sheet.png'),
  money: loadAtlas(moneyAtlas, '/images/mascots/money/sprite_sheet.png'),
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
