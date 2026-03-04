import { Hono } from 'hono';
import { z } from 'zod';
import { zValidator } from '@hono/zod-validator';
import { eq } from 'drizzle-orm';
import {
  db,
  biomes,
  distributions,
  enemyTypes,
  environmentalContexts,
  consequenceHooks,
  dreamHooksTable,
  travelEventHooks,
  environmentalStorytellingTable,
  conditionHooksTable,
  traderArchetypes,
  pricingHooksTable,
} from '../db/index.js';

export const configRouter = new Hono();

// GET /api/config/biomes - List all biomes with configuration
configRouter.get('/biomes', async (c) => {
  const result = await db.select().from(biomes);
  return c.json(result);
});

// GET /api/config/biomes/:key - Get single biome configuration
configRouter.get('/biomes/:key', async (c) => {
  const key = c.req.param('key');
  const result = await db.select().from(biomes).where(eq(biomes.key, key as any)).limit(1);

  if (result.length === 0) {
    return c.json({ error: 'Biome not found' }, 404);
  }

  return c.json(result[0]);
});

// GET /api/config/distributions - Get distribution matrix
configRouter.get('/distributions', async (c) => {
  const result = await db.select().from(distributions);

  // Transform to biome -> nodeType -> count structure
  const matrix: Record<string, Record<string, number>> = {};
  for (const row of result) {
    if (!matrix[row.biome]) {
      matrix[row.biome] = {};
    }
    matrix[row.biome][row.nodeType] = row.count;
  }

  return c.json(matrix);
});

// GET /api/config/lookup/:type - Get lookup data by type
const lookupQuerySchema = z.object({
  biome: z.string().optional(),
});

configRouter.get('/lookup/enemy-types', zValidator('query', lookupQuerySchema), async (c) => {
  const { biome } = c.req.valid('query');

  let query = db.select().from(enemyTypes);
  if (biome) {
    query = query.where(eq(enemyTypes.biome, biome as any)) as any;
  }

  const result = await query;
  return c.json(result);
});

configRouter.get('/lookup/environmental-contexts', zValidator('query', lookupQuerySchema), async (c) => {
  const { biome } = c.req.valid('query');

  let query = db.select().from(environmentalContexts);
  if (biome) {
    query = query.where(eq(environmentalContexts.biome, biome as any)) as any;
  }

  const result = await query;
  return c.json(result.map(r => ({ id: r.id, biome: r.biome, hook: r.context })));
});

configRouter.get('/lookup/consequence-hooks', zValidator('query', lookupQuerySchema), async (c) => {
  const { biome } = c.req.valid('query');

  let query = db.select().from(consequenceHooks);
  if (biome) {
    query = query.where(eq(consequenceHooks.biome, biome as any)) as any;
  }

  const result = await query;
  return c.json(result);
});

configRouter.get('/lookup/dream-hooks', zValidator('query', lookupQuerySchema), async (c) => {
  const { biome } = c.req.valid('query');

  let query = db.select().from(dreamHooksTable);
  if (biome) {
    query = query.where(eq(dreamHooksTable.biome, biome as any)) as any;
  }

  const result = await query;
  return c.json(result);
});

configRouter.get('/lookup/travel-event-hooks', zValidator('query', lookupQuerySchema), async (c) => {
  const { biome } = c.req.valid('query');

  let query = db.select().from(travelEventHooks);
  if (biome) {
    query = query.where(eq(travelEventHooks.biome, biome as any)) as any;
  }

  const result = await query;
  return c.json(result);
});

configRouter.get('/lookup/environmental-storytelling', zValidator('query', lookupQuerySchema), async (c) => {
  const { biome } = c.req.valid('query');

  let query = db.select().from(environmentalStorytellingTable);
  if (biome) {
    query = query.where(eq(environmentalStorytellingTable.biome, biome as any)) as any;
  }

  const result = await query;
  return c.json(result.map(r => ({ id: r.id, biome: r.biome, hook: r.storytelling })));
});

configRouter.get('/lookup/condition-hooks', zValidator('query', lookupQuerySchema), async (c) => {
  const { biome } = c.req.valid('query');

  let query = db.select().from(conditionHooksTable);
  if (biome) {
    query = query.where(eq(conditionHooksTable.biome, biome as any)) as any;
  }

  const result = await query;
  return c.json(result);
});

configRouter.get('/lookup/trader-archetypes', zValidator('query', lookupQuerySchema), async (c) => {
  const { biome } = c.req.valid('query');

  let query = db.select().from(traderArchetypes);
  if (biome) {
    query = query.where(eq(traderArchetypes.biome, biome as any)) as any;
  }

  const result = await query;
  return c.json(result.map(r => ({ id: r.id, biome: r.biome, hook: r.archetype, archetypeKey: r.archetype })));
});

const pricingQuerySchema = z.object({
  archetype: z.string().optional(),
});

configRouter.get('/lookup/pricing-hooks', zValidator('query', pricingQuerySchema), async (c) => {
  const { archetype } = c.req.valid('query');

  let query = db.select().from(pricingHooksTable);
  if (archetype) {
    query = query.where(eq(pricingHooksTable.archetypeKey, archetype)) as any;
  }

  const result = await query;
  return c.json(result);
});
