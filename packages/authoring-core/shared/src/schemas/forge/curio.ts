import { z } from "zod";
import {
  CURIO_RARITIES,
  CURIO_MECHANICAL_CATEGORIES,
} from "../../constants/forge.js";

const CurioRaritySchema = z.enum(CURIO_RARITIES);
const CurioMechanicalCategorySchema = z.enum(CURIO_MECHANICAL_CATEGORIES);

export const CurioEffectRefSchema = z.object({
  effectId: z.string().min(1),
  triggerEvent: z.string().min(1),
  params: z.record(z.unknown()).default({}),
  onlyFirstPerCombat: z.boolean().optional(),
  onlyFirstPerTurn: z.boolean().optional(),
  chanceToTrigger: z.number().min(0).max(1).optional(),
});

export const CurioSchema = z.object({
  id: z.string().min(1),
  name: z.string().min(1),
  description: z.string().default(""),
  rarity: CurioRaritySchema,
  mechanicalCategory: CurioMechanicalCategorySchema,
  effects: z.array(CurioEffectRefSchema).default([]),
  stackable: z.boolean().default(false),
  maxStacks: z.number().int().min(1).default(1),

  flavorText: z.string().optional(),
  corruptionCost: z.number().int().optional(),
  goldCost: z.number().int().optional(),
  unlockRequirement: z.string().optional(),
  synergy: z
    .object({
      bushranger: z.number().optional(),
      prospector: z.number().optional(),
      tracker: z.number().optional(),
      publican: z.number().optional(),
    })
    .optional(),
});

export type Curio = z.infer<typeof CurioSchema>;
