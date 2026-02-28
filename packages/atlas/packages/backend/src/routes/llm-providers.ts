import { Hono } from 'hono';
import type { Context } from 'hono';
import { zValidator } from '@hono/zod-validator';
import { z } from 'zod';
import {
  LLMProviderConfigSchema,
  LLMProviderUpdateSchema,
  LLMProviderTestSchema,
  type LLMProviderConfig,
  type LLMProviderUpdate,
} from '@node-gen-web/shared';
import { db } from '../db/index.js';
import { llmProviders } from '../db/schema.js';
import { eq, ne, desc } from 'drizzle-orm';
import { encryptApiKey, decryptApiKey } from '../middleware/encryption.js';
import { testProviderConnection } from '../services/generation/llm-client.js';

const app = new Hono();

/**
 * GET /api/llm/providers
 * List all LLM providers (without decrypted API keys)
 */
app.get('/', async (c) => {
  try {
    const providers = await db.select().from(llmProviders).orderBy(desc(llmProviders.createdAt));

    // Remove encrypted API keys from response
    const sanitized = providers.map((p) => ({
      ...p,
      encryptedApiKey: undefined,
      hasApiKey: !!p.encryptedApiKey,
    }));

    return c.json(sanitized);
  } catch (error) {
    console.error('Error fetching providers:', error);
    return c.json(
      {
        error: error instanceof Error ? error.message : 'Failed to fetch providers',
      },
      500
    );
  }
});

/**
 * GET /api/llm/providers/ollama-models
 * Fetch available models from an Ollama server
 */
app.get('/ollama-models', async (c) => {
  const baseUrl = c.req.query('baseUrl');

  if (!baseUrl) {
    return c.json({ error: 'baseUrl query parameter is required' }, 400);
  }

  try {
    const url = `${baseUrl.replace(/\/+$/, '')}/api/tags`;
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 5000);

    const response = await fetch(url, { signal: controller.signal });
    clearTimeout(timeout);

    if (!response.ok) {
      return c.json({ error: `Ollama server returned ${response.status}` }, 502);
    }

    const data = (await response.json()) as { models?: Array<{ name: string }> };
    const models = (data.models || []).map((m) => m.name);

    return c.json({ models });
  } catch (error) {
    const message =
      error instanceof Error && error.name === 'AbortError'
        ? 'Ollama server did not respond within 5 seconds'
        : error instanceof Error
          ? error.message
          : 'Failed to fetch Ollama models';
    return c.json({ error: message }, 502);
  }
});

/**
 * GET /api/llm/providers/:id
 * Get a specific provider (without decrypted API key)
 */
app.get('/:id', async (c) => {
  const id = parseInt(c.req.param('id'));

  if (isNaN(id)) {
    return c.json({ error: 'Invalid provider ID' }, 400);
  }

  try {
    const provider = await db.select().from(llmProviders).where(eq(llmProviders.id, id)).limit(1);

    if (provider.length === 0) {
      return c.json({ error: 'Provider not found' }, 404);
    }

    // Remove encrypted API key from response
    const sanitized = {
      ...provider[0],
      encryptedApiKey: undefined,
      hasApiKey: !!provider[0].encryptedApiKey,
    };

    return c.json(sanitized);
  } catch (error) {
    console.error('Error fetching provider:', error);
    return c.json(
      {
        error: error instanceof Error ? error.message : 'Failed to fetch provider',
      },
      500
    );
  }
});

/**
 * POST /api/llm/providers
 * Create a new LLM provider
 */
app.post('/', zValidator('json', LLMProviderConfigSchema), async (c) => {
  const config = c.req.valid('json') as LLMProviderConfig;

  try {
    // Encrypt the API key if provided (Ollama doesn't need one)
    const encryptedKey = config.apiKey ? encryptApiKey(config.apiKey) : null;

    // If this provider is set as active, deactivate all others
    if (config.isActive) {
      await db.update(llmProviders).set({ isActive: false });
    }

    const [provider] = await db
      .insert(llmProviders)
      .values({
        name: config.name,
        type: config.type as any,
        baseUrl: config.baseUrl || null,
        encryptedApiKey: encryptedKey,
        model: config.model,
        temperature: config.temperature,
        maxRetries: config.maxRetries,
        isActive: config.isActive,
      })
      .returning();

    // Remove encrypted API key from response
    const sanitized = {
      ...provider,
      encryptedApiKey: undefined,
      hasApiKey: !!provider.encryptedApiKey,
    };

    return c.json(sanitized, 201);
  } catch (error) {
    console.error('Error creating provider:', error);
    return c.json(
      {
        error: error instanceof Error ? error.message : 'Failed to create provider',
      },
      500
    );
  }
});

/**
 * PUT /api/llm/providers/:id
 * Update an existing LLM provider
 */
app.put('/:id', zValidator('json', LLMProviderUpdateSchema), async (c) => {
  const id = parseInt(c.req.param('id'));
  const updates = c.req.valid('json') as LLMProviderUpdate;

  if (isNaN(id)) {
    return c.json({ error: 'Invalid provider ID' }, 400);
  }

  try {
    // Check if provider exists
    const existing = await db.select().from(llmProviders).where(eq(llmProviders.id, id)).limit(1);

    if (existing.length === 0) {
      return c.json({ error: 'Provider not found' }, 404);
    }

    // Build update object
    const updateData: any = {};

    if (updates.name !== undefined) updateData.name = updates.name;
    if (updates.baseUrl !== undefined) updateData.baseUrl = updates.baseUrl;
    if (updates.model !== undefined) updateData.model = updates.model;
    if (updates.temperature !== undefined) updateData.temperature = updates.temperature;
    if (updates.maxRetries !== undefined) updateData.maxRetries = updates.maxRetries;
    if (updates.isActive !== undefined) updateData.isActive = updates.isActive;

    // Encrypt API key if provided
    if (updates.apiKey) {
      updateData.encryptedApiKey = encryptApiKey(updates.apiKey);
    }

    updateData.updatedAt = new Date();

    // If setting as active, deactivate all others
    if (updates.isActive) {
      await db.update(llmProviders).set({ isActive: false }).where(ne(llmProviders.id, id));
    }

    const [provider] = await db
      .update(llmProviders)
      .set(updateData)
      .where(eq(llmProviders.id, id))
      .returning();

    // Remove encrypted API key from response
    const sanitized = {
      ...provider,
      encryptedApiKey: undefined,
      hasApiKey: !!provider.encryptedApiKey,
    };

    return c.json(sanitized);
  } catch (error) {
    console.error('Error updating provider:', error);
    return c.json(
      {
        error: error instanceof Error ? error.message : 'Failed to update provider',
      },
      500
    );
  }
});

/**
 * DELETE /api/llm/providers/:id
 * Delete an LLM provider
 */
app.delete('/:id', async (c) => {
  const id = parseInt(c.req.param('id'));

  if (isNaN(id)) {
    return c.json({ error: 'Invalid provider ID' }, 400);
  }

  try {
    const deleted = await db.delete(llmProviders).where(eq(llmProviders.id, id)).returning();

    if (deleted.length === 0) {
      return c.json({ error: 'Provider not found' }, 404);
    }

    return c.json({ success: true, message: 'Provider deleted' });
  } catch (error) {
    console.error('Error deleting provider:', error);
    return c.json(
      {
        error: error instanceof Error ? error.message : 'Failed to delete provider',
      },
      500
    );
  }
});

/**
 * POST /api/llm/test
 * Test an LLM provider connection
 * Exported as a standalone handler — registered directly on the main app in index.ts
 */
export async function handleTestProvider(c: Context) {
  const request = c.req.valid('json');

  try {
    let providerConfig;

    if (request.providerId) {
      // Test existing provider
      const [provider] = await db
        .select()
        .from(llmProviders)
        .where(eq(llmProviders.id, request.providerId))
        .limit(1);

      if (!provider) {
        return c.json({ error: 'Provider not found' }, 404);
      }

      providerConfig = {
        type: provider.type,
        baseUrl: provider.baseUrl,
        apiKey: provider.type === 'ollama' ? 'ollama' : decryptApiKey(provider.encryptedApiKey!),
        model: provider.model,
        temperature: provider.temperature,
        maxRetries: 1, // Use only 1 retry for testing
      };
    } else if (request.providerConfig) {
      // Test new configuration
      providerConfig = request.providerConfig;
    } else {
      return c.json({ error: 'Either providerId or providerConfig must be provided' }, 400);
    }

    const startTime = Date.now();

    // Try a simple completion with the provider config directly
    const result = await testProviderConnection({
      type: providerConfig.type,
      baseUrl: providerConfig.baseUrl,
      apiKey: providerConfig.apiKey,
      model: providerConfig.model,
      temperature: (providerConfig.temperature ?? 70) / 100, // Convert 0-100 to 0.0-1.0
    });

    const latency = Date.now() - startTime;

    return c.json({
      success: true,
      message: 'Provider connection successful',
      latency,
      model: providerConfig.model,
      response: result.content,
    });
  } catch (error) {
    console.error('Provider test error:', error);
    return c.json(
      {
        success: false,
        message: 'Provider connection failed',
        error: error instanceof Error ? error.message : 'Unknown error',
      },
      200 // Return 200 but with success: false
    );
  }
}

export default app;
