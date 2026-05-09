import type { CardType } from '../types/forge.js';

export interface CardHandlerParam {
  type: 'number' | 'string' | 'boolean';
  description: string;
  required: boolean;
  example: unknown;
}

export interface CardHandlerDef {
  handlerId: string;
  displayName: string;
  description: string;
  applicableTo: CardType[];
  params: Record<string, CardHandlerParam>;
}

export const CARD_HANDLER_REGISTRY: CardHandlerDef[] = [
  {
    handlerId: 'damage',
    displayName: 'Damage',
    description: 'Deal damage to an enemy target',
    applicableTo: ['Attack', 'Hex', 'Curse'],
    params: {
      amount: { type: 'number', description: 'Base damage amount', required: true, example: 6 },
      ignores_defense: { type: 'boolean', description: 'Whether damage ignores defense', required: false, example: false },
      multi_hit: { type: 'boolean', description: 'Whether to hit multiple times', required: false, example: false },
      hits: { type: 'number', description: 'Number of hits (when multi_hit is true)', required: false, example: 3 },
      random_range: { type: 'boolean', description: 'Whether damage is randomized', required: false, example: false },
      min_amount: { type: 'number', description: 'Minimum damage (when random_range is true)', required: false, example: 4 },
      max_amount: { type: 'number', description: 'Maximum damage (when random_range is true)', required: false, example: 8 },
    },
  },
  {
    handlerId: 'health',
    displayName: 'Health Restore',
    description: 'Restore health to self',
    applicableTo: ['Skill', 'Fortune'],
    params: {
      amount: { type: 'number', description: 'Amount of health to restore', required: false, example: 8 },
      percentage_based: { type: 'boolean', description: 'Whether amount is a percentage of max health', required: false, example: false },
      percentage: { type: 'number', description: 'Percentage of max health to restore (0-100)', required: false, example: 25 },
      full_heal: { type: 'boolean', description: 'Fully restore all health', required: false, example: false },
    },
  },
  {
    handlerId: 'defense',
    displayName: 'Defense',
    description: 'Grant defense (block) to self',
    applicableTo: ['Skill', 'Power'],
    params: {
      amount: { type: 'number', description: 'Amount of defense to grant', required: true, example: 5 },
      duration: { type: 'number', description: 'Duration in turns (0 = until next turn)', required: false, example: 0 },
    },
  },
  {
    handlerId: 'sanity',
    displayName: 'Sanity Restore',
    description: 'Restore sanity to self',
    applicableTo: ['Skill', 'Fortune'],
    params: {
      amount: { type: 'number', description: 'Amount of sanity to restore', required: false, example: 5 },
      percentage_based: { type: 'boolean', description: 'Whether amount is a percentage', required: false, example: false },
      full_restore: { type: 'boolean', description: 'Fully restore all sanity', required: false, example: false },
    },
  },
  {
    handlerId: 'sanity_damage',
    displayName: 'Sanity Damage',
    description: 'Deal sanity damage to target',
    applicableTo: ['Hex', 'Curse'],
    params: {
      amount: { type: 'number', description: 'Amount of sanity damage', required: true, example: 4 },
      percentage_based: { type: 'boolean', description: 'Whether amount is a percentage', required: false, example: false },
    },
  },
  {
    handlerId: 'resource',
    displayName: 'Resource',
    description: 'Modify a resource (gold, energy, or a class-specific resource)',
    applicableTo: ['Fortune', 'Skill', 'Power'],
    params: {
      resource_type: {
        type: 'string',
        description: 'Resource to modify: gold, energy, sanity, faith (Preacher), ammo (Bushranger), fever (Prospector), scent (Tracker), brew (Publican)',
        required: true,
        example: 'gold',
      },
      amount: { type: 'number', description: 'Amount to add (negative to subtract)', required: true, example: 2 },
      can_go_negative: { type: 'boolean', description: 'Whether resource can go below zero', required: false, example: false },
      random_range: { type: 'boolean', description: 'Whether amount is randomized', required: false, example: false },
      min_amount: { type: 'number', description: 'Minimum amount (when random_range is true)', required: false, example: 1 },
      max_amount: { type: 'number', description: 'Maximum amount (when random_range is true)', required: false, example: 3 },
    },
  },
  {
    handlerId: 'stat',
    displayName: 'Stat Modifier',
    description: 'Modify a character stat permanently or temporarily',
    applicableTo: ['Power', 'Skill'],
    params: {
      stat_name: { type: 'string', description: 'Stat to modify (e.g. strength, dexterity, max_health)', required: true, example: 'strength' },
      modifier_value: { type: 'number', description: 'Value of the modifier', required: true, example: 2 },
      modifier_type: { type: 'string', description: 'flat or percent', required: true, example: 'flat' },
      duration: { type: 'number', description: 'Duration in combat turns (0 = permanent)', required: false, example: 3 },
    },
  },
  {
    handlerId: 'card',
    displayName: 'Card Manipulation',
    description: 'Manipulate cards in hand, deck, or discard pile',
    applicableTo: ['Skill', 'Fortune'],
    params: {
      action: { type: 'string', description: 'draw, discard, shuffle, or exhaust', required: true, example: 'draw' },
      amount: { type: 'number', description: 'Number of cards to affect', required: true, example: 2 },
      card_filter: { type: 'string', description: 'Optional filter (e.g. attack, skill, random)', required: false, example: 'attack' },
    },
  },
  {
    handlerId: 'karma',
    displayName: 'Karma',
    description: 'Modify karma standing with wildlife or people',
    applicableTo: ['Fortune', 'Skill'],
    params: {
      karma_category: { type: 'string', description: 'wildlife or people', required: true, example: 'people' },
      amount: { type: 'number', description: 'Karma change (positive or negative)', required: true, example: 1 },
      reason: { type: 'string', description: 'Narrative reason for karma change', required: false, example: 'helped a stranger' },
    },
  },
  {
    handlerId: 'status',
    displayName: 'Status Effect',
    description: 'Apply a status effect to self or enemy',
    applicableTo: ['Attack', 'Skill', 'Hex', 'Curse'],
    params: {
      status_effect_id: {
        type: 'string',
        description: 'Status effect ID: disarmed, weak, wounded, rattled, grit, guard, surge (also legacy: stun, weaken, vulnerable, frail, strength, dexterity, vigor)',
        required: true,
        example: 'weak',
      },
      stacks: { type: 'number', description: 'Number of stacks to apply', required: false, example: 1 },
      apply_to: { type: 'string', description: 'enemy or self', required: true, example: 'enemy' },
    },
  },
];
