import type { CardType, CardRarity } from "../types/forge.js";

const CARD_TYPE_PREFIX: Record<CardType, string> = {
  Attack: "ATK",
  Skill: "SKL",
  Power: "POW",
  Fortune: "FOR",
  Hex: "HEX",
  Curse: "CUR",
};

const CURIO_RARITY_PREFIX: Record<CardRarity | "Legendary" | "Corrupted", string> = {
  Common: "COM",
  Uncommon: "UNC",
  Rare: "RAR",
  Eldritch: "ELD",
  Legendary: "LEG",
  Corrupted: "COR",
};

export function formatCardId(type: CardType, n: number) {
  return `CRD_${CARD_TYPE_PREFIX[type]}_${String(n).padStart(3, "0")}`;
}

export function formatCurioId(rarity: keyof typeof CURIO_RARITY_PREFIX, n: number) {
  return `CUR_${CURIO_RARITY_PREFIX[rarity]}_${String(n).padStart(3, "0")}`;
}
