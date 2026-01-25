import { pgTable, text, varchar, integer, boolean, jsonb, timestamp, pgEnum, index } from 'drizzle-orm/pg-core';

// Enums
export const nodeTypeEnum = pgEnum('node_type', [
  'combat',
  'choice',
  'state_check',
  'trade',
  'passage',
  'rest',
  'transition',
]);

export const biomeEnum = pgEnum('biome', [
  'township',
  'the_diggings',
  'the_bush',
  'the_mines',
  'the_waste',
  'the_scar',
  'sacred_site',
  'the_river',
]);

export const dilemmaTypeEnum = pgEnum('dilemma_type', ['moral', 'practical', 'survival']);
export const restTypeEnum = pgEnum('rest_type', ['safe', 'risky', 'sacred']);
export const interruptionChanceEnum = pgEnum('interruption_chance', ['none', 'low', 'medium', 'high']);
export const llmProviderTypeEnum = pgEnum('llm_provider_type', ['openai', 'openrouter', 'anthropic']);
export const beatRoleEnum = pgEnum('beat_role', [
  'setup',
  'escalation',
  'reveal',
  'choice',
  'consequence',
  'button',
  'tension',
  'relief',
  'foreshadow',
  'reflection',
]);

export const jobStatusEnum = pgEnum('job_status', ['pending', 'running', 'completed', 'failed']);

// Main nodes table (single table with nullable fields)
export const nodes = pgTable(
  'nodes',
  {
    // Primary key
    id: integer('id').primaryKey().generatedAlwaysAsIdentity(),

    // Common fields (all nodes)
    nodeId: varchar('node_id', { length: 50 }).notNull().unique(),
    type: nodeTypeEnum('type').notNull(),
    biome: biomeEnum('biome').notNull(),
    name: varchar('name', { length: 255 }).notNull(),
    acts: jsonb('acts').notNull(), // Array of Act numbers (1-4)
    actVariant: boolean('act_variant').default(false),
    isReplaceable: boolean('is_replaceable').notNull(),
    replacementTags: jsonb('replacement_tags').notNull(), // Array of strings
    themes: jsonb('themes').notNull(), // Array of strings
    entityTypes: jsonb('entity_types').notNull(), // Array of strings
    estimatedCombatDifficulty: integer('estimated_combat_difficulty'), // 1-5, nullable

    // Complex data (JSONB)
    eligibility: jsonb('eligibility'), // Eligibility object
    resourceCost: jsonb('resource_cost'), // ResourceCheck object
    potentialRewards: jsonb('potential_rewards'), // Array of strings
    content: jsonb('content'), // NodeContent object (for non-variant nodes)
    actVariants: jsonb('act_variants'), // ActVariantContent object (for variant nodes)

    // Combat-specific fields (nullable)
    enemyTypeHooks: jsonb('enemy_type_hooks'), // Array of strings
    environmentalContext: varchar('environmental_context', { length: 255 }),

    // Choice-specific fields (nullable)
    consequenceHooks: jsonb('consequence_hooks'), // Array of strings
    dilemmaType: dilemmaTypeEnum('dilemma_type'),

    // Trade-specific fields (nullable)
    traderArchetype: varchar('trader_archetype', { length: 100 }),
    pricingHooks: jsonb('pricing_hooks'), // Array of strings

    // Rest-specific fields (nullable)
    restType: restTypeEnum('rest_type'),
    interruptionChance: interruptionChanceEnum('interruption_chance'),
    dreamHooks: jsonb('dream_hooks'), // Array of strings

    // Passage-specific fields (nullable)
    travelEventHooks: jsonb('travel_event_hooks'), // Array of strings
    environmentalStorytelling: text('environmental_storytelling'),

    // StateCheck-specific fields (nullable)
    conditionHooks: jsonb('condition_hooks'), // Array of strings
    branchTargets: jsonb('branch_targets'), // Object with success/failure strings

    // Transition-specific fields (nullable)
    actChangeTrigger: integer('act_change_trigger'), // Act number 1-4
    narrativeSummary: text('narrative_summary'),
    worldStateShifts: jsonb('world_state_shifts'), // Array of strings

    // AI generation metadata
    criticScore: integer('critic_score'), // 0-100, for AI-generated content
    generatedBy: varchar('generated_by', { length: 50 }), // LLM provider name

    // Metadata
    createdAt: timestamp('created_at').defaultNow().notNull(),
    updatedAt: timestamp('updated_at').defaultNow().notNull(),
  },
  (table) => {
    return {
      typeIdx: index('type_idx').on(table.type),
      biomeIdx: index('biome_idx').on(table.biome),
      nodeIdIdx: index('node_id_idx').on(table.nodeId),
    };
  }
);

// Biomes configuration table
export const biomes = pgTable('biomes', {
  id: integer('id').primaryKey().generatedAlwaysAsIdentity(),
  key: biomeEnum('key').notNull().unique(),
  displayName: varchar('display_name', { length: 100 }).notNull(),
  themes: jsonb('themes').notNull(), // Array of strings
  entityTypes: jsonb('entity_types').notNull(), // Array of strings
  actPresence: jsonb('act_presence').notNull(), // Object mapping Act -> ActPresence (0-4)
  atmosphere: text('atmosphere'), // Atmospheric description for generation
  voiceNotes: text('voice_notes'), // Narrative voice guidance
  updatedAt: timestamp('updated_at').defaultNow(),
});

// Distribution configuration table
export const distributions = pgTable('distributions', {
  id: integer('id').primaryKey().generatedAlwaysAsIdentity(),
  biome: biomeEnum('biome').notNull(),
  nodeType: nodeTypeEnum('node_type').notNull(),
  count: integer('count').notNull(),
});

// Lookup data tables
export const enemyTypes = pgTable('enemy_types', {
  id: integer('id').primaryKey().generatedAlwaysAsIdentity(),
  biome: biomeEnum('biome').notNull(),
  hook: varchar('hook', { length: 100 }).notNull(),
});

export const environmentalContexts = pgTable('environmental_contexts', {
  id: integer('id').primaryKey().generatedAlwaysAsIdentity(),
  biome: biomeEnum('biome').notNull(),
  context: varchar('context', { length: 100 }).notNull(),
});

export const consequenceHooks = pgTable('consequence_hooks', {
  id: integer('id').primaryKey().generatedAlwaysAsIdentity(),
  biome: biomeEnum('biome').notNull(),
  hook: varchar('hook', { length: 100 }).notNull(),
});

export const dreamHooksTable = pgTable('dream_hooks', {
  id: integer('id').primaryKey().generatedAlwaysAsIdentity(),
  biome: biomeEnum('biome').notNull(),
  hook: varchar('hook', { length: 100 }).notNull(),
});

export const travelEventHooks = pgTable('travel_event_hooks', {
  id: integer('id').primaryKey().generatedAlwaysAsIdentity(),
  biome: biomeEnum('biome').notNull(),
  hook: varchar('hook', { length: 100 }).notNull(),
});

export const environmentalStorytellingTable = pgTable('environmental_storytelling', {
  id: integer('id').primaryKey().generatedAlwaysAsIdentity(),
  biome: biomeEnum('biome').notNull(),
  storytelling: varchar('storytelling', { length: 100 }).notNull(),
});

export const conditionHooksTable = pgTable('condition_hooks', {
  id: integer('id').primaryKey().generatedAlwaysAsIdentity(),
  biome: biomeEnum('biome').notNull(),
  hook: varchar('hook', { length: 100 }).notNull(),
});

export const traderArchetypes = pgTable('trader_archetypes', {
  id: integer('id').primaryKey().generatedAlwaysAsIdentity(),
  biome: biomeEnum('biome').notNull(),
  archetype: varchar('archetype', { length: 100 }).notNull(),
});

export const pricingHooksTable = pgTable('pricing_hooks', {
  id: integer('id').primaryKey().generatedAlwaysAsIdentity(),
  archetypeKey: varchar('archetype_key', { length: 100 }).notNull(),
  hook: varchar('hook', { length: 100 }).notNull(),
});

// LLM Provider configuration
export const llmProviders = pgTable('llm_providers', {
  id: integer('id').primaryKey().generatedAlwaysAsIdentity(),
  name: varchar('name', { length: 100 }).notNull(),
  type: llmProviderTypeEnum('type').notNull(),
  baseUrl: varchar('base_url', { length: 255 }),
  encryptedApiKey: text('encrypted_api_key'), // Encrypted API key
  model: varchar('model', { length: 100 }).notNull(),
  temperature: integer('temperature').default(70), // 0-100 (maps to 0.0-1.0)
  maxRetries: integer('max_retries').default(3),
  isActive: boolean('is_active').default(false),
  createdAt: timestamp('created_at').defaultNow().notNull(),
  updatedAt: timestamp('updated_at').defaultNow().notNull(),
});

// Generation settings
export const generationSettings = pgTable('generation_settings', {
  id: integer('id').primaryKey().generatedAlwaysAsIdentity(),
  batchSize: integer('batch_size').default(5),
  criticThreshold: integer('critic_threshold').default(70), // 0-100
  enableCriticStage: boolean('enable_critic_stage').default(true),
  defaultTemperature: integer('default_temperature').default(70), // 0-100
  maxRetries: integer('max_retries').default(3),
  updatedAt: timestamp('updated_at').defaultNow().notNull(),
});

// Beat roles (editable beat types)
export const beatRoles = pgTable('beat_roles', {
  id: integer('id').primaryKey().generatedAlwaysAsIdentity(),
  key: varchar('key', { length: 50 }).notNull().unique(),
  displayName: varchar('display_name', { length: 100 }).notNull(),
  description: text('description'),
  isCore: boolean('is_core').default(false), // Core beats always available
  sortOrder: integer('sort_order').default(0),
  createdAt: timestamp('created_at').defaultNow().notNull(),
});

// Beat sequences (templates for node generation)
export const beatSequences = pgTable('beat_sequences', {
  id: integer('id').primaryKey().generatedAlwaysAsIdentity(),
  nodeType: nodeTypeEnum('node_type').notNull(),
  sequenceKey: varchar('sequence_key', { length: 100 }).notNull(),
  beatStructure: jsonb('beat_structure').notNull(), // Array of beat role keys
  weight: integer('weight').default(1), // For probabilistic selection
  actConstraints: jsonb('act_constraints'), // Which acts this sequence applies to
  requiredTags: jsonb('required_tags'), // Tags that must be present
  createdAt: timestamp('created_at').defaultNow().notNull(),
  updatedAt: timestamp('updated_at').defaultNow().notNull(),
});

// Style guide (per-biome generation guidance)
export const styleGuide = pgTable('style_guide', {
  id: integer('id').primaryKey().generatedAlwaysAsIdentity(),
  biome: biomeEnum('biome').notNull().unique(),
  atmosphere: text('atmosphere'),
  sensoryDetails: jsonb('sensory_details'), // Array of sensory descriptors
  dangers: jsonb('dangers'), // Array of danger types
  voiceNotes: text('voice_notes'),
  antipatterns: jsonb('antipatterns'), // Phrases/patterns to avoid
  createdAt: timestamp('created_at').defaultNow().notNull(),
  updatedAt: timestamp('updated_at').defaultNow().notNull(),
});

// Vernacular (historical term glossary)
export const vernacular = pgTable('vernacular', {
  id: integer('id').primaryKey().generatedAlwaysAsIdentity(),
  term: varchar('term', { length: 100 }).notNull(),
  definition: text('definition').notNull(),
  era: varchar('era', { length: 50 }), // e.g., "1850s", "Gold Rush"
  usageNotes: text('usage_notes'),
  sortOrder: integer('sort_order').default(0),
  createdAt: timestamp('created_at').defaultNow().notNull(),
});

// Act tones (act-specific narrative guidance)
export const actTones = pgTable('act_tones', {
  id: integer('id').primaryKey().generatedAlwaysAsIdentity(),
  act: integer('act').notNull(), // 1-4
  toneName: varchar('tone_name', { length: 100 }).notNull(),
  description: text('description'),
  sensoryPalette: jsonb('sensory_palette'), // Act-specific sensory elements
  createdAt: timestamp('created_at').defaultNow().notNull(),
  updatedAt: timestamp('updated_at').defaultNow().notNull(),
});

// Generation jobs (track job state for SSE reconnection)
export const generationJobs = pgTable(
  'generation_jobs',
  {
    id: integer('id').primaryKey().generatedAlwaysAsIdentity(),
    jobId: varchar('job_id', { length: 50 }).notNull().unique(),
    status: jobStatusEnum('status').notNull().default('pending'),
    nodeType: nodeTypeEnum('node_type').notNull(),
    biome: biomeEnum('biome').notNull(),
    request: jsonb('request').notNull(), // Full GenerationRequest for resume
    progress: integer('progress').default(0), // 0-100 percentage
    currentStage: varchar('current_stage', { length: 50 }), // outlining, expanding, reviewing, completed, failed
    result: jsonb('result'), // Final GenerationProgress on completion
    error: text('error'), // Error message if failed
    createdAt: timestamp('created_at').defaultNow().notNull(),
    updatedAt: timestamp('updated_at').defaultNow().notNull(),
    expiresAt: timestamp('expires_at').notNull(), // createdAt + 24 hours for auto-cleanup
  },
  (table) => {
    return {
      jobIdIdx: index('job_id_idx').on(table.jobId),
      expiresAtIdx: index('expires_at_idx').on(table.expiresAt),
    };
  }
);

// Type exports for TypeScript
export type Node = typeof nodes.$inferSelect;
export type NewNode = typeof nodes.$inferInsert;
export type Biome = typeof biomes.$inferSelect;
export type NewBiome = typeof biomes.$inferInsert;
export type Distribution = typeof distributions.$inferSelect;
export type NewDistribution = typeof distributions.$inferInsert;
export type LLMProvider = typeof llmProviders.$inferSelect;
export type NewLLMProvider = typeof llmProviders.$inferInsert;
export type GenerationSettings = typeof generationSettings.$inferSelect;
export type NewGenerationSettings = typeof generationSettings.$inferInsert;
export type BeatRole = typeof beatRoles.$inferSelect;
export type NewBeatRole = typeof beatRoles.$inferInsert;
export type BeatSequence = typeof beatSequences.$inferSelect;
export type NewBeatSequence = typeof beatSequences.$inferInsert;
export type StyleGuide = typeof styleGuide.$inferSelect;
export type NewStyleGuide = typeof styleGuide.$inferInsert;
export type Vernacular = typeof vernacular.$inferSelect;
export type NewVernacular = typeof vernacular.$inferInsert;
export type ActTone = typeof actTones.$inferSelect;
export type NewActTone = typeof actTones.$inferInsert;
export type GenerationJob = typeof generationJobs.$inferSelect;
export type NewGenerationJob = typeof generationJobs.$inferInsert;
