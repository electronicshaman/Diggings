import { z } from 'zod';
import { EligibilitySchema } from './eligibility.js';

// Enum schemas
const ActSchema = z.union([z.literal(1), z.literal(2), z.literal(3), z.literal(4)]);

const BiomeSchema = z.enum([
  'township',
  'the_diggings',
  'the_bush',
  'the_mines',
  'the_waste',
  'the_scar',
  'sacred_site',
  'the_river',
]);

const NodeTypeSchema = z.enum([
  'combat',
  'choice',
  'state_check',
  'trade',
  'passage',
  'rest',
  'transition',
]);

// Content schemas
const BeatRoleSchema = z.enum([
  // Core roles (original 6):
  'setup',
  'escalation',
  'reveal',
  'choice',
  'consequence',
  'button',
  // Extended roles (new 4):
  'tension',
  'relief',
  'foreshadow',
  'reflection',
]);

const StoryBeatSchema = z.object({
  id: z.string().min(1),
  role: BeatRoleSchema,
  text: z.string().min(10).max(500), // 1-3 sentences
  playerPrompt: z.string().optional(),
  outcomeTags: z.array(z.string()).optional(),
});

const ChoiceOptionSchema = z.object({
  id: z.string().min(1),
  label: z.string().min(3).max(60), // 5-10 words
  description: z.string().min(10).max(200), // 1 sentence consequence hint
  consequenceTags: z.array(z.string()),
});

const OutcomeTextSchema = z.object({
  text: z.string().min(10).max(300), // 1-2 sentences
  buttonText: z.string().min(1).max(30),
});

const NodeOutcomesSchema = z.object({
  victory: OutcomeTextSchema.optional(),
  defeat: OutcomeTextSchema.optional(),
  neutral: OutcomeTextSchema.optional(),
});

const MoodDescriptorSchema = z.object({
  tension: z.union([z.literal(1), z.literal(2), z.literal(3), z.literal(4), z.literal(5)]),
  atmosphere: z.string().min(1),
  sensoryDetails: z.array(z.string()).min(2).max(5),
});

const NodeContentSchema = z.object({
  narrative_hook: z.string().min(20).max(500), // 1-3 sentences
  beats: z.array(StoryBeatSchema).min(1),
  options: z.array(ChoiceOptionSchema).optional(),
  outcomes: NodeOutcomesSchema.optional(),
  mood: MoodDescriptorSchema,
});

const ActVariantContentSchema = z.record(
  z.coerce.number().int().min(1).max(4),
  NodeContentSchema
);

const ResourceCheckSchema = z.object({
  type: z.string(),
  amount: z.number(),
  optional: z.boolean().optional(),
});

// Base node metadata schema
const BaseNodeMetadataSchema = z.object({
  id: z.string().min(1),
  type: NodeTypeSchema,
  biome: BiomeSchema,
  name: z.string().min(1),
  acts: z.array(ActSchema).min(1),
  actVariant: z.boolean().optional(),
  isReplaceable: z.boolean(),
  replacementTags: z.array(z.string()),
  themes: z.array(z.string()),
  entityTypes: z.array(z.string()),
  eligibility: EligibilitySchema.optional(),
  estimatedCombatDifficulty: z.union([z.literal(1), z.literal(2), z.literal(3), z.literal(4), z.literal(5)]).optional(),
  resourceCost: ResourceCheckSchema.optional(),
  potentialRewards: z.array(z.string()).optional(),
  // Content fields
  content: NodeContentSchema.optional(),
  actVariants: ActVariantContentSchema.optional(),
});

// Node type-specific schemas
export const CombatNodeSchema = BaseNodeMetadataSchema.extend({
  type: z.literal('combat'),
  enemyTypeHooks: z.array(z.string()).min(1),
  environmentalContext: z.string(),
  estimatedCombatDifficulty: z.union([z.literal(1), z.literal(2), z.literal(3), z.literal(4), z.literal(5)]),
});

export const ChoiceNodeSchema = BaseNodeMetadataSchema.extend({
  type: z.literal('choice'),
  consequenceHooks: z.array(z.string()).min(1),
  dilemmaType: z.enum(['moral', 'practical', 'survival']),
});

export const TradeNodeSchema = BaseNodeMetadataSchema.extend({
  type: z.literal('trade'),
  traderArchetype: z.string(),
  pricingHooks: z.array(z.string()),
});

export const RestNodeSchema = BaseNodeMetadataSchema.extend({
  type: z.literal('rest'),
  restType: z.enum(['safe', 'risky', 'sacred']),
  interruptionChance: z.enum(['none', 'low', 'medium', 'high']),
  dreamHooks: z.array(z.string()).optional(),
});

export const PassageNodeSchema = BaseNodeMetadataSchema.extend({
  type: z.literal('passage'),
  travelEventHooks: z.array(z.string()),
  environmentalStorytelling: z.string(),
  resourceCost: ResourceCheckSchema,
});

export const StateCheckNodeSchema = BaseNodeMetadataSchema.extend({
  type: z.literal('state_check'),
  conditionHooks: z.array(z.string()),
  branchTargets: z.object({
    success: z.string(),
    failure: z.string(),
  }),
});

export const TransitionNodeSchema = BaseNodeMetadataSchema.extend({
  type: z.literal('transition'),
  actChangeTrigger: ActSchema.optional(),
  narrativeSummary: z.string(),
  worldStateShifts: z.array(z.string()),
});

// Discriminated union of all node types
export const AnyNodeMetadataSchema: z.ZodDiscriminatedUnion<'type', z.ZodDiscriminatedUnionOption<'type'>[]> = z.discriminatedUnion('type', [
  CombatNodeSchema,
  ChoiceNodeSchema,
  TradeNodeSchema,
  RestNodeSchema,
  PassageNodeSchema,
  StateCheckNodeSchema,
  TransitionNodeSchema,
]);

// Export all content schemas
export {
  ActSchema,
  BiomeSchema,
  NodeTypeSchema,
  BeatRoleSchema,
  StoryBeatSchema,
  ChoiceOptionSchema,
  OutcomeTextSchema,
  NodeOutcomesSchema,
  MoodDescriptorSchema,
  NodeContentSchema,
  ActVariantContentSchema,
  ResourceCheckSchema,
  BaseNodeMetadataSchema,
};
