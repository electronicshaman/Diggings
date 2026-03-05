export type CardType = "Attack" | "Skill" | "Power" | "Fortune" | "Hex" | "Curse";
export type CardRarity = "Common" | "Uncommon" | "Rare" | "Eldritch";
export type CardOwner = "PLAYER" | "ENEMY" | "NEUTRAL";
export type CardHandling = "Standard" | "Equipped" | "Flash" | "Keep" | "Hold" | "Oneshot";
export type AccessibilityTier = "Starting" | "Class" | "Neutral" | "Rare";

export type CurioRarity = "Common" | "Rare" | "Legendary" | "Corrupted";
export type CurioMechanicalCategory = "Passive" | "Triggered" | "Modifier" | "Resource";

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
