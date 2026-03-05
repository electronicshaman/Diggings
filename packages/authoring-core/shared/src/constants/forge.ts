import type {
  CardType,
  CardRarity,
  CardOwner,
  CardHandling,
  AccessibilityTier,
  CurioRarity,
  CurioMechanicalCategory,
} from "../types/forge.js";

export const CARD_TYPES: CardType[] = [
  "Attack",
  "Skill",
  "Power",
  "Fortune",
  "Hex",
  "Curse",
];

export const CARD_RARITIES: CardRarity[] = [
  "Common",
  "Uncommon",
  "Rare",
  "Eldritch",
];

export const CARD_OWNERS: CardOwner[] = ["PLAYER", "ENEMY", "NEUTRAL"];

export const CARD_HANDLING: CardHandling[] = [
  "Standard",
  "Equipped",
  "Flash",
  "Keep",
  "Hold",
  "Oneshot",
];

export const ACCESSIBILITY_TIERS: AccessibilityTier[] = [
  "Starting",
  "Class",
  "Neutral",
  "Rare",
];

export const CURIO_RARITIES: CurioRarity[] = [
  "Common",
  "Rare",
  "Legendary",
  "Corrupted",
];

export const CURIO_MECHANICAL_CATEGORIES: CurioMechanicalCategory[] = [
  "Passive",
  "Triggered",
  "Modifier",
  "Resource",
];
