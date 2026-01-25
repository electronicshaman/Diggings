import { z } from 'zod';

/**
 * Style guide (per-biome generation guidance)
 */
export const StyleGuideRecordSchema = z.object({
  id: z.number().int(),
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
  atmosphere: z.string().nullable(),
  sensoryDetails: z.array(z.string()), // JSONB
  dangers: z.array(z.string()), // JSONB
  voiceNotes: z.string().nullable(),
  antipatterns: z.array(z.string()), // JSONB
  createdAt: z.date(),
  updatedAt: z.date(),
});

export type StyleGuideRecord = z.infer<typeof StyleGuideRecordSchema>;

/**
 * Style guide update
 */
export const StyleGuideUpdateSchema = z.object({
  atmosphere: z.string().optional(),
  sensoryDetails: z.array(z.string()).optional(),
  dangers: z.array(z.string()).optional(),
  voiceNotes: z.string().optional(),
  antipatterns: z.array(z.string()).optional(),
});

export type StyleGuideUpdate = z.infer<typeof StyleGuideUpdateSchema>;

/**
 * Vernacular term
 */
export const VernacularRecordSchema = z.object({
  id: z.number().int(),
  term: z.string().min(1).max(100),
  definition: z.string().min(1),
  era: z.string().max(50).nullable(),
  usageNotes: z.string().nullable(),
  sortOrder: z.number().int().default(0),
  createdAt: z.date(),
});

export type VernacularRecord = z.infer<typeof VernacularRecordSchema>;

/**
 * Vernacular creation
 */
export const VernacularCreateSchema = z.object({
  term: z.string().min(1).max(100),
  definition: z.string().min(1),
  era: z.string().max(50).optional(),
  usageNotes: z.string().optional(),
  sortOrder: z.number().int().default(0),
});

export type VernacularCreate = z.infer<typeof VernacularCreateSchema>;

/**
 * Vernacular update
 */
export const VernacularUpdateSchema = z.object({
  term: z.string().min(1).max(100).optional(),
  definition: z.string().min(1).optional(),
  era: z.string().max(50).nullable().optional(),
  usageNotes: z.string().nullable().optional(),
  sortOrder: z.number().int().optional(),
});

export type VernacularUpdate = z.infer<typeof VernacularUpdateSchema>;

/**
 * Act tone (act-specific narrative guidance)
 */
export const ActToneRecordSchema = z.object({
  id: z.number().int(),
  act: z.number().int().min(1).max(4),
  toneName: z.string().min(1).max(100),
  description: z.string().nullable(),
  sensoryPalette: z.any(), // JSONB - flexible structure
  createdAt: z.date(),
  updatedAt: z.date(),
});

export type ActToneRecord = z.infer<typeof ActToneRecordSchema>;

/**
 * Act tone update
 */
export const ActToneUpdateSchema = z.object({
  toneName: z.string().min(1).max(100).optional(),
  description: z.string().optional(),
  sensoryPalette: z.any().optional(),
});

export type ActToneUpdate = z.infer<typeof ActToneUpdateSchema>;
