import { z } from 'zod';

// Comparator schema
const ComparatorSchema = z.enum([
  '==',
  '!=',
  '>',
  '>=',
  '<',
  '<=',
  'in',
  'not_in',
  'contains',
  'not_contains',
]);

// Condition schemas
const FlagConditionSchema = z.object({
  kind: z.literal('flag'),
  key: z.string(),
  op: z.enum(['==', '!=']),
  value: z.boolean(),
});

const ResourceConditionSchema = z.object({
  kind: z.literal('resource'),
  key: z.string(),
  op: ComparatorSchema,
  value: z.union([z.number(), z.tuple([z.number(), z.number()])]),
});

const TagConditionSchema = z.object({
  kind: z.literal('tag'),
  scope: z.enum(['player', 'run', 'biome', 'world', 'deck', 'node_context']),
  op: z.enum(['contains', 'not_contains']),
  value: z.string(),
});

const BiomeConditionSchema = z.object({
  kind: z.literal('biome'),
  op: z.enum(['in', 'not_in', '==']),
  value: z.union([z.string(), z.array(z.string())]),
});

const ActConditionSchema = z.object({
  kind: z.literal('act'),
  op: z.enum(['in', 'not_in', '==', '>=', '<=']),
  value: z.union([z.number(), z.array(z.number())]),
});

const DifficultyConditionSchema = z.object({
  kind: z.literal('difficulty'),
  op: z.enum(['<=', '>=']),
  value: z.number(),
});

const CooldownConditionSchema = z.object({
  kind: z.literal('cooldown'),
  key: z.string(),
  op: z.enum(['>=', '<=']),
  value: z.number(),
});

const SeenConditionSchema = z.object({
  kind: z.literal('seen'),
  key: z.string(),
  op: z.enum(['==', '!=', '>=', '<=']),
  value: z.number(),
});

const BindingConditionSchema = z.object({
  kind: z.literal('bind_exists'),
  role: z.string(),
  requiredTags: z.array(z.string()).optional(),
  count: z
    .object({
      op: z.enum(['>=', '==', '<=']),
      value: z.number(),
    })
    .optional(),
});

const ConditionSchema = z.discriminatedUnion('kind', [
  FlagConditionSchema,
  ResourceConditionSchema,
  TagConditionSchema,
  BiomeConditionSchema,
  ActConditionSchema,
  DifficultyConditionSchema,
  CooldownConditionSchema,
  SeenConditionSchema,
  BindingConditionSchema,
]);

// BoolExpr schema (recursive)
type BoolExprSchema = z.ZodType<
  | { allOf: BoolExpr[] }
  | { anyOf: BoolExpr[] }
  | { noneOf: BoolExpr[] }
  | z.infer<typeof ConditionSchema>
>;

type BoolExpr =
  | { allOf: BoolExpr[] }
  | { anyOf: BoolExpr[] }
  | { noneOf: BoolExpr[] }
  | z.infer<typeof ConditionSchema>;

const BoolExprSchema: BoolExprSchema = z.lazy(() =>
  z.union([
    z.object({ allOf: z.array(BoolExprSchema) }),
    z.object({ anyOf: z.array(BoolExprSchema) }),
    z.object({ noneOf: z.array(BoolExprSchema) }),
    ConditionSchema,
  ])
);

// RepeatPolicy schema
const RepeatPolicySchema = z.union([
  z.object({ mode: z.literal('once') }),
  z.object({
    mode: z.literal('repeatable'),
    minStepsBetween: z.number().optional(),
    maxTimesPerRun: z.number().optional(),
  }),
]);

// QualityRule schema
const QualityRuleSchema = z.object({
  if: BoolExprSchema,
  add: z.number(),
  reason: z.string().optional(),
});

// Saliency schema
const SaliencySchema = z.object({
  qualityRules: z.array(QualityRuleSchema).optional(),
  cooldownBias: z
    .array(
      z.object({
        key: z.string(),
        minSteps: z.number().optional(),
        weight: z.number(),
      })
    )
    .optional(),
});

// BindingSpec schema
const BindingSpecSchema = z.object({
  role: z.string(),
  requiredTags: z.array(z.string()).optional(),
  optionalTags: z.array(z.string()).optional(),
  maxCandidates: z.number().optional(),
  prefer: z
    .array(
      z.object({
        tag: z.string(),
        weight: z.number(),
      })
    )
    .optional(),
});

// Eligibility schema
export const EligibilitySchema = z.object({
  when: BoolExprSchema,
  saliency: SaliencySchema.optional(),
  repeat: RepeatPolicySchema.optional(),
  bindings: z.array(BindingSpecSchema).optional(),
});

// Export individual schemas
export {
  ComparatorSchema,
  FlagConditionSchema,
  ResourceConditionSchema,
  TagConditionSchema,
  BiomeConditionSchema,
  ActConditionSchema,
  DifficultyConditionSchema,
  CooldownConditionSchema,
  SeenConditionSchema,
  BindingConditionSchema,
  ConditionSchema,
  BoolExprSchema,
  RepeatPolicySchema,
  QualityRuleSchema,
  SaliencySchema,
  BindingSpecSchema,
};
