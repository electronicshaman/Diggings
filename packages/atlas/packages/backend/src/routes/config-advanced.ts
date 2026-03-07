import { Hono } from 'hono';
import { zValidator } from '@hono/zod-validator';
import { z } from 'zod';
import {
  BeatRoleCreateSchema,
  BeatSequenceCreateSchema,
  BeatSequenceUpdateSchema,
  StyleGuideUpdateSchema,
  VernacularCreateSchema,
  VernacularUpdateSchema,
  ActToneUpdateSchema,
} from '@atlas/shared';
import { db } from '../db/index.js';
import {
  beatRoles,
  beatSequences,
  styleGuide,
  vernacular,
  actTones,
  distributions,
  nodes,
  generationSettings,
} from '../db/schema.js';
import { eq, and, sql } from 'drizzle-orm';

const app = new Hono();

// ============================================================================
// BEAT ROLES
// ============================================================================

app.get('/beat-roles', async (c) => {
  try {
    const roles = await db.select().from(beatRoles).orderBy(beatRoles.sortOrder);
    return c.json(roles);
  } catch (error) {
    console.error('Error fetching beat roles:', error);
    return c.json({ error: 'Failed to fetch beat roles' }, 500);
  }
});

app.post('/beat-roles', zValidator('json', BeatRoleCreateSchema), async (c) => {
  const data = c.req.valid('json');

  try {
    const [role] = await db.insert(beatRoles).values(data as any).returning();
    return c.json(role, 201);
  } catch (error) {
    console.error('Error creating beat role:', error);
    return c.json({ error: 'Failed to create beat role' }, 500);
  }
});

app.put('/beat-roles/:id', async (c) => {
  const id = parseInt(c.req.param('id'));
  const updates = await c.req.json();

  if (isNaN(id)) {
    return c.json({ error: 'Invalid role ID' }, 400);
  }

  try {
    const [role] = await db.update(beatRoles).set(updates).where(eq(beatRoles.id, id)).returning();

    if (!role) {
      return c.json({ error: 'Beat role not found' }, 404);
    }

    return c.json(role);
  } catch (error) {
    console.error('Error updating beat role:', error);
    return c.json({ error: 'Failed to update beat role' }, 500);
  }
});

app.delete('/beat-roles/:id', async (c) => {
  const id = parseInt(c.req.param('id'));

  if (isNaN(id)) {
    return c.json({ error: 'Invalid role ID' }, 400);
  }

  try {
    const deleted = await db.delete(beatRoles).where(eq(beatRoles.id, id)).returning();

    if (deleted.length === 0) {
      return c.json({ error: 'Beat role not found' }, 404);
    }

    return c.json({ success: true });
  } catch (error) {
    console.error('Error deleting beat role:', error);
    return c.json({ error: 'Failed to delete beat role' }, 500);
  }
});

// ============================================================================
// BEAT SEQUENCES
// ============================================================================

app.get('/beat-sequences', async (c) => {
  const nodeType = c.req.query('nodeType');

  try {
    let query = db.select().from(beatSequences).$dynamic();

    if (nodeType) {
      query = query.where(eq(beatSequences.nodeType, nodeType as any));
    }

    const sequences = await query;
    return c.json(sequences);
  } catch (error) {
    console.error('Error fetching beat sequences:', error);
    return c.json({ error: 'Failed to fetch beat sequences' }, 500);
  }
});

app.post('/beat-sequences', zValidator('json', BeatSequenceCreateSchema), async (c) => {
  const data = c.req.valid('json');

  try {
    const [sequence] = await db.insert(beatSequences).values(data as any).returning();
    return c.json(sequence, 201);
  } catch (error) {
    console.error('Error creating beat sequence:', error);
    return c.json({ error: 'Failed to create beat sequence' }, 500);
  }
});

app.put('/beat-sequences/:id', zValidator('json', BeatSequenceUpdateSchema), async (c) => {
  const id = parseInt(c.req.param('id'));
  const updates = c.req.valid('json');

  if (isNaN(id)) {
    return c.json({ error: 'Invalid sequence ID' }, 400);
  }

  try {
    const updateData = { ...updates, updatedAt: new Date() };
    const [sequence] = await db
      .update(beatSequences)
      .set(updateData as any)
      .where(eq(beatSequences.id, id))
      .returning();

    if (!sequence) {
      return c.json({ error: 'Beat sequence not found' }, 404);
    }

    return c.json(sequence);
  } catch (error) {
    console.error('Error updating beat sequence:', error);
    return c.json({ error: 'Failed to update beat sequence' }, 500);
  }
});

app.delete('/beat-sequences/:id', async (c) => {
  const id = parseInt(c.req.param('id'));

  if (isNaN(id)) {
    return c.json({ error: 'Invalid sequence ID' }, 400);
  }

  try {
    const deleted = await db.delete(beatSequences).where(eq(beatSequences.id, id)).returning();

    if (deleted.length === 0) {
      return c.json({ error: 'Beat sequence not found' }, 404);
    }

    return c.json({ success: true });
  } catch (error) {
    console.error('Error deleting beat sequence:', error);
    return c.json({ error: 'Failed to delete beat sequence' }, 500);
  }
});

// ============================================================================
// STYLE GUIDE
// ============================================================================

app.get('/style-guide', async (c) => {
  const biome = c.req.query('biome');

  try {
    let query = db.select().from(styleGuide).$dynamic();

    if (biome) {
      query = query.where(eq(styleGuide.biome, biome as any));
    }

    const guides = await query;
    return c.json(biome ? guides[0] || null : guides);
  } catch (error) {
    console.error('Error fetching style guide:', error);
    return c.json({ error: 'Failed to fetch style guide' }, 500);
  }
});

app.put('/style-guide/:biome', zValidator('json', StyleGuideUpdateSchema), async (c) => {
  const biome = c.req.param('biome');
  const updates = c.req.valid('json');

  try {
    const updateData = { ...updates, updatedAt: new Date() };
    const [guide] = await db
      .update(styleGuide)
      .set(updateData as any)
      .where(eq(styleGuide.biome, biome as any))
      .returning();

    if (!guide) {
      return c.json({ error: 'Style guide not found for biome' }, 404);
    }

    return c.json(guide);
  } catch (error) {
    console.error('Error updating style guide:', error);
    return c.json({ error: 'Failed to update style guide' }, 500);
  }
});

// ============================================================================
// VERNACULAR
// ============================================================================

app.get('/vernacular', async (c) => {
  try {
    const terms = await db.select().from(vernacular).orderBy(vernacular.sortOrder);
    return c.json(terms);
  } catch (error) {
    console.error('Error fetching vernacular:', error);
    return c.json({ error: 'Failed to fetch vernacular' }, 500);
  }
});

app.post('/vernacular', zValidator('json', VernacularCreateSchema), async (c) => {
  const data = c.req.valid('json');

  try {
    const [term] = await db.insert(vernacular).values(data as any).returning();
    return c.json(term, 201);
  } catch (error) {
    console.error('Error creating vernacular term:', error);
    return c.json({ error: 'Failed to create vernacular term' }, 500);
  }
});

app.put('/vernacular/:id', zValidator('json', VernacularUpdateSchema), async (c) => {
  const id = parseInt(c.req.param('id'));
  const updates = c.req.valid('json');

  if (isNaN(id)) {
    return c.json({ error: 'Invalid term ID' }, 400);
  }

  try {
    const [term] = await db
      .update(vernacular)
      .set(updates as any)
      .where(eq(vernacular.id, id))
      .returning();

    if (!term) {
      return c.json({ error: 'Vernacular term not found' }, 404);
    }

    return c.json(term);
  } catch (error) {
    console.error('Error updating vernacular term:', error);
    return c.json({ error: 'Failed to update vernacular term' }, 500);
  }
});

app.delete('/vernacular/:id', async (c) => {
  const id = parseInt(c.req.param('id'));

  if (isNaN(id)) {
    return c.json({ error: 'Invalid term ID' }, 400);
  }

  try {
    const deleted = await db.delete(vernacular).where(eq(vernacular.id, id)).returning();

    if (deleted.length === 0) {
      return c.json({ error: 'Vernacular term not found' }, 404);
    }

    return c.json({ success: true });
  } catch (error) {
    console.error('Error deleting vernacular term:', error);
    return c.json({ error: 'Failed to delete vernacular term' }, 500);
  }
});

// ============================================================================
// ACT TONES
// ============================================================================

app.get('/act-tones', async (c) => {
  const act = c.req.query('act');

  try {
    let query = db.select().from(actTones).$dynamic();

    if (act) {
      const actNum = parseInt(act);
      if (!isNaN(actNum)) {
        query = query.where(eq(actTones.act, actNum));
      }
    }

    const tones = await query.orderBy(actTones.act);
    return c.json(act ? tones[0] || null : tones);
  } catch (error) {
    console.error('Error fetching act tones:', error);
    return c.json({ error: 'Failed to fetch act tones' }, 500);
  }
});

app.put('/act-tones/:act', zValidator('json', ActToneUpdateSchema), async (c) => {
  const act = parseInt(c.req.param('act'));
  const updates = c.req.valid('json');

  if (isNaN(act) || act < 1 || act > 4) {
    return c.json({ error: 'Invalid act number (must be 1-4)' }, 400);
  }

  try {
    const updateData = { ...updates, updatedAt: new Date() };
    const [tone] = await db
      .update(actTones)
      .set(updateData as any)
      .where(eq(actTones.act, act))
      .returning();

    if (!tone) {
      return c.json({ error: 'Act tone not found' }, 404);
    }

    return c.json(tone);
  } catch (error) {
    console.error('Error updating act tone:', error);
    return c.json({ error: 'Failed to update act tone' }, 500);
  }
});

// ============================================================================
// GENERATION SETTINGS
// ============================================================================

app.get('/generation-settings', async (c) => {
  try {
    const [settings] = await db.select().from(generationSettings).limit(1);

    if (!settings) {
      return c.json({ error: 'Generation settings not found' }, 404);
    }

    return c.json(settings);
  } catch (error) {
    console.error('Error fetching generation settings:', error);
    return c.json({ error: 'Failed to fetch generation settings' }, 500);
  }
});

app.put('/generation-settings', async (c) => {
  const updates = await c.req.json();

  try {
    const updateData = { ...updates, updatedAt: new Date() };
    const [settings] = await db.update(generationSettings).set(updateData).returning();

    if (!settings) {
      return c.json({ error: 'Generation settings not found' }, 404);
    }

    return c.json(settings);
  } catch (error) {
    console.error('Error updating generation settings:', error);
    return c.json({ error: 'Failed to update generation settings' }, 500);
  }
});

// ============================================================================
// DISTRIBUTION GAP ANALYSIS
// ============================================================================

app.get('/distributions/gaps', async (c) => {
  try {
    // Get target distributions
    const targetDists = await db.select().from(distributions);

    // Get actual node counts grouped by biome and type
    const actualCounts = await db
      .select({
        biome: nodes.biome,
        nodeType: nodes.type,
        count: sql<number>`count(*)::int`,
      })
      .from(nodes)
      .groupBy(nodes.biome, nodes.type);

    // Create a map of actual counts
    const actualMap = new Map<string, number>();
    for (const row of actualCounts) {
      const key = `${row.biome}_${row.nodeType}`;
      actualMap.set(key, row.count);
    }

    // Calculate gaps
    const gaps = targetDists.map((target) => {
      const key = `${target.biome}_${target.nodeType}`;
      const actual = actualMap.get(key) || 0;
      const gap = target.count - actual;

      return {
        biome: target.biome,
        nodeType: target.nodeType,
        target: target.count,
        actual,
        gap,
        needsGeneration: gap > 0,
      };
    });

    // Filter to only gaps that need generation
    const gapsToFill = gaps.filter((g) => g.needsGeneration);

    return c.json({
      gaps,
      totalGaps: gapsToFill.length,
      totalNodesNeeded: gapsToFill.reduce((sum, g) => sum + g.gap, 0),
    });
  } catch (error) {
    console.error('Error analyzing distribution gaps:', error);
    return c.json({ error: 'Failed to analyze distribution gaps' }, 500);
  }
});

export default app;
