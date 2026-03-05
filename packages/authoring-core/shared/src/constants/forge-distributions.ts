import type { CardType, CardRarity, CurioRarity } from "../types/forge.js";

export type CardDistribution = Record<CardType, Record<CardRarity, number>>;

export const CARD_DISTRIBUTION: CardDistribution = {
  Attack: { Common: 40, Uncommon: 25, Rare: 12, Eldritch: 6 },
  Skill: { Common: 30, Uncommon: 20, Rare: 10, Eldritch: 5 },
  Power: { Common: 15, Uncommon: 10, Rare: 6, Eldritch: 4 },
  Fortune: { Common: 10, Uncommon: 8, Rare: 4, Eldritch: 3 },
  Hex: { Common: 8, Uncommon: 6, Rare: 4, Eldritch: 3 },
  Curse: { Common: 10, Uncommon: 6, Rare: 4, Eldritch: 3 },
};

export const CURIO_DISTRIBUTION: Record<CurioRarity, number> = {
  Common: 20,
  Rare: 12,
  Legendary: 6,
  Corrupted: 6,
};
