/**
 * Field-level generation endpoints
 * Generate individual fields (narrative_hook, beat, beat-list) without full 3-stage pipeline
 */

import { Hono } from 'hono';
import { zValidator } from '@hono/zod-validator';
import { z } from 'zod';
import OpenAI from 'openai';
import Anthropic from '@anthropic-ai/sdk';
import { getActiveProvider } from '../services/generation/llm-client.js';

// Helper to decrypt API key (from llm-client.ts)
function decryptApiKey(encryptedKey: string): string {
  return Buffer.from(encryptedKey, 'base64').toString('utf-8');
}

// SSE format helper
function formatSSE(type: string, data: any): string {
  return `data: ${JSON.stringify({ type, ...data })}\n\n`;
}

// Request schemas
const narrativeHookRequestSchema = z.object({
  nodeType: z.string(),
  biome: z.string(),
  name: z.string(),
  themes: z.array(z.string()),
  entityTypes: z.array(z.string()),
  act: z.number().optional(),
  nodeMetadata: z.record(z.any()).optional(),
});

const beatRequestSchema = z.object({
  nodeType: z.string(),
  biome: z.string(),
  role: z.string(),
  context: z.string().optional(),
  narrativeHook: z.string().optional(),
  existingBeats: z.array(z.any()).optional(),
});

const beatListRequestSchema = z.object({
  nodeType: z.string(),
  biome: z.string(),
  name: z.string(),
  themes: z.array(z.string()),
  narrativeHook: z.string().optional(),
});

const router = new Hono();

/**
 * POST /narrative-hook
 * Generate narrative hook text (1-3 sentences) - STREAMING
 */
router.post('/narrative-hook', zValidator('json', narrativeHookRequestSchema), async (c) => {
  const body = c.req.valid('json');

  // Get active provider
  const provider = await getActiveProvider();
  if (!provider) {
    return c.json({ error: 'No LLM provider configured' }, 500);
  }

  // Set SSE headers
  c.header('Content-Type', 'text/event-stream');
  c.header('Cache-Control', 'no-cache');
  c.header('Connection', 'keep-alive');

  const encoder = new TextEncoder();
  const apiKey = decryptApiKey(provider.encryptedApiKey!);

  const systemPrompt = `You are a narrative writer for an Australian Gold Rush cosmic horror game.

Write a compelling narrative hook: 1-3 sentences that open this ${body.nodeType} node.

Biome: ${body.biome}
Themes: ${body.themes.join(', ') || 'frontier survival'}
Act: ${body.act || 1}

Setting: 1850s Australian goldfields during a rush that has uncovered something ancient and wrong beneath the earth. The tone blends historical grit with creeping cosmic dread.

Write in second person present tense. Be concise, evocative, sensory-rich.
Return only the narrative hook text (20-500 characters), no JSON or metadata.`;

  const userPrompt = `Write the narrative hook for: "${body.name}"

Node type: ${body.nodeType}
Entity types: ${body.entityTypes.join(', ') || 'none specified'}`;

  const stream = new ReadableStream({
    async start(controller) {
      try {
        let fullText = '';

        if (provider.type === 'anthropic') {
          const client = new Anthropic({ apiKey });
          const response = await client.messages.create({
            model: provider.model,
            max_tokens: 256,
            temperature: provider.temperature / 100,
            stream: true, // <-- STREAMING FLAG
            system: systemPrompt,
            messages: [{ role: 'user', content: userPrompt }],
          });

          // Anthropic streaming uses async iteration
          for await (const event of response) {
            if (event.type === 'content_block_delta' && event.delta.type === 'text_delta') {
              const token = event.delta.text;
              fullText += token;
              controller.enqueue(encoder.encode(formatSSE('token', { content: token })));
            }
          }
        } else {
          // OpenAI/OpenRouter
          const client = new OpenAI({
            apiKey,
            baseURL: provider.baseUrl || undefined,
            defaultHeaders:
              provider.type === 'openrouter'
                ? {
                    'HTTP-Referer': 'https://github.com/node-gen-web',
                    'X-Title': 'Node Gen Web',
                  }
                : undefined,
          });

          const response = await client.chat.completions.create({
            model: provider.model,
            temperature: provider.temperature / 100,
            max_tokens: 256,
            stream: true, // <-- STREAMING FLAG
            messages: [
              { role: 'system', content: systemPrompt },
              { role: 'user', content: userPrompt },
            ],
          });

          // OpenAI streaming uses async iteration
          for await (const chunk of response) {
            const token = chunk.choices[0]?.delta?.content;
            if (token) {
              fullText += token;
              controller.enqueue(encoder.encode(formatSSE('token', { content: token })));
            }
          }
        }

        // Send done event with complete text
        controller.enqueue(encoder.encode(formatSSE('done', { content: fullText })));
        controller.close();
      } catch (error) {
        const message = error instanceof Error ? error.message : 'Generation failed';
        controller.enqueue(encoder.encode(formatSSE('error', { error: message })));
        controller.close();
      }
    },
  });

  return new Response(stream);
});

/**
 * POST /beat
 * Generate single story beat text (50-150 chars) - STREAMING
 */
router.post('/beat', zValidator('json', beatRequestSchema), async (c) => {
  const body = c.req.valid('json');

  // Get active provider
  const provider = await getActiveProvider();
  if (!provider) {
    return c.json({ error: 'No LLM provider configured' }, 500);
  }

  // Set SSE headers
  c.header('Content-Type', 'text/event-stream');
  c.header('Cache-Control', 'no-cache');
  c.header('Connection', 'keep-alive');

  const encoder = new TextEncoder();
  const apiKey = decryptApiKey(provider.encryptedApiKey!);

  // Beat role guidance
  const roleGuidance: Record<string, string> = {
    setup: 'Establish the scene and situation. What the player sees/hears/feels initially.',
    escalation: 'Raise the stakes. Situation becomes more intense or complex.',
    reveal: 'Key information or twist revealed. Changes player understanding.',
    choice: 'Present the decision point. Frame the dilemma clearly.',
    consequence: 'Show immediate result of player choice. Cause and effect.',
    button: 'Closing line after player clicks to continue. Transition or reflection.',
    tension: 'Build unease or anticipation. Something feels wrong.',
    relief: 'Moment of calm or respite. Tension temporarily eases.',
    foreshadow: 'Hint at future events. Plant seeds for later payoff.',
    reflection: 'Character contemplates what happened. Internal processing.',
  };

  const systemPrompt = `You are a narrative writer for an Australian Gold Rush cosmic horror game.

Write a single story beat for a ${body.nodeType} node.

Beat role: ${body.role} - ${roleGuidance[body.role] || 'narrative progression'}
Biome: ${body.biome}
${body.narrativeHook ? `Narrative hook: ${body.narrativeHook}` : ''}
${body.context ? `Additional context: ${body.context}` : ''}

Write 50-150 characters of evocative prose in second person present tense.
Focus on sensory details and atmosphere appropriate to the beat role.
Return only the beat text, no JSON or metadata.`;

  const userPrompt = `Write the ${body.role} beat.`;

  const stream = new ReadableStream({
    async start(controller) {
      try {
        let fullText = '';

        if (provider.type === 'anthropic') {
          const client = new Anthropic({ apiKey });
          const response = await client.messages.create({
            model: provider.model,
            max_tokens: 200,
            temperature: provider.temperature / 100,
            stream: true,
            system: systemPrompt,
            messages: [{ role: 'user', content: userPrompt }],
          });

          for await (const event of response) {
            if (event.type === 'content_block_delta' && event.delta.type === 'text_delta') {
              const token = event.delta.text;
              fullText += token;
              controller.enqueue(encoder.encode(formatSSE('token', { content: token })));
            }
          }
        } else {
          const client = new OpenAI({
            apiKey,
            baseURL: provider.baseUrl || undefined,
            defaultHeaders:
              provider.type === 'openrouter'
                ? {
                    'HTTP-Referer': 'https://github.com/node-gen-web',
                    'X-Title': 'Node Gen Web',
                  }
                : undefined,
          });

          const response = await client.chat.completions.create({
            model: provider.model,
            temperature: provider.temperature / 100,
            max_tokens: 200,
            stream: true,
            messages: [
              { role: 'system', content: systemPrompt },
              { role: 'user', content: userPrompt },
            ],
          });

          for await (const chunk of response) {
            const token = chunk.choices[0]?.delta?.content;
            if (token) {
              fullText += token;
              controller.enqueue(encoder.encode(formatSSE('token', { content: token })));
            }
          }
        }

        controller.enqueue(encoder.encode(formatSSE('done', { content: fullText })));
        controller.close();
      } catch (error) {
        const message = error instanceof Error ? error.message : 'Generation failed';
        controller.enqueue(encoder.encode(formatSSE('error', { error: message })));
        controller.close();
      }
    },
  });

  return new Response(stream);
});

/**
 * POST /beat-list
 * Generate beat outline suggestions (3-5 beats) - NON-STREAMING
 */
router.post('/beat-list', zValidator('json', beatListRequestSchema), async (c) => {
  const body = c.req.valid('json');

  // Get active provider
  const provider = await getActiveProvider();
  if (!provider) {
    return c.json({ error: 'No LLM provider configured' }, 500);
  }

  const apiKey = decryptApiKey(provider.encryptedApiKey!);

  // Beat sequence templates by node type
  const beatSequences: Record<string, string> = {
    combat: 'setup (establish threat), escalation (combat intensifies), reveal (enemy nature/weakness)',
    choice: 'setup (present situation), tension (stakes become clear), choice (frame the dilemma)',
    state_check: 'setup (scene), button (quick transition)',
    trade: 'setup (merchant intro), escalation (negotiation), button (trade outcome)',
    passage: 'setup (travel begins), tension or relief (journey event), button (arrival)',
    rest: 'setup (make camp), relief (rest activities), tension or foreshadow (optional interruption)',
    transition: 'reflection (past act), foreshadow (future act), button (transition)',
  };

  const sequenceTemplate = beatSequences[body.nodeType] || 'setup, escalation, button';

  const systemPrompt = `You are a narrative structure designer for an Australian Gold Rush cosmic horror game.

Generate a beat outline for a ${body.nodeType} node.

Suggested beat sequence: ${sequenceTemplate}

Node name: ${body.name}
Biome: ${body.biome}
Themes: ${body.themes.join(', ') || 'frontier survival'}
${body.narrativeHook ? `Narrative hook: ${body.narrativeHook}` : ''}

Return a JSON array of beat outlines. Each beat should have:
- id: unique identifier (e.g., "beat_1")
- role: beat role (setup, escalation, reveal, choice, consequence, button, tension, relief, foreshadow, reflection)
- text: brief description of what happens in this beat (10-30 words)

Example:
[
  { "id": "beat_1", "role": "setup", "text": "You encounter a prospector's abandoned camp. Something fled in panic." },
  { "id": "beat_2", "role": "tension", "text": "Strange symbols carved in the dirt. They seem to writhe in peripheral vision." },
  { "id": "beat_3", "role": "button", "text": "You decide whether to investigate or move on quickly." }
]

Return ONLY the JSON array, no markdown formatting.`;

  const userPrompt = `Generate beat outline for: "${body.name}"`;

  try {
    let content = '';

    if (provider.type === 'anthropic') {
      const client = new Anthropic({ apiKey });
      const response = await client.messages.create({
        model: provider.model,
        max_tokens: 1024,
        temperature: provider.temperature / 100,
        system: systemPrompt,
        messages: [{ role: 'user', content: userPrompt }],
      });

      content = response.content[0]?.type === 'text' ? response.content[0].text : '';
    } else {
      const client = new OpenAI({
        apiKey,
        baseURL: provider.baseUrl || undefined,
        defaultHeaders:
          provider.type === 'openrouter'
            ? {
                'HTTP-Referer': 'https://github.com/node-gen-web',
                'X-Title': 'Node Gen Web',
              }
            : undefined,
      });

      const response = await client.chat.completions.create({
        model: provider.model,
        temperature: provider.temperature / 100,
        max_tokens: 1024,
        messages: [
          { role: 'system', content: systemPrompt },
          { role: 'user', content: userPrompt },
        ],
      });

      content = response.choices[0]?.message?.content ?? '';
    }

    // Parse JSON response (handle markdown code blocks if present)
    const jsonMatch = content.match(/```(?:json)?\s*([\s\S]*?)```/);
    const jsonStr = jsonMatch ? jsonMatch[1].trim() : content.trim();

    let beats;
    try {
      beats = JSON.parse(jsonStr);
    } catch (parseError) {
      console.error('Failed to parse beat list JSON:', content);
      return c.json({ error: 'Failed to parse beat suggestions' }, 500);
    }

    return c.json({ beats });
  } catch (error) {
    console.error('Beat list generation error:', error);
    return c.json(
      { error: error instanceof Error ? error.message : 'Beat list generation failed' },
      500
    );
  }
});

export default router;
