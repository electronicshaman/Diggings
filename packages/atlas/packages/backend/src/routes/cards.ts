import { Hono } from 'hono';
import { zValidator } from '@hono/zod-validator';
import { z } from 'zod';
import { db, cards } from '../db/index.js';
import { eq, and, sql } from 'drizzle-orm';
import { CardSchema } from '@atlas/shared';

const cardsRouter = new Hono();

const CardCreateSchema = CardSchema.extend({
  id: z.string().min(1).optional(),
});

const CardPatchSchema = z.object({
  name: z.string().min(1).max(255).optional(),
  description: z.string().optional(),
  cardType: z.enum(['Attack', 'Skill', 'Power', 'Fortune', 'Hex', 'Curse']).optional(),
  costs: z.array(z.any()).optional(),
  effects: z.array(z.any()).optional(),
  rarity: z.enum(['Common', 'Uncommon', 'Rare', 'Eldritch']).optional(),
  cardOwner: z.enum(['PLAYER', 'ENEMY', 'NEUTRAL']).optional(),
  handling: z.enum(['Standard', 'Equipped', 'Flash', 'Keep', 'Hold', 'Oneshot']).optional(),
  classAffinity: z.array(z.string()).optional(),
  accessibilityTier: z.enum(['Starting', 'Class', 'Neutral', 'Rare']).optional(),
  flavorText: z.string().optional(),
  baseDurability: z.number().int().optional(),
  volatileBonus: z.boolean().optional(),
  luckModifier: z.number().optional(),
  enemyFaction: z.string().optional(),
});

const listQuerySchema = z.object({
  cardType: z.string().optional(),
  rarity: z.string().optional(),
  cardOwner: z.string().optional(),
  handling: z.string().optional(),
  accessibilityTier: z.string().optional(),
  limit: z.coerce.number().int().min(1).max(100).default(50),
  offset: z.coerce.number().int().min(0).default(0),
});

const generateCardId = async (): Promise<string> => {
  const existing = await db
    .select({ cardId: cards.cardId })
    .from(cards)
    .where(sql`${cards.cardId} ILIKE ${'CARD_%'}`);

  let maxSuffix = 0;
  for (const row of existing) {
    const parts = row.cardId.split('_');
    const last = parts[parts.length - 1];
    const parsed = Number.parseInt(last, 10);
    if (!Number.isNaN(parsed)) {
      maxSuffix = Math.max(maxSuffix, parsed);
    }
  }

  const next = maxSuffix + 1;
  return `CARD_${String(next).padStart(3, '0')}`;
};

// GET /api/cards - List cards with filtering
cardsRouter.get('/', zValidator('query', listQuerySchema), async (c) => {
  const { cardType, rarity, cardOwner, handling, accessibilityTier, limit, offset } =
    c.req.valid('query');

  let query = db.select().from(cards);

  const conditions = [];
  if (cardType) conditions.push(eq(cards.cardType, cardType as any));
  if (rarity) conditions.push(eq(cards.rarity, rarity as any));
  if (cardOwner) conditions.push(eq(cards.cardOwner, cardOwner as any));
  if (handling) conditions.push(eq(cards.handling, handling as any));
  if (accessibilityTier) conditions.push(eq(cards.accessibilityTier, accessibilityTier as any));

  if (conditions.length > 0) {
    query = query.where(and(...conditions)) as any;
  }

  const result = await query.limit(limit).offset(offset);

  return c.json({
    data: result,
    pagination: { limit, offset, total: result.length },
  });
});

// GET /api/cards/:cardId - Get single card
cardsRouter.get('/:cardId', async (c) => {
  const cardId = c.req.param('cardId');
  const result = await db.select().from(cards).where(eq(cards.cardId, cardId)).limit(1);

  if (result.length === 0) {
    return c.json({ error: 'Card not found' }, 404);
  }

  return c.json(result[0]);
});

// POST /api/cards - Create card
cardsRouter.post('/', zValidator('json', CardCreateSchema), async (c) => {
  const data = c.req.valid('json');
  const cardId = data.id || (await generateCardId());

  const dbData = {
    cardId,
    name: data.name,
    description: data.description ?? '',
    cardType: data.cardType,
    costs: data.costs ?? [],
    effects: data.effects ?? [],
    rarity: data.rarity,
    cardOwner: data.cardOwner,
    handling: data.handling,
    classAffinity: data.classAffinity ?? [],
    accessibilityTier: data.accessibilityTier,
    flavorText: data.flavorText,
    baseDurability: data.baseDurability,
    volatileBonus: data.volatileBonus,
    luckModifier: data.luckModifier,
    enemyFaction: data.enemyFaction,
  };

  const result = await db.insert(cards).values(dbData).returning();
  return c.json(result[0], 201);
});

// PUT /api/cards/:cardId - Full replace
cardsRouter.put('/:cardId', zValidator('json', CardSchema), async (c) => {
  const cardId = c.req.param('cardId');
  const data = c.req.valid('json');

  const existing = await db.select().from(cards).where(eq(cards.cardId, cardId)).limit(1);
  if (existing.length === 0) {
    return c.json({ error: 'Card not found' }, 404);
  }

  const dbData = {
    cardId: data.id,
    name: data.name,
    description: data.description ?? '',
    cardType: data.cardType,
    costs: data.costs ?? [],
    effects: data.effects ?? [],
    rarity: data.rarity,
    cardOwner: data.cardOwner,
    handling: data.handling,
    classAffinity: data.classAffinity ?? [],
    accessibilityTier: data.accessibilityTier,
    flavorText: data.flavorText,
    baseDurability: data.baseDurability,
    volatileBonus: data.volatileBonus,
    luckModifier: data.luckModifier,
    enemyFaction: data.enemyFaction,
    updatedAt: new Date(),
  };

  const result = await db.update(cards).set(dbData).where(eq(cards.cardId, cardId)).returning();
  return c.json(result[0]);
});

// PATCH /api/cards/:cardId - Partial update
cardsRouter.patch('/:cardId', zValidator('json', CardPatchSchema), async (c) => {
  const cardId = c.req.param('cardId');
  const data = c.req.valid('json');

  const existing = await db.select().from(cards).where(eq(cards.cardId, cardId)).limit(1);
  if (existing.length === 0) {
    return c.json({ error: 'Card not found' }, 404);
  }

  const result = await db
    .update(cards)
    .set({ ...data, updatedAt: new Date() })
    .where(eq(cards.cardId, cardId))
    .returning();

  return c.json(result[0]);
});

// DELETE /api/cards/:cardId - Delete card
cardsRouter.delete('/:cardId', async (c) => {
  const cardId = c.req.param('cardId');

  const existing = await db.select().from(cards).where(eq(cards.cardId, cardId)).limit(1);
  if (existing.length === 0) {
    return c.json({ error: 'Card not found' }, 404);
  }

  await db.delete(cards).where(eq(cards.cardId, cardId));
  return c.json({ success: true });
});

export default cardsRouter;
