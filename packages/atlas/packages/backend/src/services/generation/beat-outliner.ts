/**
 * Beat outliner - First generation stage
 * Creates beat structure outlines from node metadata
 */

import { completeWithRetry, parseJsonResponse } from './llm-client.js';
import {
  buildNodeContext,
  formatBiomeToneForPrompt,
  formatActToneForPrompt,
  type NodeGenerationContext,
} from './prompt-builder.js';
import { db } from '../../db/index.js';
import { beatSequences } from '../../db/schema.js';
import { eq } from 'drizzle-orm';

// System prompts - TODO: Move to shared constants in Phase 4
export const BEAT_OUTLINER_SYSTEM_PROMPT = `You are a narrative beat outliner for an Australian Gold Rush horror game set in the 1850s.

Your task is to create a beat structure (outline) for narrative nodes. You will receive node metadata and must output a structured beat sheet.

## Setting Context
- 1850s Australian Gold Rush
- Cosmic horror elements emerge as the story progresses
- Indigenous Australian spirituality respected (not appropriated)
- Historical authenticity with supernatural undertones

## Output Format
Return valid JSON with this structure:
{
  "narrative_hook": "Brief 1-sentence description of the encounter",
  "beats": [
    {
      "id": "unique_beat_id",
      "role": "setup|escalation|reveal|choice|consequence|button|tension|relief|foreshadow|reflection",
      "intent": "What this beat accomplishes narratively"
    }
  ],
  "mood": {
    "tension": 1-5,
    "atmosphere": "single word or short phrase",
    "sensoryDetails": ["detail1", "detail2", "detail3"]
  }
}

## Beat Roles
Core roles:
- setup: Environmental context, character/threat introduction
- escalation: Tension increases, stakes raised
- reveal: Information disclosed, twist revealed
- choice: Player decision point
- consequence: Result of action/choice
- button: Final beat, transition prompt ("Continue...", "Move on...")

Extended roles:
- tension: Sustained unease without escalation (dread builds slowly)
- relief: Brief respite, false calm before storm
- foreshadow: Hint at future events, ominous environmental signs
- reflection: Character/player processing moment, introspection

## Rules
- Each beat must advance the narrative
- Setup always comes first
- Choices require clear stakes
- Consequences must feel meaningful
- Maintain tone appropriate to act (hopeful early, dread late)
- 2-4 beats per node typically
- Be specific to the node's biome and themes
- Follow the provided beat structure closely when one is specified`;

export interface BeatTemplate {
  role: string;
  intent: string;
  required: boolean;
}

export interface BeatSequence {
  id: string;
  nodeType: string;
  sequenceKey: string;
  beatStructure: BeatTemplate[];
  weight: number;
  actConstraints?: number[];
  requiredTags?: string[];
}

export interface BeatOutline {
  narrative_hook: string;
  beats: Array<{
    id: string;
    role: string;
    intent: string;
  }>;
  mood: {
    tension: 1 | 2 | 3 | 4 | 5;
    atmosphere: string;
    sensoryDetails: string[];
  };
}

/**
 * Get beat sequences for a node type from database
 */
async function getBeatSequences(nodeType: string): Promise<BeatSequence[]> {
  const sequences = await db.select().from(beatSequences).where(eq(beatSequences.nodeType, nodeType as any));

  return sequences.map((seq) => ({
    id: seq.id.toString(),
    nodeType: seq.nodeType,
    sequenceKey: seq.sequenceKey,
    beatStructure: seq.beatStructure as BeatTemplate[],
    weight: seq.weight || 1,
    actConstraints: seq.actConstraints as number[] | undefined,
    requiredTags: seq.requiredTags as string[] | undefined,
  }));
}

/**
 * Select a beat sequence for the node
 * Uses weight-based random selection with act/tag filtering
 */
function selectBeatSequence(
  sequences: BeatSequence[],
  act?: number,
  tags: string[] = []
): BeatSequence | null {
  // Filter by act constraints
  let eligible = sequences.filter((seq) => {
    if (seq.actConstraints && act) {
      return seq.actConstraints.includes(act);
    }
    return true;
  });

  // Filter by required tags
  eligible = eligible.filter((seq) => {
    if (seq.requiredTags && seq.requiredTags.length > 0) {
      return seq.requiredTags.some((tag) => tags.includes(tag));
    }
    return true;
  });

  if (eligible.length === 0) {
    return null;
  }

  // Weight-based random selection
  const totalWeight = eligible.reduce((sum, seq) => sum + seq.weight, 0);
  let random = Math.random() * totalWeight;

  for (const seq of eligible) {
    random -= seq.weight;
    if (random <= 0) {
      return seq;
    }
  }

  return eligible[0];
}

/**
 * Build beat outliner prompt for a node
 */
function createBeatOutlinerPrompt(
  context: NodeGenerationContext,
  nodeMetadata: any,
  selectedSequence?: BeatSequence
): string {
  let nodeSpecificContext = '';

  // Add type-specific context based on node type
  switch (context.nodeType) {
    case 'combat':
      nodeSpecificContext = `
Enemy Type Hooks: ${nodeMetadata.enemyTypeHooks?.join(', ') || 'none'}
Environmental Context: ${nodeMetadata.environmentalContext || 'none'}
Combat Difficulty: ${nodeMetadata.estimatedCombatDifficulty || 'unknown'}/5`;
      break;
    case 'choice':
      nodeSpecificContext = `
Dilemma Type: ${nodeMetadata.dilemmaType || 'unknown'}
Consequence Hooks: ${nodeMetadata.consequenceHooks?.join(', ') || 'none'}`;
      break;
    case 'trade':
      nodeSpecificContext = `
Trader Archetype: ${nodeMetadata.traderArchetype || 'unknown'}
Pricing Hooks: ${nodeMetadata.pricingHooks?.join(', ') || 'none'}`;
      break;
    case 'rest':
      nodeSpecificContext = `
Rest Type: ${nodeMetadata.restType || 'unknown'}
Interruption Chance: ${nodeMetadata.interruptionChance || 'unknown'}
Dream Hooks: ${nodeMetadata.dreamHooks?.join(', ') || 'none'}`;
      break;
    case 'passage':
      nodeSpecificContext = `
Travel Event Hooks: ${nodeMetadata.travelEventHooks?.join(', ') || 'none'}
Environmental Storytelling: ${nodeMetadata.environmentalStorytelling || 'none'}`;
      break;
    case 'transition':
      nodeSpecificContext = `
Narrative Summary: ${nodeMetadata.narrativeSummary || 'none'}
World State Shifts: ${nodeMetadata.worldStateShifts?.join(', ') || 'none'}
Act Change Trigger: ${nodeMetadata.actChangeTrigger || 'none'}`;
      break;
  }

  // Build beat structure guide
  let beatTemplateGuide = '';
  if (selectedSequence) {
    beatTemplateGuide = `\nBeat Structure (${selectedSequence.sequenceKey}):\n${selectedSequence.beatStructure
      .map((b) => `- ${b.role}: ${b.intent}${b.required ? ' (required)' : ' (optional)'}`)
      .join('\n')}`;
  }

  const biomeContext = context.biomeTone
    ? formatBiomeToneForPrompt(context.biomeTone, context.biome)
    : `Biome: ${context.biome}`;

  const actContext = context.actTone ? formatActToneForPrompt(context.actTone) : '';

  return `Create a beat outline for this narrative node:

${biomeContext}

Node ID: ${context.nodeId}
Type: ${context.nodeType}
Biome: ${context.biome}
Name: ${context.name}
Themes: ${context.themes.join(', ')}
Entity Types: ${context.entityTypes.join(', ')}
${nodeSpecificContext}
${actContext}
${beatTemplateGuide}

Generate the beat outline as JSON.`;
}

/**
 * Generate beat outline for a node
 */
export async function generateBeatOutline(params: {
  nodeId: string;
  nodeType: string;
  biome: string;
  name: string;
  themes: string[];
  entityTypes: string[];
  act?: number;
  nodeMetadata: any;
  temperature?: number;
}): Promise<BeatOutline> {
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

  // Get and select beat sequence
  const sequences = await getBeatSequences(params.nodeType);
  const selectedSequence = selectBeatSequence(sequences, params.act, params.themes);

  // Build prompt
  const userPrompt = createBeatOutlinerPrompt(context, params.nodeMetadata, selectedSequence || undefined);

  // Call LLM
  const result = await completeWithRetry({
    systemPrompt: BEAT_OUTLINER_SYSTEM_PROMPT,
    userPrompt,
    temperature: params.temperature,
    responseFormat: 'json',
  });

  // Parse and return
  return parseJsonResponse<BeatOutline>(result.content);
}
