enum DevilBattlePose {
  neutral,
  push,
  block,
  force,
  tug,
  whisper,
  coin,
  receiptHook,
  sneak,
  ragePush,
  slip,
  frustrated,
  win,
  lose,
}

enum AngelBattlePose {
  neutral,
  block,
  push,
  force,
  tug,
  shield,
  coinShield,
  intercept,
  focusPray,
  holyBurst,
  lastStand,
  wingBlock,
  numberOne,
  win,
  lose,
}

enum MoneyBattlePose {
  neutral,
  left,
  right,
  save,
  afraid,
  squish,
  burst,
  folded,
}

enum ConscienceBattleOutcome { saved, spent }

enum LoaderShakeMode { none, light, impact, panic, tug }

class LoaderBattlePhase {
  const LoaderBattlePhase({
    required this.start,
    required this.end,
    required this.devilPose,
    required this.angelPose,
    required this.moneyPose,
    this.devilX = 0,
    this.angelX = 0,
    this.moneyX = 0,
    this.moneyY = 0,
    this.shake = LoaderShakeMode.none,
    this.shieldPulse = false,
    this.burstFlash = false,
    this.outcome,
  });

  final double start;
  final double end;
  final DevilBattlePose devilPose;
  final AngelBattlePose angelPose;
  final MoneyBattlePose moneyPose;
  final double devilX;
  final double angelX;
  final double moneyX;
  final double moneyY;
  final LoaderShakeMode shake;
  final bool shieldPulse;
  final bool burstFlash;
  final ConscienceBattleOutcome? outcome;

  bool contains(double t) => t >= start && t < end;
}

const assistantCommonPhases = <LoaderBattlePhase>[
  LoaderBattlePhase(
    start: 0.00,
    end: 0.12,
    devilPose: DevilBattlePose.neutral,
    angelPose: AngelBattlePose.neutral,
    moneyPose: MoneyBattlePose.neutral,
    moneyY: 0.16,
  ),
  LoaderBattlePhase(
    start: 0.12,
    end: 0.24,
    devilPose: DevilBattlePose.whisper,
    angelPose: AngelBattlePose.neutral,
    moneyPose: MoneyBattlePose.neutral,
    devilX: 0.05,
    moneyX: -0.04,
  ),
  LoaderBattlePhase(
    start: 0.24,
    end: 0.38,
    devilPose: DevilBattlePose.coin,
    angelPose: AngelBattlePose.intercept,
    moneyPose: MoneyBattlePose.left,
    devilX: 0.09,
    angelX: -0.08,
    moneyX: -0.12,
  ),
  LoaderBattlePhase(
    start: 0.38,
    end: 0.52,
    devilPose: DevilBattlePose.push,
    angelPose: AngelBattlePose.block,
    moneyPose: MoneyBattlePose.squish,
    shake: LoaderShakeMode.impact,
  ),
  LoaderBattlePhase(
    start: 0.52,
    end: 0.68,
    devilPose: DevilBattlePose.ragePush,
    angelPose: AngelBattlePose.lastStand,
    moneyPose: MoneyBattlePose.folded,
    moneyX: -0.08,
    shake: LoaderShakeMode.panic,
  ),
  LoaderBattlePhase(
    start: 0.68,
    end: 0.80,
    devilPose: DevilBattlePose.receiptHook,
    angelPose: AngelBattlePose.tug,
    moneyPose: MoneyBattlePose.right,
    moneyX: 0.10,
    shake: LoaderShakeMode.tug,
  ),
];

const assistantSavedPhases = <LoaderBattlePhase>[
  LoaderBattlePhase(
    start: 0.80,
    end: 0.92,
    devilPose: DevilBattlePose.slip,
    angelPose: AngelBattlePose.shield,
    moneyPose: MoneyBattlePose.save,
    moneyX: 0.12,
    shieldPulse: true,
    outcome: ConscienceBattleOutcome.saved,
  ),
  LoaderBattlePhase(
    start: 0.92,
    end: 1.01,
    devilPose: DevilBattlePose.frustrated,
    angelPose: AngelBattlePose.numberOne,
    moneyPose: MoneyBattlePose.save,
    moneyX: 0.14,
    outcome: ConscienceBattleOutcome.saved,
  ),
];

const assistantSpentPhases = <LoaderBattlePhase>[
  LoaderBattlePhase(
    start: 0.80,
    end: 0.92,
    devilPose: DevilBattlePose.win,
    angelPose: AngelBattlePose.lose,
    moneyPose: MoneyBattlePose.left,
    moneyX: -0.14,
    outcome: ConscienceBattleOutcome.spent,
  ),
  LoaderBattlePhase(
    start: 0.92,
    end: 1.01,
    devilPose: DevilBattlePose.win,
    angelPose: AngelBattlePose.lose,
    moneyPose: MoneyBattlePose.afraid,
    moneyX: -0.10,
    shake: LoaderShakeMode.panic,
    outcome: ConscienceBattleOutcome.spent,
  ),
];

const reflectionPhases = <LoaderBattlePhase>[
  LoaderBattlePhase(
    start: 0.00,
    end: 0.22,
    devilPose: DevilBattlePose.neutral,
    angelPose: AngelBattlePose.neutral,
    moneyPose: MoneyBattlePose.neutral,
    moneyY: 0.16,
  ),
  LoaderBattlePhase(
    start: 0.22,
    end: 0.42,
    devilPose: DevilBattlePose.whisper,
    angelPose: AngelBattlePose.focusPray,
    moneyPose: MoneyBattlePose.neutral,
  ),
  LoaderBattlePhase(
    start: 0.42,
    end: 0.64,
    devilPose: DevilBattlePose.sneak,
    angelPose: AngelBattlePose.intercept,
    moneyPose: MoneyBattlePose.left,
    moneyX: -0.05,
  ),
  LoaderBattlePhase(
    start: 0.64,
    end: 0.84,
    devilPose: DevilBattlePose.push,
    angelPose: AngelBattlePose.coinShield,
    moneyPose: MoneyBattlePose.save,
    moneyX: 0.04,
    shieldPulse: true,
  ),
  LoaderBattlePhase(
    start: 0.84,
    end: 1.01,
    devilPose: DevilBattlePose.neutral,
    angelPose: AngelBattlePose.neutral,
    moneyPose: MoneyBattlePose.save,
  ),
];
