export const heroContent = {
  kicker: 'Finance wellness, made simple',
  title: 'Your all-in-one money system.',
  body:
    'Track spending, reflect on purchases, manage budgets, scan receipts, surface patterns, and coordinate shared household planning — all in one calm place.',
  supportBullets: [
    'Record every money moment',
    'Reflect before, during, and after',
    'Scan receipts without losing the details',
    'Start on the budgets that matter',
    'Insights that help you make better choices',
    'Plan together with the people you trust',
  ],
};

export const storyChapters = [
  {
    id: 'transactions-and-filters',
    kicker: 'Track every moment',
    title: 'Transactions that tell your story.',
    body:
      'Capture every expense in seconds. Filter by time or category, and see your money moments in context.',
    bullets: [
      'Smart filters surface what matters fast',
      'Categories keep your records readable',
      'Realtime totals reveal your spending trail',
    ],
    image: '/images/marketing/transactions.png',
    imageAlt: 'Conscia transactions screen with spending trail, date filter, and category chips',
    screenId: 'transactions',
  },
  {
    id: 'reflection-and-purchase-assistant',
    kicker: 'Reflect with intention',
    title: 'Pause. Reflect. Decide with clarity.',
    body:
      'Conscia guides you before, during, and after you spend so you can turn purchases into something useful instead of automatic.',
    bullets: [
      'Pre-purchase prompts bring the decision into focus',
      'Reflections turn moments into signal',
      'Gentle follow-through helps the next choice feel clearer',
    ],
    image: '/images/marketing/purchase-assistant.png',
    imageAlt: 'Conscia purchase assistant screen prompting a buying decision',
    screenId: 'assistant',
  },
  {
    id: 'receipt-scanning',
    kicker: 'Scan and review',
    title: 'Scan receipts without losing the plot.',
    body:
      'Turn paper receipts into transaction drafts, then sanity-check the merchant, amount, category, and line items before they become part of your record.',
    bullets: [
      'Confidence cues show when details need review',
      'Editable fields keep the final transaction accurate',
      'Extracted line items preserve useful context',
    ],
    image: '/images/marketing/scan-receipt.png',
    imageAlt: 'Conscia receipt review screen showing scan confidence and extracted receipt items',
    screenId: 'receipt',
  },
  {
    id: 'budgets-and-categories',
    kicker: 'Stay on budget',
    title: 'Budgets that keep you in control.',
    body:
      'Create calm, clear monthly guardrails so you always know what is okay, what is close, and what needs attention.',
    bullets: [
      'Monthly caps keep your spending visible',
      'View progress by category in one glance',
      'Category flows stay tidy across the full system',
    ],
    image: '/images/marketing/budget.png',
    imageAlt: 'Conscia budgets screen with category budget pacing and donut chart',
    screenId: 'budgets',
  },
  {
    id: 'insights-and-merchant-signals',
    kicker: 'Insights that matter',
    title: 'Patterns > reactions.',
    body:
      'Conscia surfaces the patterns behind your spending so you can act with understanding, not impulse.',
    bullets: [
      'Regret signals catch what is heating up',
      'Merchant watchlists reveal where habits repeat',
      'Actionable views help you respond early on',
    ],
    image: '/images/marketing/insights.png',
    imageAlt: 'Conscia insights screen highlighting regret patterns and merchant signals',
    screenId: 'insights',
  },
  {
    id: 'shared-household-and-settings',
    kicker: 'Plan together',
    title: 'Money is better together.',
    body:
      'Coordinate, plan, and stay aligned with the people you trust, while keeping your personal layer intact.',
    bullets: [
      'Shared households create a calm planning layer',
      'Roles and boundaries stay clear from the start',
      'Settings and premium live in the same system',
    ],
    image: '/images/marketing/family.png',
    imageAlt: 'Conscia shared household screen with members and invite controls',
    screenId: 'household',
  },
];
