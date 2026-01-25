import { z } from 'zod';

/**
 * Beat outline structure (Stage 1 output)
 */
export const BeatOutlineSchema = z.object({
  narrative_hook: z.string().min(1).max(500),
  beats: z.array(
    z.object({
      id: z.string(),
      role: z.string(), // Will be validated against beat_roles table
      intent: z.string(),
    })
  ),
  mood: z.object({
    tension: z.number().int().min(1).max(5),
    atmosphere: z.string(),
    sensoryDetails: z.array(z.string()),
  }),
});

export type BeatOutline = z.infer<typeof BeatOutlineSchema>;

/**
 * Expanded content (Stage 2 output)
 */
export const ExpandedContentSchema = z.object({
  narrative_hook: z.string().min(1).max(500),
  beats: z.array(
    z.object({
      id: z.string(),
      role: z.string(),
      text: z.string().min(10).max(500),
    })
  ),
  outcomes: z
    .object({
      victory: z
        .object({
          text: z.string(),
          buttonText: z.string(),
        })
        .optional(),
      defeat: z
        .object({
          text: z.string(),
          buttonText: z.string(),
        })
        .optional(),
      neutral: z
        .object({
          text: z.string(),
          buttonText: z.string(),
        })
        .optional(),
    })
    .optional(),
  options: z
    .array(
      z.object({
        id: z.string(),
        label: z.string(),
        description: z.string(),
      })
    )
    .optional(),
});

export type ExpandedContent = z.infer<typeof ExpandedContentSchema>;

/**
 * Critic evaluation result (Stage 3 output)
 */
export const CriticResultSchema = z.object({
  pass: z.boolean(),
  score: z.number().int().min(0).max(100),
  issues: z.array(
    z.object({
      severity: z.enum(['critical', 'major', 'minor']),
      category: z.enum(['completeness', 'length', 'tone', 'authenticity', 'cliche', 'quality']),
      description: z.string(),
      beatId: z.string().nullable(),
      suggestion: z.string(),
    })
  ),
  strengths: z.array(z.string()),
  repairInstructions: z.string().nullable(),
});

export type CriticResult = z.infer<typeof CriticResultSchema>;

/**
 * Single node generation request
 */
export const GenerationRequestSchema = z.object({
  nodeId: z.string().optional(), // If editing existing node
  nodeType: z.enum(['combat', 'choice', 'trade', 'rest', 'passage', 'state_check', 'transition']),
  biome: z.enum([
    'township',
    'the_diggings',
    'the_bush',
    'the_mines',
    'the_waste',
    'the_scar',
    'sacred_site',
    'the_river',
  ]),
  name: z.string().min(1).max(255),
  themes: z.array(z.string()).min(1),
  entityTypes: z.array(z.string()).min(1),
  acts: z.array(z.number().int().min(1).max(4)).min(1),
  actVariant: z.boolean().default(false),
  estimatedCombatDifficulty: z.number().int().min(1).max(5).optional(),

  // Type-specific fields (will be validated based on nodeType)
  enemyTypeHooks: z.array(z.string()).optional(),
  environmentalContext: z.string().optional(),
  consequenceHooks: z.array(z.string()).optional(),
  dilemmaType: z.enum(['moral', 'practical', 'survival']).optional(),
  traderArchetype: z.string().optional(),
  pricingHooks: z.array(z.string()).optional(),
  restType: z.enum(['safe', 'risky', 'sacred']).optional(),
  interruptionChance: z.enum(['none', 'low', 'medium', 'high']).optional(),
  dreamHooks: z.array(z.string()).optional(),
  travelEventHooks: z.array(z.string()).optional(),
  environmentalStorytelling: z.string().optional(),
  conditionHooks: z.array(z.string()).optional(),
  actChangeTrigger: z.number().int().min(1).max(4).optional(),
  narrativeSummary: z.string().optional(),
  worldStateShifts: z.array(z.string()).optional(),
});

export type GenerationRequest = z.infer<typeof GenerationRequestSchema>;

/**
 * Bulk generation request
 */
export const BulkGenerationRequestSchema = z.object({
  biome: z.enum([
    'township',
    'the_diggings',
    'the_bush',
    'the_mines',
    'the_waste',
    'the_scar',
    'sacred_site',
    'the_river',
  ]).optional(), // If specified, only generate for this biome
  nodeType: z.enum(['combat', 'choice', 'trade', 'rest', 'passage', 'state_check', 'transition']).optional(), // If specified, only generate this type
  count: z.number().int().min(1).max(100).optional(), // If specified, generate this many nodes
  fillGaps: z.boolean().default(true), // If true, analyze distribution gaps and fill them
});

export type BulkGenerationRequest = z.infer<typeof BulkGenerationRequestSchema>;

/**
 * Generation progress event (for SSE streaming)
 */
export const ProgressEventSchema = z.object({
  stage: z.enum(['outlining', 'expanding', 'reviewing', 'completed', 'error']),
  progress: z.number().min(0).max(100), // 0-100%
  message: z.string().optional(),
  data: z.any().optional(), // Stage-specific data (outline, content, critique, etc.)
  error: z.string().optional(),
});

export type ProgressEvent = z.infer<typeof ProgressEventSchema>;

/**
 * Generation response (single node)
 */
export const GenerationResponseSchema = z.object({
  success: z.boolean(),
  nodeId: z.string().optional(),
  content: ExpandedContentSchema.optional(),
  criticScore: z.number().int().min(0).max(100).optional(),
  criticResult: CriticResultSchema.optional(),
  error: z.string().optional(),
});

export type GenerationResponse = z.infer<typeof GenerationResponseSchema>;

/**
 * Batch generation response
 */
export const BatchGenerationResponseSchema = z.object({
  jobId: z.string(),
  totalNodes: z.number().int(),
  status: z.enum(['pending', 'running', 'completed', 'failed']),
  progress: z.number().min(0).max(100),
  completedNodes: z.array(z.string()),
  failedNodes: z.array(z.string()),
  message: z.string().optional(),
});

export type BatchGenerationResponse = z.infer<typeof BatchGenerationResponseSchema>;
