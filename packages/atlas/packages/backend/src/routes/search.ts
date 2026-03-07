import { Hono } from 'hono';
import { z } from 'zod';
import { zValidator } from '@hono/zod-validator';
import { db, nodes } from '../db/index.js';
import { sql, count, eq } from 'drizzle-orm';

export const searchRouter = new Hono();

// GET /api/search?q=... - Full-text search
const searchQuerySchema = z.object({
  q: z.string().min(2),
  limit: z.coerce.number().int().min(1).max(100).default(20),
  offset: z.coerce.number().int().min(0).default(0),
});

searchRouter.get('/', zValidator('query', searchQuerySchema), async (c) => {
  const { q, limit, offset } = c.req.valid('query');

  // Search in name, nodeId, and content fields
  const searchCondition = sql`
    ${nodes.nodeId} ILIKE ${`%${q}%`} OR
    ${nodes.name} ILIKE ${`%${q}%`} OR
    ${nodes.narrativeSummary} ILIKE ${`%${q}%`}
  `;

  const [totalResult, result] = await Promise.all([
    db.select({ count: count() }).from(nodes).where(searchCondition),
    db.select().from(nodes).where(searchCondition).limit(limit).offset(offset),
  ]);

  return c.json({
    data: result,
    pagination: {
      limit,
      offset,
      total: totalResult[0]?.count ?? 0,
    },
  });
});

// GET /api/search/stats - Distribution statistics
searchRouter.get('/stats', async (c) => {
  // Count by type
  const byType = await db
    .select({
      type: nodes.type,
      count: count(),
    })
    .from(nodes)
    .groupBy(nodes.type);

  // Count by biome
  const byBiome = await db
    .select({
      biome: nodes.biome,
      count: count(),
    })
    .from(nodes)
    .groupBy(nodes.biome);

  // Total count
  const totalResult = await db.select({ count: count() }).from(nodes);
  const total = totalResult[0]?.count || 0;

  return c.json({
    total,
    byType,
    byBiome,
  });
});
