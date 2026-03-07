import { Hono } from 'hono';
import { zValidator } from '@hono/zod-validator';
import { z } from 'zod';
import { db, nodes } from '../db/index.js';
import { eq, and, inArray, sql } from 'drizzle-orm';
import {
  AnyNodeMetadataSchema,
  CombatNodeSchema,
  ChoiceNodeSchema,
  TradeNodeSchema,
  RestNodeSchema,
  PassageNodeSchema,
  StateCheckNodeSchema,
  TransitionNodeSchema,
  BiomeSchema,
  NodeTypeSchema,
} from '@atlas/shared';

export const nodesRouter = new Hono();

const CombatNodeCreateSchema = CombatNodeSchema.extend({
  id: z.string().min(1).optional(),
});
const ChoiceNodeCreateSchema = ChoiceNodeSchema.extend({
  id: z.string().min(1).optional(),
});
const TradeNodeCreateSchema = TradeNodeSchema.extend({
  id: z.string().min(1).optional(),
});
const RestNodeCreateSchema = RestNodeSchema.extend({
  id: z.string().min(1).optional(),
});
const PassageNodeCreateSchema = PassageNodeSchema.extend({
  id: z.string().min(1).optional(),
});
const StateCheckNodeCreateSchema = StateCheckNodeSchema.extend({
  id: z.string().min(1).optional(),
});
const TransitionNodeCreateSchema = TransitionNodeSchema.extend({
  id: z.string().min(1).optional(),
});

const AnyNodeCreateSchema = z.discriminatedUnion('type', [
  CombatNodeCreateSchema,
  ChoiceNodeCreateSchema,
  TradeNodeCreateSchema,
  RestNodeCreateSchema,
  PassageNodeCreateSchema,
  StateCheckNodeCreateSchema,
  TransitionNodeCreateSchema,
]);

const generateNodeId = async (biome: string, type: string) => {
  const prefix = `${biome}`.toUpperCase() + '_' + `${type}`.toUpperCase();
  const existing = await db
    .select({ nodeId: nodes.nodeId })
    .from(nodes)
    .where(sql`${nodes.nodeId} ILIKE ${`${prefix}_%`}`);

  let maxSuffix = 0;
  for (const row of existing) {
    const parts = row.nodeId.split('_');
    const last = parts[parts.length - 1];
    const parsed = Number.parseInt(last, 10);
    if (!Number.isNaN(parsed)) {
      maxSuffix = Math.max(maxSuffix, parsed);
    }
  }

  const next = maxSuffix + 1;
  return `${prefix}_${String(next).padStart(3, '0')}`;
};

// Query params schema for listing nodes
const listQuerySchema = z.object({
  type: z.string().optional(),
  biome: z.string().optional(),
  acts: z.string().optional(), // Comma-separated acts
  limit: z.coerce.number().int().min(1).max(100).default(50),
  offset: z.coerce.number().int().min(0).default(0),
});

// GET /api/nodes - List nodes with filtering
nodesRouter.get('/', zValidator('query', listQuerySchema), async (c) => {
  const { type, biome, acts, limit, offset } = c.req.valid('query');

  let query = db.select().from(nodes);

  // Apply filters
  const conditions = [];
  if (type) {
    conditions.push(eq(nodes.type, type as any));
  }
  if (biome) {
    conditions.push(eq(nodes.biome, biome as any));
  }
  if (acts) {
    const actArray = acts.split(',').map(Number).filter((n) => n >= 1 && n <= 4);
    if (actArray.length === 0) {
      return c.json({ error: 'Invalid acts parameter: values must be between 1 and 4' }, 400);
    }
    // Filter by acts contained in the JSONB array
    conditions.push(sql`${nodes.acts} @> ${JSON.stringify(actArray)}::jsonb`);
  }

  if (conditions.length > 0) {
    query = query.where(and(...conditions)) as any;
  }

  const result = await query.limit(limit).offset(offset);

  return c.json({
    data: result,
    pagination: {
      limit,
      offset,
      total: result.length,
    },
  });
});

// GET /api/nodes/:nodeId - Get single node
nodesRouter.get('/:nodeId', async (c) => {
  const nodeId = c.req.param('nodeId');

  const result = await db.select().from(nodes).where(eq(nodes.nodeId, nodeId)).limit(1);

  if (result.length === 0) {
    return c.json({ error: 'Node not found' }, 404);
  }

  return c.json(result[0]);
});

// POST /api/nodes - Create node
nodesRouter.post('/', zValidator('json', AnyNodeCreateSchema), async (c) => {
  const data = c.req.valid('json');
  const nodeId = data.id || (await generateNodeId(data.biome, data.type));

  // Transform the data to match database schema
  const dbData: any = {
    nodeId,
    type: data.type,
    biome: data.biome,
    name: data.name,
    acts: data.acts,
    actVariant: data.actVariant || false,
    isReplaceable: data.isReplaceable,
    replacementTags: data.replacementTags,
    themes: data.themes,
    entityTypes: data.entityTypes,
    eligibility: data.eligibility,
    estimatedCombatDifficulty: data.estimatedCombatDifficulty,
    resourceCost: data.resourceCost,
    potentialRewards: data.potentialRewards,
    content: data.content,
    actVariants: data.actVariants,
  };

  // Add type-specific fields
  if (data.type === 'combat') {
    dbData.enemyTypeHooks = data.enemyTypeHooks;
    dbData.environmentalContext = data.environmentalContext;
  } else if (data.type === 'choice') {
    dbData.consequenceHooks = data.consequenceHooks;
    dbData.dilemmaType = data.dilemmaType;
  } else if (data.type === 'trade') {
    dbData.traderArchetype = data.traderArchetype;
    dbData.pricingHooks = data.pricingHooks;
  } else if (data.type === 'rest') {
    dbData.restType = data.restType;
    dbData.interruptionChance = data.interruptionChance;
    dbData.dreamHooks = data.dreamHooks;
  } else if (data.type === 'passage') {
    dbData.travelEventHooks = data.travelEventHooks;
    dbData.environmentalStorytelling = data.environmentalStorytelling;
  } else if (data.type === 'state_check') {
    dbData.conditionHooks = data.conditionHooks;
    dbData.branchTargets = data.branchTargets;
  } else if (data.type === 'transition') {
    dbData.actChangeTrigger = data.actChangeTrigger;
    dbData.narrativeSummary = data.narrativeSummary;
    dbData.worldStateShifts = data.worldStateShifts;
  }

  const result = await db.insert(nodes).values(dbData).returning();

  return c.json(result[0], 201);
});

// PUT /api/nodes/:nodeId - Update node (full replacement)
nodesRouter.put('/:nodeId', zValidator('json', AnyNodeMetadataSchema), async (c) => {
  const nodeId = c.req.param('nodeId');
  const data = c.req.valid('json');

  // Check if node exists
  const existing = await db.select().from(nodes).where(eq(nodes.nodeId, nodeId)).limit(1);
  if (existing.length === 0) {
    return c.json({ error: 'Node not found' }, 404);
  }

  // Transform the data to match database schema (same as POST)
  const dbData: any = {
    nodeId: data.id,
    type: data.type,
    biome: data.biome,
    name: data.name,
    acts: data.acts,
    actVariant: data.actVariant || false,
    isReplaceable: data.isReplaceable,
    replacementTags: data.replacementTags,
    themes: data.themes,
    entityTypes: data.entityTypes,
    eligibility: data.eligibility,
    estimatedCombatDifficulty: data.estimatedCombatDifficulty,
    resourceCost: data.resourceCost,
    potentialRewards: data.potentialRewards,
    content: data.content,
    actVariants: data.actVariants,
    updatedAt: new Date(),
  };

  // Add type-specific fields
  if (data.type === 'combat') {
    dbData.enemyTypeHooks = data.enemyTypeHooks;
    dbData.environmentalContext = data.environmentalContext;
  } else if (data.type === 'choice') {
    dbData.consequenceHooks = data.consequenceHooks;
    dbData.dilemmaType = data.dilemmaType;
  } else if (data.type === 'trade') {
    dbData.traderArchetype = data.traderArchetype;
    dbData.pricingHooks = data.pricingHooks;
  } else if (data.type === 'rest') {
    dbData.restType = data.restType;
    dbData.interruptionChance = data.interruptionChance;
    dbData.dreamHooks = data.dreamHooks;
  } else if (data.type === 'passage') {
    dbData.travelEventHooks = data.travelEventHooks;
    dbData.environmentalStorytelling = data.environmentalStorytelling;
  } else if (data.type === 'state_check') {
    dbData.conditionHooks = data.conditionHooks;
    dbData.branchTargets = data.branchTargets;
  } else if (data.type === 'transition') {
    dbData.actChangeTrigger = data.actChangeTrigger;
    dbData.narrativeSummary = data.narrativeSummary;
    dbData.worldStateShifts = data.worldStateShifts;
  }

  const result = await db.update(nodes).set(dbData).where(eq(nodes.nodeId, nodeId)).returning();

  return c.json(result[0]);
});

// Partial update schema - allows any valid node fields
const NodePatchSchema = z.object({
  name: z.string().min(1).max(255).optional(),
  biome: BiomeSchema.optional(),
  type: NodeTypeSchema.optional(),
  acts: z.array(z.number().int().min(1).max(4)).optional(),
  themes: z.array(z.string()).optional(),
  entityTypes: z.array(z.string()).optional(),
  content: z.record(z.any()).optional(),
  narrativeSummary: z.string().optional(),
  isReplaceable: z.boolean().optional(),
  replacementTags: z.array(z.string()).optional(),
  actVariant: z.boolean().optional(),
}).strict();

// PATCH /api/nodes/:nodeId - Partial update
nodesRouter.patch('/:nodeId', zValidator('json', NodePatchSchema), async (c) => {
  const nodeId = c.req.param('nodeId');
  const data = c.req.valid('json');

  // Check if node exists
  const existing = await db.select().from(nodes).where(eq(nodes.nodeId, nodeId)).limit(1);
  if (existing.length === 0) {
    return c.json({ error: 'Node not found' }, 404);
  }

  // Update with partial data
  const result = await db
    .update(nodes)
    .set({ ...data, updatedAt: new Date() })
    .where(eq(nodes.nodeId, nodeId))
    .returning();

  return c.json(result[0]);
});

// DELETE /api/nodes/:nodeId - Delete node
nodesRouter.delete('/:nodeId', async (c) => {
  const nodeId = c.req.param('nodeId');

  // Check if node exists
  const existing = await db.select().from(nodes).where(eq(nodes.nodeId, nodeId)).limit(1);
  if (existing.length === 0) {
    return c.json({ error: 'Node not found' }, 404);
  }

  await db.delete(nodes).where(eq(nodes.nodeId, nodeId));

  return c.json({ success: true });
});
