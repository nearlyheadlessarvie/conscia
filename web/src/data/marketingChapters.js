export const heroContent = {
  kicker: 'Meet the inner voices',
  title: 'Your financial conscience, in full color.',
  body:
    'Conscia turns impulse, reason, and reflection into one product flow so people can catch a spending decision before it disappears into a ledger.',
  primaryCta: { label: 'Open the app', href: '#open-the-app' },
  secondaryCta: { label: 'See how it works', href: '#experience' },
  proof: [
    'Pre-purchase assistant before a spend',
    'Fast logging when the moment already happened',
    'Reflection and habit-building after the emotion settles',
  ],
};

export const storyChapters = [
  {
    id: 'catch-the-moment',
    kicker: 'Catch the moment',
    title: 'Pre-purchase assistant and fast logging, right when the spend is still live.',
    body:
      'Use Conscia before the tap or immediately after. The product helps while the emotional context still exists instead of waiting for a month-end postmortem.',
    bullets: ['Pre-purchase assistant', 'Fast transaction logging', 'Real-world spending flow'],
    scene: {
      mood: 'warm',
      devilPose: '2_push.png',
      moneyPose: '4_save.png',
      uiBadge: 'Logged in seconds',
      cardTitle: 'Capture the spend',
    },
  },
  {
    id: 'reflect-without-shame',
    kicker: 'Reflect without shame',
    title: 'Reflection prompts that help users notice patterns without turning the app into a guilt machine.',
    body:
      'Conscia remembers hesitation, regret, and repeated second-guessing so users can learn from the moment rather than just archive it.',
    bullets: ['Reflection prompts', 'Regret memory', 'Pattern awareness'],
    scene: {
      mood: 'soft',
      angelPose: '8_shield.png',
      moneyPose: '1_neutral.png',
      uiBadge: 'Reflection + memory',
      cardTitle: 'Notice what happened',
    },
  },
  {
    id: 'build-better-habits',
    kicker: 'Build better habits',
    title: 'Budgets, recurring transactions, and insights that turn one decision into a steadier routine.',
    body:
      'The payoff is not one perfect choice. It is a better pattern: more context, calmer decisions, and stronger habits over time.',
    bullets: ['Budgets', 'Insights', 'Recurring transactions'],
    scene: {
      mood: 'cool',
      angelPose: '9_coinshield.png',
      moneyPose: '4_save.png',
      uiBadge: 'Reflection + budgets',
      cardTitle: 'See the payoff',
    },
  },
];
