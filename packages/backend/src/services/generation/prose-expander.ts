/**
 * Prose expander - Second generation stage
 * Expands beat outlines into full prose with outcomes and options
 */

import { completeWithRetry, parseJsonResponse } from './llm-client.js';
import {
  buildNodeContext,
  formatBiomeToneForPrompt,
  formatActToneForPrompt,
  getVernacularHint,
  type NodeGenerationContext,
} from './prompt-builder.js';
import type { BeatOutline } from './beat-outliner.js';

// System prompt base (vernacular loaded from DB at call time)
export const PROSE_EXPANDER_SYSTEM_PROMPT = 'DEPRECATED: use buildProseExpanderSystemPrompt()';

async function buildProseExpanderSystemPrompt(): Promise<string> {
  const vocabHint = await getVernacularHint();
  return `You are a prose writer for an Australian Gold Rush cosmic horror game set in the 1850s.

Your task is to expand beat outlines into full prose. You'll receive a beat sheet and must write evocative, period-appropriate text for each beat.

## Writing Style Guidelines
- Concise but evocative (1-3 sentences per beat, 10-150 characters per beat text)
- Second person present tense ("You see...", "The miner watches...")
- Historical authenticity (1850s Australian vernacular where appropriate)
- Sensory-rich descriptions
- Build tension progressively
- Show through concrete detail, don't tell through summary
- Avoid clichés ("Indian burial ground", generic horror tropes)
${vocabHint}

## Act-Specific Tones
- Act 1 (Arrival): Hope, opportunity, frontier grit. Dust, sun, sweat.
- Act 2 (Fever): Greed, competition, first wrongness. Gold glint, bloodshot eyes.
- Act 3 (Blasphemy): Forbidden truths, isolation, corruption. Salt, silence, shifting geometry.
- Act 4 (Unmaking): Cosmic dread, futility, transformation. Static, void, impossible colors.

## Output Format
Return valid JSON:
{
  "narrative_hook": "Expanded 1-3 sentence encounter description",
  "beats": [
    {
      "id": "beat_id",
      "role": "role",
      "text": "The actual prose text (1-3 sentences)"
    }
  ],
  "outcomes": {
    "victory": { "text": "Victory description", "buttonText": "Continue" },
    "defeat": { "text": "Defeat description", "buttonText": "Accept fate" },
    "neutral": { "text": "Neutral outcome", "buttonText": "Move on" }
  },
  "options": [
    {
      "id": "option_1",
      "label": "Short label (5-10 words)",
      "description": "Consequence hint (1 sentence)"
    }
  ]
}

## Rules
- Keep beat text concise but impactful
- Each beat should feel distinct
- Victory/defeat outcomes only for combat/challenge nodes
- Options only for choice nodes
- Neutral outcomes for passage/rest nodes
- Button text should match tone (hopeful early, resigned late)`;
}

export interface StoryBeat {
  id: string;
  role: string;
  text: string;
}

export interface OutcomeText {
  text: string;
  buttonText: string;
}

export interface ChoiceOption {
  id: string;
  label: string;
  description: string;
}

export interface ExpandedContent {
  narrative_hook: string;
  beats: StoryBeat[];
  outcomes?: {
    victory?: OutcomeText;
    defeat?: OutcomeText;
    neutral?: OutcomeText;
  };
  options?: ChoiceOption[];
}

/**
 * Build prose expander prompt
 */
function createProseExpanderPrompt(
  context: NodeGenerationContext,
  outline: BeatOutline,
  nodeMetadata: any
): string {
  const needsOutcomes = ['combat'].includes(context.nodeType);
  const needsOptions = context.nodeType === 'choice';
  const needsNeutral = ['passage', 'rest', 'trade'].includes(context.nodeType);

  let outcomeGuidance = '';
  if (needsOutcomes) {
    outcomeGuidance = '\nInclude victory and defeat outcomes.';
  } else if (needsNeutral) {
    outcomeGuidance = '\nInclude a neutral outcome.';
  }

  let optionsGuidance = '';
  if (needsOptions) {
    optionsGuidance = `\nInclude 2-4 player options for this ${nodeMetadata.dilemmaType || 'unknown'} dilemma.
Consider consequence hooks: ${nodeMetadata.consequenceHooks?.join(', ') || 'none'}`;
  }

  const biomeContext = context.biomeTone
    ? formatBiomeToneForPrompt(context.biomeTone, context.biome)
    : `Biome: ${context.biome}`;

  const actContext = context.actTone ? formatActToneForPrompt(context.actTone) : '';

  return `Expand this beat outline into full prose:

${biomeContext}

Node: ${context.nodeId} (${context.nodeType})
Biome: ${context.biome}
Themes: ${context.themes.join(', ')}
${actContext}

## Beat Outline
Narrative Hook: ${outline.narrative_hook}
Mood: ${outline.mood.atmosphere} (tension ${outline.mood.tension}/5)
Sensory: ${outline.mood.sensoryDetails.join(', ')}

Beats to expand:
${outline.beats.map((b) => `- [${b.role}] ${b.id}: ${b.intent}`).join('\n')}
${outcomeGuidance}
${optionsGuidance}

Write the full prose as JSON.`;
}

/**
 * Expand beat outline into full prose
 */
export async function expandBeatsToProse(params: {
  nodeId: string;
  nodeType: string;
  biome: string;
  name: string;
  themes: string[];
  entityTypes: string[];
  act?: number;
  outline: BeatOutline;
  nodeMetadata: any;
  temperature?: number;
}): Promise<ExpandedContent> {
  // Build context
  const context = await buildNodeContext({
    biome: params.biome,
    act: params.act,
    nodeType: params.nodeType,
    nodeId: params.nodeId,
    name: params.name,
    themes: params.themes,
    entityTypes: params.entityTypes,
  });

  // Build prompts
  const systemPrompt = await buildProseExpanderSystemPrompt();
  const userPrompt = createProseExpanderPrompt(context, params.outline, params.nodeMetadata);

  // Call LLM
  const result = await completeWithRetry({
    systemPrompt,
    userPrompt,
    temperature: params.temperature,
    responseFormat: 'json',
  });

  // Parse and return
  return parseJsonResponse<ExpandedContent>(result.content);
}
