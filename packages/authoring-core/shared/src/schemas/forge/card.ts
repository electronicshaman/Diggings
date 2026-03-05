import { z } from "zod";
import {
  CardType,
  CardRarity,
  CardOwner,
  CardHandling,
  AccessibilityTier,
  CostType,
} from "../../types/forge.js";

export const CardCostSchema = z.object({
  type: z.custom<CostType>(),
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
  cardType: z.custom<CardType>(),
  costs: z.array(CardCostSchema).default([]),
  effects: z.array(EffectRefSchema).default([]),
  rarity: z.custom<CardRarity>(),
  cardOwner: z.custom<CardOwner>(),
  handling: z.custom<CardHandling>(),
  classAffinity: z.array(z.string()).default([]),
  accessibilityTier: z.custom<AccessibilityTier>(),

  flavorText: z.string().optional(),
  baseDurability: z.number().int().optional(),
  volatileBonus: z.boolean().optional(),
  luckModifier: z.number().optional(),
  enemyFaction: z.string().optional(),
});

export type Card = z.infer<typeof CardSchema>;
