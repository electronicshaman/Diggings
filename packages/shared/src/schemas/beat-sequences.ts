import { z } from 'zod';

/**
 * Beat role (dynamic, loaded from database)
 */
export const BeatRoleRecordSchema = z.object({
  id: z.number().int(),
  key: z.string().min(1).max(50),
  displayName: z.string().min(1).max(100),
  description: z.string().nullable(),
  isCore: z.boolean().default(false),
  sortOrder: z.number().int().default(0),
  createdAt: z.date(),
});

export type BeatRoleRecord = z.infer<typeof BeatRoleRecordSchema>;

/**
 * Beat role creation
 */
export const BeatRoleCreateSchema = z.object({
  key: z.string().min(1).max(50),
  displayName: z.string().min(1).max(100),
  description: z.string().optional(),
  isCore: z.boolean().default(false),
  sortOrder: z.number().int().default(0),
});

export type BeatRoleCreate = z.infer<typeof BeatRoleCreateSchema>;

/**
 * Beat template (part of a sequence)
 */
export const BeatTemplateSchema = z.object({
  role: z.string(), // References beat_roles.key
  intent: z.string(),
  required: z.boolean().default(true),
});

export type BeatTemplate = z.infer<typeof BeatTemplateSchema>;

/**
 * Beat sequence (template for generation)
 */
export const BeatSequenceRecordSchema = z.object({
  id: z.number().int(),
  nodeType: z.enum(['combat', 'choice', 'trade', 'rest', 'passage', 'state_check', 'transition']),
  sequenceKey: z.string().min(1).max(100),
  beatStructure: z.array(BeatTemplateSchema), // JSONB
  weight: z.number().int().min(1).max(10).default(1),
  actConstraints: z
    .object({
      acts: z.array(z.number().int().min(1).max(4)),
    })
    .nullable(),
  requiredTags: z.array(z.string()), // JSONB
  createdAt: z.date(),
  updatedAt: z.date(),
});

export type BeatSequenceRecord = z.infer<typeof BeatSequenceRecordSchema>;

/**
 * Beat sequence creation
 */
export const BeatSequenceCreateSchema = z.object({
  nodeType: z.enum(['combat', 'choice', 'trade', 'rest', 'passage', 'state_check', 'transition']),
  sequenceKey: z.string().min(1).max(100),
  beatStructure: z.array(BeatTemplateSchema),
  weight: z.number().int().min(1).max(10).default(1),
  actConstraints: z
    .object({
      acts: z.array(z.number().int().min(1).max(4)),
    })
    .nullable()
    .optional(),
  requiredTags: z.array(z.string()).default([]),
});

export type BeatSequenceCreate = z.infer<typeof BeatSequenceCreateSchema>;

/**
 * Beat sequence update
 */
export const BeatSequenceUpdateSchema = z.object({
  sequenceKey: z.string().min(1).max(100).optional(),
  beatStructure: z.array(BeatTemplateSchema).optional(),
  weight: z.number().int().min(1).max(10).optional(),
  actConstraints: z
    .object({
      acts: z.array(z.number().int().min(1).max(4)),
    })
    .nullable()
    .optional(),
  requiredTags: z.array(z.string()).optional(),
});

export type BeatSequenceUpdate = z.infer<typeof BeatSequenceUpdateSchema>;
