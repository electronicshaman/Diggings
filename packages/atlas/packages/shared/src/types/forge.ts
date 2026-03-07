import {
  CARD_TYPES,
  CARD_RARITIES,
  CARD_OWNERS,
  CARD_HANDLING,
  ACCESSIBILITY_TIERS,
  CURIO_RARITIES,
  CURIO_MECHANICAL_CATEGORIES,
} from "../constants/forge.js";

export type CardType = (typeof CARD_TYPES)[number];
export type CardRarity = (typeof CARD_RARITIES)[number];
export type CardOwner = (typeof CARD_OWNERS)[number];
export type CardHandling = (typeof CARD_HANDLING)[number];
export type AccessibilityTier = (typeof ACCESSIBILITY_TIERS)[number];

export type CurioRarity = (typeof CURIO_RARITIES)[number];
export type CurioMechanicalCategory = (typeof CURIO_MECHANICAL_CATEGORIES)[number];

export type CostType = "energy" | "sanity" | "resource";

export interface CardCost {
  type: CostType;
  amount: number;
  resourceKey?: string;
}

export interface EffectRef {
  handlerId: string;
  params: Record<string, unknown>;
}

export interface CurioEffectRef {
  effectId: string;
  triggerEvent: string;
  params: Record<string, unknown>;
  onlyFirstPerCombat?: boolean;
  onlyFirstPerTurn?: boolean;
  chanceToTrigger?: number;
}
