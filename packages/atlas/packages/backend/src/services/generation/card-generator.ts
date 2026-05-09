/**
 * Card generation service — generates a single card using the active LLM provider.
 * Validates output against CardSchema (minus id) with up to 3 retry attempts.
 */

import { z } from 'zod';
import { CardSchema, CARD_HANDLER_REGISTRY, type CardGenerationRequest } from '@atlas/shared';
import { complete, parseJsonResponse } from './llm-client.js';

// Schema for LLM output (no id required — we assign it after)
const CardOutputSchema = CardSchema.omit({ id: true });
type CardOutput = z.infer<typeof CardOutputSchema>;

/**
 * Format the handler registry as a compact reference table for the system prompt.
 */
function formatHandlerRegistry(): string {
  return CARD_HANDLER_REGISTRY.map((h) => {
    const paramLines = Object.entries(h.params)
      .map(([key, p]) => `    ${key} (${p.type}${p.required ? ', required' : ''}): ${p.description}`)
      .join('\n');
    return `  ${h.handlerId} — ${h.description} [applies to: ${h.applicableTo.join(', ')}]\n${paramLines}`;
  }).join('\n\n');
}

const SYSTEM_PROMPT = `You are a card designer for "The Diggings", an Australian frontier/mining horror card game.

## Setting
The Diggings is set in 1870s colonial Australia. Players navigate a harsh mining frontier where horror lurks beneath the surface. The five playable classes are:
- bushranger: outlaw, fast attacks, ambush tactics, uses ammo
- prospector: reckless gold-chaser, risk/reward mechanics, uses fever (obsession)
- tracker: indigenous knowledge, nature communion, uses scent
- publican: community leader, debuffs/control, uses brew
- preacher: religious zealot, sanity/faith mechanics, uses faith

## Card Schema Rules
You must output valid JSON matching the card schema exactly. Key rules:
- name: evocative, 1-5 words, Australian frontier flavour
- description: mechanical effect text, clear and concise (max 150 chars)
- flavorText: atmospheric quote or snippet, optional but encouraged
- costs: array of {type, amount} where type is "energy" | "sanity" | "resource". Most cards cost 1-3 energy. High-rarity cards may cost sanity.
- effects: array of {handlerId, params} — handlerId MUST be one from the registry below
- classAffinity: array of class names this card suits (bushranger/prospector/tracker/publican/preacher), or [] for universal
- baseDurability: integer for Equipped cards (how many uses), null otherwise
- volatileBonus: true only for Fortune or Eldritch cards with a random element
- luckModifier: float, usually 0. Fortune cards may have 0.1–0.3

## Rarity Guidelines
- Common: straightforward, 1 effect, low cost
- Uncommon: 1-2 effects, moderate complexity
- Rare: strong effects, thematic synergy, may have conditional triggers
- Eldritch: powerful, unsettling flavour, high cost or risk

## Handling Semantics
- Standard: played from hand, consumed
- Equipped: permanent equipment card (use baseDurability)
- Flash: 0-cost instant
- Keep: retained each turn
- Hold: held in hand without cost reduction
- Oneshot: powerful single use, then removed from game

## Handler Registry
${formatHandlerRegistry()}

Output JSON only — no markdown, no explanation. Match the schema exactly.`;

function buildUserPrompt(request: CardGenerationRequest): string {
  const parts = [
    `Generate a ${request.rarity} ${request.cardType} card.`,
    `Owner: ${request.cardOwner}.`,
    `Handling: ${request.handling}.`,
    `Accessibility tier: ${request.accessibilityTier}.`,
  ];

  if (request.classAffinity && request.classAffinity.length > 0) {
    parts.push(`Preferred class affinity: ${request.classAffinity.join(', ')}.`);
  }

  if (request.themeHint) {
    parts.push(`Theme hint: ${request.themeHint}.`);
  }

  parts.push(`Return only JSON with fields: name, description, flavorText, cardType, rarity, cardOwner, handling, accessibilityTier, costs, effects, classAffinity, baseDurability, volatileBonus, luckModifier.`);

  return parts.join(' ');
}

/**
 * Generate a single card using the active LLM provider.
 * Returns the validated card data (without id — caller assigns it).
 */
export async function generateCard(request: CardGenerationRequest): Promise<CardOutput> {
  const systemPrompt = SYSTEM_PROMPT;
  const userPrompt = buildUserPrompt(request);

  let lastError: Error | null = null;

  for (let attempt = 0; attempt < 3; attempt++) {
    const retryNote =
      attempt > 0 && lastError
        ? `\n\nPrevious attempt failed validation: ${lastError.message}. Fix these issues and try again.`
        : '';

    try {
      const result = await complete({
        systemPrompt,
        userPrompt: userPrompt + retryNote,
        temperature: 0.8,
        maxTokens: 1024,
        responseFormat: 'json',
      });

      const raw = parseJsonResponse<unknown>(result.content);
      const parsed = CardOutputSchema.parse(raw);
      return parsed;
    } catch (err) {
      lastError = err instanceof Error ? err : new Error(String(err));
      console.warn(`[card-generator] Attempt ${attempt + 1} failed: ${lastError.message}`);
    }
  }

  throw lastError ?? new Error('Card generation failed after 3 attempts');
}
