import { z } from 'zod';

/**
 * LLM provider type
 */
export const LLMProviderTypeSchema = z.enum(['openai', 'openrouter', 'anthropic', 'ollama']);

export type LLMProviderType = z.infer<typeof LLMProviderTypeSchema>;

/**
 * LLM provider configuration (without encrypted API key)
 */
export const LLMProviderSchema = z.object({
  id: z.number().int(),
  name: z.string().min(1).max(100),
  type: LLMProviderTypeSchema,
  baseUrl: z.string().url().nullable(),
  model: z.string().min(1).max(100),
  temperature: z.number().int().min(0).max(100).default(70), // 0-100 (maps to 0.0-1.0)
  maxRetries: z.number().int().min(0).max(10).default(3),
  isActive: z.boolean().default(false),
  createdAt: z.date(),
  updatedAt: z.date(),
});

export type LLMProvider = z.infer<typeof LLMProviderSchema>;

/**
 * LLM provider configuration for creation/update (with API key)
 */
export const LLMProviderConfigSchema = z
  .object({
    name: z.string().min(1).max(100),
    type: LLMProviderTypeSchema,
    baseUrl: z.string().url().nullable().optional(),
    apiKey: z.string().min(1).optional(), // Optional for Ollama
    model: z.string().min(1).max(100),
    temperature: z.number().int().min(0).max(100).default(70),
    maxRetries: z.number().int().min(0).max(10).default(3),
    isActive: z.boolean().default(false),
  })
  .superRefine((data, ctx) => {
    if (data.type !== 'ollama' && !data.apiKey) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        message: 'API key is required for this provider type',
        path: ['apiKey'],
      });
    }
    if (data.type === 'ollama' && !data.baseUrl) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        message: 'Base URL is required for Ollama',
        path: ['baseUrl'],
      });
    }
  });

export type LLMProviderConfig = z.infer<typeof LLMProviderConfigSchema>;

/**
 * LLM provider update (API key optional)
 */
export const LLMProviderUpdateSchema = z.object({
  name: z.string().min(1).max(100).optional(),
  baseUrl: z.string().url().nullable().optional(),
  apiKey: z.string().min(1).optional(), // If provided, will be encrypted
  model: z.string().min(1).max(100).optional(),
  temperature: z.number().int().min(0).max(100).optional(),
  maxRetries: z.number().int().min(0).max(10).optional(),
  isActive: z.boolean().optional(),
});

export type LLMProviderUpdate = z.infer<typeof LLMProviderUpdateSchema>;

/**
 * LLM provider test request
 */
export const LLMProviderTestSchema = z.object({
  providerId: z.number().int().optional(), // If testing existing provider
  providerConfig: LLMProviderConfigSchema.optional(), // If testing before saving (apiKey optional for Ollama)
});

export type LLMProviderTest = z.infer<typeof LLMProviderTestSchema>;

/**
 * LLM provider test result
 */
export const LLMProviderTestResultSchema = z.object({
  success: z.boolean(),
  message: z.string(),
  latency: z.number().optional(), // Response time in ms
  model: z.string().optional(),
  error: z.string().optional(),
});

export type LLMProviderTestResult = z.infer<typeof LLMProviderTestResultSchema>;

/**
 * Generation settings
 */
export const GenerationSettingsSchema = z.object({
  id: z.number().int(),
  batchSize: z.number().int().min(1).max(20).default(5),
  criticThreshold: z.number().int().min(0).max(100).default(70),
  enableCriticStage: z.boolean().default(true),
  defaultTemperature: z.number().int().min(0).max(100).default(70),
  maxRetries: z.number().int().min(0).max(10).default(3),
  updatedAt: z.date(),
});

export type GenerationSettings = z.infer<typeof GenerationSettingsSchema>;

/**
 * Generation settings update
 */
export const GenerationSettingsUpdateSchema = z.object({
  batchSize: z.number().int().min(1).max(20).optional(),
  criticThreshold: z.number().int().min(0).max(100).optional(),
  enableCriticStage: z.boolean().optional(),
  defaultTemperature: z.number().int().min(0).max(100).optional(),
  maxRetries: z.number().int().min(0).max(10).optional(),
});

export type GenerationSettingsUpdate = z.infer<typeof GenerationSettingsUpdateSchema>;
