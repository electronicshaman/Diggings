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
  try {
    const result = await db.select().from(biomes);
    return c.json(result);
  } catch (error) {
    console.error('Error fetching biomes:', error);
    return c.json({ error: 'Failed to fetch biomes' }, 500);
  }
});

// GET /api/config/biomes/:key - Get single biome configuration
configRouter.get('/biomes/:key', async (c) => {
  try {
    const key = c.req.param('key');
    const result = await db.select().from(biomes).where(eq(biomes.key, key as any)).limit(1);

    if (result.length === 0) {
      return c.json({ error: 'Biome not found' }, 404);
    }

    return c.json(result[0]);
  } catch (error) {
    console.error('Error fetching biome:', error);
    return c.json({ error: 'Failed to fetch biome' }, 500);
  }
});

// GET /api/config/distributions - Get distribution matrix
configRouter.get('/distributions', async (c) => {
  try {
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
  } catch (error) {
    console.error('Error fetching distributions:', error);
    return c.json({ error: 'Failed to fetch distributions' }, 500);
  }
});

// GET /api/config/lookup/:type - Get lookup data by type
const lookupQuerySchema = z.object({
  biome: z.string().optional(),
});

configRouter.get('/lookup/enemy-types', zValidator('query', lookupQuerySchema), async (c) => {
  try {
    const { biome } = c.req.valid('query');

    let query = db.select().from(enemyTypes);
    if (biome) {
      query = query.where(eq(enemyTypes.biome, biome as any)) as any;
    }

    const result = await query;
    return c.json(result);
  } catch (error) {
    console.error('Error fetching enemy types:', error);
    return c.json({ error: 'Failed to fetch enemy types' }, 500);
  }
});

configRouter.get('/lookup/environmental-contexts', zValidator('query', lookupQuerySchema), async (c) => {
  try {
    const { biome } = c.req.valid('query');

    let query = db.select().from(environmentalContexts);
    if (biome) {
      query = query.where(eq(environmentalContexts.biome, biome as any)) as any;
    }

    const result = await query;
    return c.json(result.map(r => ({ id: r.id, biome: r.biome, hook: r.context })));
  } catch (error) {
    console.error('Error fetching environmental contexts:', error);
    return c.json({ error: 'Failed to fetch environmental contexts' }, 500);
  }
});

configRouter.get('/lookup/consequence-hooks', zValidator('query', lookupQuerySchema), async (c) => {
  try {
    const { biome } = c.req.valid('query');

    let query = db.select().from(consequenceHooks);
    if (biome) {
      query = query.where(eq(consequenceHooks.biome, biome as any)) as any;
    }

    const result = await query;
    return c.json(result);
  } catch (error) {
    console.error('Error fetching consequence hooks:', error);
    return c.json({ error: 'Failed to fetch consequence hooks' }, 500);
  }
});

configRouter.get('/lookup/dream-hooks', zValidator('query', lookupQuerySchema), async (c) => {
  try {
    const { biome } = c.req.valid('query');

    let query = db.select().from(dreamHooksTable);
    if (biome) {
      query = query.where(eq(dreamHooksTable.biome, biome as any)) as any;
    }

    const result = await query;
    return c.json(result);
  } catch (error) {
    console.error('Error fetching dream hooks:', error);
    return c.json({ error: 'Failed to fetch dream hooks' }, 500);
  }
});

configRouter.get('/lookup/travel-event-hooks', zValidator('query', lookupQuerySchema), async (c) => {
  try {
    const { biome } = c.req.valid('query');

    let query = db.select().from(travelEventHooks);
    if (biome) {
      query = query.where(eq(travelEventHooks.biome, biome as any)) as any;
    }

    const result = await query;
    return c.json(result);
  } catch (error) {
    console.error('Error fetching travel event hooks:', error);
    return c.json({ error: 'Failed to fetch travel event hooks' }, 500);
  }
});

configRouter.get('/lookup/environmental-storytelling', zValidator('query', lookupQuerySchema), async (c) => {
  try {
    const { biome } = c.req.valid('query');

    let query = db.select().from(environmentalStorytellingTable);
    if (biome) {
      query = query.where(eq(environmentalStorytellingTable.biome, biome as any)) as any;
    }

    const result = await query;
    return c.json(result.map(r => ({ id: r.id, biome: r.biome, hook: r.storytelling })));
  } catch (error) {
    console.error('Error fetching environmental storytelling:', error);
    return c.json({ error: 'Failed to fetch environmental storytelling' }, 500);
  }
});

configRouter.get('/lookup/condition-hooks', zValidator('query', lookupQuerySchema), async (c) => {
  try {
    const { biome } = c.req.valid('query');

    let query = db.select().from(conditionHooksTable);
    if (biome) {
      query = query.where(eq(conditionHooksTable.biome, biome as any)) as any;
    }

    const result = await query;
    return c.json(result);
  } catch (error) {
    console.error('Error fetching condition hooks:', error);
    return c.json({ error: 'Failed to fetch condition hooks' }, 500);
  }
});

configRouter.get('/lookup/trader-archetypes', zValidator('query', lookupQuerySchema), async (c) => {
  try {
    const { biome } = c.req.valid('query');

    let query = db.select().from(traderArchetypes);
    if (biome) {
      query = query.where(eq(traderArchetypes.biome, biome as any)) as any;
    }

    const result = await query;
    return c.json(result.map(r => ({ id: r.id, biome: r.biome, hook: r.archetype, archetypeKey: r.archetype })));
  } catch (error) {
    console.error('Error fetching trader archetypes:', error);
    return c.json({ error: 'Failed to fetch trader archetypes' }, 500);
  }
});

const pricingQuerySchema = z.object({
  archetype: z.string().optional(),
});

configRouter.get('/lookup/pricing-hooks', zValidator('query', pricingQuerySchema), async (c) => {
  try {
    const { archetype } = c.req.valid('query');

    let query = db.select().from(pricingHooksTable);
    if (archetype) {
      query = query.where(eq(pricingHooksTable.archetypeKey, archetype)) as any;
    }

    const result = await query;
    return c.json(result);
  } catch (error) {
    console.error('Error fetching pricing hooks:', error);
    return c.json({ error: 'Failed to fetch pricing hooks' }, 500);
  }
});
