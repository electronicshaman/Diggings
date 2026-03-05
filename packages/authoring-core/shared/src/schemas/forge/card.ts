import { z } from "zod";
import {
  CARD_TYPES,
  CARD_RARITIES,
  CARD_OWNERS,
  CARD_HANDLING,
  ACCESSIBILITY_TIERS,
} from "../../constants/forge.js";
import { CostType } from "../../types/forge.js";

const CardTypeSchema = z.enum(CARD_TYPES);
const CardRaritySchema = z.enum(CARD_RARITIES);
const CardOwnerSchema = z.enum(CARD_OWNERS);
const CardHandlingSchema = z.enum(CARD_HANDLING);
const AccessibilityTierSchema = z.enum(ACCESSIBILITY_TIERS);

export const CardCostSchema = z.object({
  type: z.enum(["energy", "sanity", "resource"]) as z.ZodType<CostType>,
  amount: z.number().int().min(0),
  resourceKey: z.string().optional(),
});

export const EffectRefSchema = z.object({
  handlerId: z.string().min(1),
  params: z.record(z.unknown()).default({}),
});

export const CardSchema = z.object({
  id: z.string().min(1),
  name: z.string().min(1),
  description: z.string().default(""),
  cardType: CardTypeSchema,
  costs: z.array(CardCostSchema).default([]),
  effects: z.array(EffectRefSchema).default([]),
  rarity: CardRaritySchema,
  cardOwner: CardOwnerSchema,
  handling: CardHandlingSchema,
  classAffinity: z.array(z.string()).default([]),
  accessibilityTier: AccessibilityTierSchema,

  flavorText: z.string().optional(),
  baseDurability: z.number().int().optional(),
  volatileBonus: z.boolean().optional(),
  luckModifier: z.number().optional(),
  enemyFaction: z.string().optional(),
});

export type Card = z.infer<typeof CardSchema>;
