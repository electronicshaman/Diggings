/**
 * Utility for building prompts with database-backed configuration
 * Loads biome tones, style guides, and act tones from database
 */

import { db } from '../../db/index.js';
import { styleGuide, actTones, vernacular } from '../../db/schema.js';
import { eq } from 'drizzle-orm';

export interface BiomeTone {
  atmosphere: string;
  sensoryDetails: string[];
  dangers: string[];
  voiceNotes: string;
  antipatterns: string[];
}

export interface ActTone {
  act: number;
  toneName: string;
  description: string;
  sensoryPalette: string[];
}

/**
 * Get biome tone data from database
 */
export async function getBiomeTone(biome: string): Promise<BiomeTone | null> {
  const [guide] = await db.select().from(styleGuide).where(eq(styleGuide.biome, biome as any));

  if (!guide) {
    return null;
  }

  return {
    atmosphere: guide.atmosphere || '',
    sensoryDetails: (guide.sensoryDetails as string[]) || [],
    dangers: (guide.dangers as string[]) || [],
    voiceNotes: guide.voiceNotes || '',
    antipatterns: (guide.antipatterns as string[]) || [],
  };
}

/**
 * Get act tone data from database
 */
export async function getActTone(act: number): Promise<ActTone | null> {
  const [tone] = await db.select().from(actTones).where(eq(actTones.act, act));

  if (!tone) {
    return null;
  }

  return {
    act: tone.act,
    toneName: tone.toneName,
    description: tone.description || '',
    sensoryPalette: (tone.sensoryPalette as string[]) || [],
  };
}

/**
 * Format biome tone for prompt injection (~50 tokens)
 */
export function formatBiomeToneForPrompt(tone: BiomeTone, biomeName: string): string {
  return `Biome (${biomeName}): ${tone.atmosphere}
Sensory: ${tone.sensoryDetails.slice(0, 3).join(', ')}
Voice: ${tone.voiceNotes}`;
}

/**
 * Format anti-patterns for critic prompt (~30 tokens)
 */
export function formatAntipatternsForPrompt(tone: BiomeTone): string {
  const patterns = tone.antipatterns.slice(0, 6);
  return `Avoid: ${patterns.join(', ')}`;
}

/**
 * Format act tone for prompt injection
 */
export function formatActToneForPrompt(tone: ActTone): string {
  return `Act ${tone.act} (${tone.toneName}):
- Tone: ${tone.description}
- Sensory Palette: ${tone.sensoryPalette.join(', ')}`;
}

/**
 * Get vernacular hint for prompts from database
 */
export async function getVernacularHint(): Promise<string> {
  try {
    const terms = await db.select().from(vernacular).orderBy(vernacular.sortOrder);

    if (terms.length > 0) {
      const termPairs = terms.map((t) => `"${t.term}"${t.definition ? ` (${t.definition})` : ''}`);
      return `\nVocabulary: ${termPairs.join(', ')}\n`;
    }
  } catch {
    // Fall through to default
  }

  // Fallback if no terms in database
  return `
Vocabulary: "digger" not miner, "colour" for gold flakes, "duffer" for failed claim,
"new chum" for newcomer, "old hand" for veteran, "sly grog" for illegal liquor,
"troopers" for police, "publican" for bartender, "mullock" for waste rock.
`;
}

/**
 * Get exemplar hint for critic prompts
 */
export function getExemplarHint(): string {
  return `
Good prose: "The publican's smile doesn't reach his eyes. His hands stay below the bar."
Bad prose: "The innkeeper looks suspicious and might be hiding something."
Rule: Show through concrete detail, don't tell through summary.
`;
}

/**
 * Build context object for a node generation
 */
export interface NodeGenerationContext {
  biome: string;
  biomeTone: BiomeTone | null;
  act?: number;
  actTone: ActTone | null;
  nodeType: string;
  nodeId: string;
  name: string;
  themes: string[];
  entityTypes: string[];
}

export async function buildNodeContext(params: {
  biome: string;
  act?: number;
  nodeType: string;
  nodeId: string;
  name: string;
  themes: string[];
  entityTypes: string[];
}): Promise<NodeGenerationContext> {
  const biomeTone = await getBiomeTone(params.biome);
  const actTone = params.act ? await getActTone(params.act) : null;

  return {
    biome: params.biome,
    biomeTone,
    act: params.act,
    actTone,
    nodeType: params.nodeType,
    nodeId: params.nodeId,
    name: params.name,
    themes: params.themes,
    entityTypes: params.entityTypes,
  };
}
