/**
 * Critic - Third generation stage
 * Evaluates generated content quality and provides repair instructions
 */

import { completeWithRetry, parseJsonResponse } from './llm-client.js';
import {
  buildNodeContext,
  formatAntipatternsForPrompt,
  getExemplarHint,
  type NodeGenerationContext,
} from './prompt-builder.js';
import type { ExpandedContent } from './prose-expander.js';

// System prompt - TODO: Move to shared constants in Phase 4
export const CRITIC_SYSTEM_PROMPT = `You are a narrative quality critic for an Australian Gold Rush cosmic horror game.

Your task is to evaluate generated content and provide a pass/fail judgment with specific feedback.

## Evaluation Criteria

### Required (Fail if not met)
1. Beat sequence completeness - All required beats present
2. Text length bounds - Each beat 10-150 characters
3. Tone alignment - Matches act-appropriate mood
4. Historical authenticity - 1850s Australian Gold Rush setting
5. No clichés - Avoid generic horror tropes

### Quality Factors (Contribute to score)
1. Sensory richness - Uses sight, sound, smell, touch
2. Stakes clarity - Player understands what's at risk
3. Emotional impact - Beats feel meaningful
4. Pacing - Tension builds appropriately
5. Distinctiveness - Feels unique, not repetitive
6. Show don't tell - Concrete details imply meaning

${getExemplarHint()}

## Output Format
Return valid JSON:
{
  "pass": true/false,
  "score": 0-100,
  "issues": [
    {
      "severity": "critical|major|minor",
      "category": "completeness|length|tone|authenticity|cliche|quality",
      "description": "Specific issue description",
      "beatId": "affected_beat_id or null",
      "suggestion": "How to fix"
    }
  ],
  "strengths": ["What works well"],
  "repairInstructions": "If fail, specific instructions to fix" or null
}

## Rules
- Be constructive, not harsh
- Critical issues = automatic fail
- Score 70+ required for pass
- Provide actionable feedback
- Note what works, not just problems`;

export interface CriticIssue {
  severity: 'critical' | 'major' | 'minor';
  category: 'completeness' | 'length' | 'tone' | 'authenticity' | 'cliche' | 'quality';
  description: string;
  beatId: string | null;
  suggestion: string;
}

export interface CriticResult {
  pass: boolean;
  score: number;
  issues: CriticIssue[];
  strengths: string[];
  repairInstructions: string | null;
}

/**
 * Build critic prompt
 */
function createCriticPrompt(
  context: NodeGenerationContext,
  content: ExpandedContent,
  nodeMetadata: any
): string {
  const actContext = context.actTone
    ? `Expected tone for Act ${context.act} (${context.actTone.toneName}): ${context.actTone.description}`
    : '';

  const antipatterns = context.biomeTone
    ? formatAntipatternsForPrompt(context.biomeTone)
    : 'Avoid: generic horror tropes, clichés';

  return `Evaluate this generated content:

${antipatterns}

Node: ${context.nodeId} (${context.nodeType})
Biome: ${context.biome}
Themes: ${context.themes.join(', ')}
${actContext}

## Generated Content

Narrative Hook:
"${content.narrative_hook}"

Beats:
${content.beats.map((b) => `- [${b.role}] ${b.id}: "${b.text}" (${b.text.length} chars)`).join('\n')}

${content.outcomes ? `Outcomes:\n${JSON.stringify(content.outcomes, null, 2)}` : ''}
${content.options ? `Options:\n${JSON.stringify(content.options, null, 2)}` : ''}

Evaluate and return JSON.`;
}

/**
 * Evaluate generated content
 */
export async function evaluateContent(params: {
  nodeId: string;
  nodeType: string;
  biome: string;
  name: string;
  themes: string[];
  entityTypes: string[];
  act?: number;
  content: ExpandedContent;
  nodeMetadata: any;
  temperature?: number;
}): Promise<CriticResult> {
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

  // Build prompt
  const userPrompt = createCriticPrompt(context, params.content, params.nodeMetadata);

  // Call LLM
  const result = await completeWithRetry({
    systemPrompt: CRITIC_SYSTEM_PROMPT,
    userPrompt,
    temperature: params.temperature ?? 0.3, // Lower temperature for more consistent evaluation
    responseFormat: 'json',
  });

  // Parse and return
  return parseJsonResponse<CriticResult>(result.content);
}
