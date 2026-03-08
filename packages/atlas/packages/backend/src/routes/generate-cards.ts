/**
 * POST /api/generate/cards/bulk
 * SSE streaming bulk card generation based on distribution gap analysis.
 */

import { Hono } from 'hono';
import { zValidator } from '@hono/zod-validator';
import { sql } from 'drizzle-orm';
import {
  BulkCardGenerationRequestSchema,
  type BulkCardGenerationRequest,
  CARD_DISTRIBUTION,
  CARD_TYPES,
  CARD_RARITIES,
  type CardType,
  type CardRarity,
  CARD_HANDLING,
  ACCESSIBILITY_TIERS,
} from '@atlas/shared';
import type { CardGenerationRequest } from '@atlas/shared';
import { db, cards } from '../db/index.js';
import { generateCard } from '../services/generation/card-generator.js';

const app = new Hono();

// ── SSE helpers ──────────────────────────────────────────────────────────────

function formatSSE(event: string, data: unknown): string {
  return `event: ${event}\ndata: ${JSON.stringify(data)}\n\n`;
}

// ── Gap analysis ─────────────────────────────────────────────────────────────

interface CardSlot {
  cardType: CardType;
  rarity: CardRarity;
}

async function computeCardGapQueue(
  request: BulkCardGenerationRequest
): Promise<{ queue: CardSlot[]; plan: { cardType: CardType; rarity: CardRarity; count: number }[] }> {
  // Query existing card counts grouped by type + rarity
  const countRows = await db
    .select({
      cardType: cards.cardType,
      rarity: cards.rarity,
      count: sql<number>`cast(count(*) as int)`,
    })
    .from(cards)
    .groupBy(cards.cardType, cards.rarity);

  const actual: Partial<Record<CardType, Partial<Record<CardRarity, number>>>> = {};
  for (const row of countRows) {
    if (!row.cardType || !row.rarity) continue;
    const type = row.cardType as CardType;
    const rarity = row.rarity as CardRarity;
    if (!actual[type]) actual[type] = {};
    actual[type]![rarity] = row.count;
  }

  // Compute total weight across all type+rarity combos
  let totalWeight = 0;
  for (const type of CARD_TYPES) {
    for (const rarity of CARD_RARITIES) {
      totalWeight += CARD_DISTRIBUTION[type][rarity];
    }
  }

  const queue: CardSlot[] = [];
  const plan: { cardType: CardType; rarity: CardRarity; count: number }[] = [];

  for (const type of CARD_TYPES) {
    for (const rarity of CARD_RARITIES) {
      const weight = CARD_DISTRIBUTION[type][rarity];
      const target = Math.round((request.targetTotal * weight) / totalWeight);
      const actualCount = actual[type]?.[rarity] ?? 0;
      const gap = Math.max(0, target - actualCount);

      if (gap > 0) {
        plan.push({ cardType: type, rarity, count: gap });
        for (let i = 0; i < gap; i++) {
          queue.push({ cardType: type, rarity });
        }
      }
    }
  }

  return { queue, plan };
}

// ── Determine handling + accessibilityTier from rarity ───────────────────────

function deriveHandlingForRarity(rarity: CardRarity): (typeof CARD_HANDLING)[number] {
  switch (rarity) {
    case 'Common':
      return 'Standard';
    case 'Uncommon':
      return Math.random() < 0.7 ? 'Standard' : 'Flash';
    case 'Rare':
      return CARD_HANDLING[Math.floor(Math.random() * CARD_HANDLING.length)];
    case 'Eldritch':
      return Math.random() < 0.5 ? 'Keep' : 'Oneshot';
  }
}

function deriveAccessibilityTier(rarity: CardRarity): (typeof ACCESSIBILITY_TIERS)[number] {
  switch (rarity) {
    case 'Common':
      return Math.random() < 0.5 ? 'Starting' : 'Neutral';
    case 'Uncommon':
      return Math.random() < 0.6 ? 'Class' : 'Neutral';
    case 'Rare':
    case 'Eldritch':
      return 'Rare';
  }
}

// ── ID generation (same pattern as cards CRUD route) ─────────────────────────

async function generateCardId(): Promise<string> {
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
}

// ── Bulk SSE endpoint ─────────────────────────────────────────────────────────

app.post('/bulk', zValidator('json', BulkCardGenerationRequestSchema), async (c) => {
  const request = c.req.valid('json') as BulkCardGenerationRequest;

  c.header('Content-Type', 'text/event-stream');
  c.header('Cache-Control', 'no-cache, no-store, must-revalidate');
  c.header('Connection', 'keep-alive');
  c.header('X-Accel-Buffering', 'no');

  const encoder = new TextEncoder();
  const jobId = crypto.randomUUID();

  const stream = new ReadableStream({
    async start(controller) {
      // Heartbeat to keep connection alive
      const heartbeat = setInterval(() => {
        try {
          controller.enqueue(encoder.encode(formatSSE('ping', { timestamp: Date.now() })));
        } catch {
          clearInterval(heartbeat);
        }
      }, 12000);

      try {
        const { queue, plan } = await computeCardGapQueue(request);
        const totalCards = queue.length;

        controller.enqueue(
          encoder.encode(
            formatSSE('bulk_start', { jobId, totalCards, plan })
          )
        );

        if (totalCards === 0) {
          controller.enqueue(
            encoder.encode(
              formatSSE('bulk_complete', {
                totalCards: 0,
                succeeded: 0,
                failed: 0,
                cardIds: [],
              })
            )
          );
          clearInterval(heartbeat);
          controller.close();
          return;
        }

        let succeeded = 0;
        let failed = 0;
        const cardIds: string[] = [];

        for (let i = 0; i < queue.length; i++) {
          const slot = queue[i];

          controller.enqueue(
            encoder.encode(
              formatSSE('card_start', {
                index: i,
                cardType: slot.cardType,
                rarity: slot.rarity,
              })
            )
          );

          try {
            const genRequest: CardGenerationRequest = {
              cardType: slot.cardType,
              rarity: slot.rarity,
              cardOwner: request.cardOwner ?? 'PLAYER',
              handling: deriveHandlingForRarity(slot.rarity),
              accessibilityTier: deriveAccessibilityTier(slot.rarity),
            };

            const cardData = await generateCard(genRequest);
            const cardId = await generateCardId();

            await db.insert(cards).values({
              cardId,
              name: cardData.name,
              description: cardData.description ?? '',
              cardType: cardData.cardType,
              costs: cardData.costs ?? [],
              effects: cardData.effects ?? [],
              rarity: cardData.rarity,
              cardOwner: cardData.cardOwner,
              handling: cardData.handling,
              classAffinity: cardData.classAffinity ?? [],
              accessibilityTier: cardData.accessibilityTier,
              flavorText: cardData.flavorText,
              baseDurability: cardData.baseDurability,
              volatileBonus: cardData.volatileBonus,
              luckModifier: cardData.luckModifier,
            });

            cardIds.push(cardId);
            succeeded++;

            controller.enqueue(
              encoder.encode(
                formatSSE('card_complete', {
                  index: i,
                  cardId,
                  name: cardData.name,
                  cardType: slot.cardType,
                  rarity: slot.rarity,
                })
              )
            );
          } catch (err) {
            failed++;
            const error = err instanceof Error ? err.message : String(err);
            console.error(`[generate-cards] Card ${i} failed (${slot.cardType}/${slot.rarity}): ${error}`);

            controller.enqueue(
              encoder.encode(
                formatSSE('card_error', {
                  index: i,
                  cardType: slot.cardType,
                  rarity: slot.rarity,
                  error,
                })
              )
            );
          }
        }

        controller.enqueue(
          encoder.encode(
            formatSSE('bulk_complete', {
              totalCards,
              succeeded,
              failed,
              cardIds,
            })
          )
        );
      } catch (err) {
        const error = err instanceof Error ? err.message : String(err);
        console.error('[generate-cards] Bulk generation failed:', error);
        controller.enqueue(
          encoder.encode(formatSSE('card_error', { index: -1, cardType: null, rarity: null, error }))
        );
      } finally {
        clearInterval(heartbeat);
        controller.close();
      }
    },
  });

  return new Response(stream);
});

export default app;
