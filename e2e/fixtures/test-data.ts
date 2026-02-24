export function createCombatNode(overrides: Record<string, unknown> = {}) {
  const ts = Date.now();
  return {
    name: `Test Combat ${ts}`,
    type: 'combat' as const,
    biome: 'the_bush' as const,
    acts: [1],
    actVariant: false,
    isReplaceable: true,
    replacementTags: [],
    themes: ['survival'],
    entityTypes: ['enemy'],
    enemyTypeHooks: ['bushrangers'],
    environmentalContext: 'Dense scrubland',
    estimatedCombatDifficulty: 3,
    ...overrides,
  };
}

export function createChoiceNode(overrides: Record<string, unknown> = {}) {
  const ts = Date.now();
  return {
    name: `Test Choice ${ts}`,
    type: 'choice' as const,
    biome: 'township' as const,
    acts: [1, 2],
    actVariant: false,
    isReplaceable: true,
    replacementTags: [],
    themes: ['morality'],
    entityTypes: ['npc'],
    consequenceHooks: ['reputation_change'],
    dilemmaType: 'moral' as const,
    ...overrides,
  };
}
