export const CARD_TYPES = [
  "Attack",
  "Skill",
  "Power",
  "Fortune",
  "Hex",
  "Curse",
] as const;

export const CARD_RARITIES = [
  "Common",
  "Uncommon",
  "Rare",
  "Eldritch",
] as const;

export const CARD_OWNERS = ["PLAYER", "ENEMY", "NEUTRAL"] as const;

export const CARD_HANDLING = [
  "Standard",
  "Equipped",
  "Flash",
  "Keep",
  "Hold",
  "Oneshot",
] as const;

export const ACCESSIBILITY_TIERS = [
  "Starting",
  "Class",
  "Neutral",
  "Rare",
] as const;

export const CURIO_RARITIES = [
  "Common",
  "Rare",
  "Legendary",
  "Corrupted",
] as const;

export const CURIO_MECHANICAL_CATEGORIES = [
  "Passive",
  "Triggered",
  "Modifier",
  "Resource",
] as const;
