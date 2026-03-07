/**
 * Multi-provider LLM client for content generation
 * Supports OpenAI, OpenRouter, and Anthropic providers
 */

import OpenAI from 'openai';
import Anthropic from '@anthropic-ai/sdk';
import { db } from '../../db/index.js';
import { llmProviders, generationSettings } from '../../db/schema.js';
import { eq } from 'drizzle-orm';
import { completeWithCircuitBreaker } from './circuit-breaker.js';
import { classifyLLMError, calculateRetryDelay } from './error-handler.js';

// Provider types
export type LLMProviderType = 'openai' | 'openrouter' | 'anthropic';

export interface LLMProvider {
  id: number;
  name: string;
  type: LLMProviderType;
  baseUrl: string | null;
  encryptedApiKey: string | null;
  model: string;
  temperature: number;
  maxRetries: number;
  isActive: boolean;
}

export interface LLMCompletionOptions {
  systemPrompt: string;
  userPrompt: string;
  temperature?: number;
  maxTokens?: number;
  responseFormat?: 'text' | 'json';
}

export interface LLMExplicitProviderConfig {
  type: LLMProviderType;
  baseUrl: string | null | undefined;
  apiKey: string;
  model: string;
}

export interface LLMCompletionResult {
  content: string;
  usage?: {
    promptTokens: number;
    completionTokens: number;
    totalTokens: number;
  };
}

/**
 * Simple base64 encryption/decryption for API keys
 * TODO: Replace with proper encryption (e.g., AES-256)
 */
function encryptApiKey(apiKey: string): string {
  return Buffer.from(apiKey).toString('base64');
}

function decryptApiKey(encryptedKey: string): string {
  return Buffer.from(encryptedKey, 'base64').toString('utf-8');
}

/**
 * Get the active LLM provider from the database
 */
export async function getActiveProvider(): Promise<LLMProvider | null> {
  const providers = await db.select().from(llmProviders).where(eq(llmProviders.isActive, true));

  if (providers.length === 0) {
    return null;
  }

  return providers[0] as LLMProvider;
}

/**
 * Create an OpenAI-compatible client for the given provider
 */
function createOpenAIClient(provider: LLMProvider): OpenAI {
  if (!provider.encryptedApiKey) {
    throw new Error(`Provider ${provider.name} has no API key configured`);
  }

  const apiKey = decryptApiKey(provider.encryptedApiKey);

  return new OpenAI({
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
}

/**
 * Create an Anthropic client for the given provider
 */
function createAnthropicClient(provider: LLMProvider): Anthropic {
  if (!provider.encryptedApiKey) {
    throw new Error(`Provider ${provider.name} has no API key configured`);
  }

  const apiKey = decryptApiKey(provider.encryptedApiKey);

  return new Anthropic({
    apiKey,
  });
}

/**
 * Complete an LLM request using the active provider
 */
export async function complete(options: LLMCompletionOptions): Promise<LLMCompletionResult> {
  const provider = await getActiveProvider();

  if (!provider) {
    throw new Error('No active LLM provider configured. Please configure a provider in settings.');
  }

  // Get generation settings for defaults
  const settings = await db.select().from(generationSettings);
  const defaultSettings = settings[0];

  const temperature = options.temperature ?? (provider.temperature / 100);
  const maxTokens = options.maxTokens ?? 2048;

  if (provider.type === 'anthropic') {
    const client = createAnthropicClient(provider);

    const response = await client.messages.create({
      model: provider.model,
      max_tokens: maxTokens,
      temperature,
      system: options.systemPrompt,
      messages: [
        {
          role: 'user',
          content: options.userPrompt,
        },
      ],
    });

    const content = response.content[0]?.type === 'text' ? response.content[0].text : '';

    return {
      content,
      usage: {
        promptTokens: response.usage.input_tokens,
        completionTokens: response.usage.output_tokens,
        totalTokens: response.usage.input_tokens + response.usage.output_tokens,
      },
    };
  } else {
    // OpenAI and OpenRouter use the same API
    const client = createOpenAIClient(provider);

    const response = await client.chat.completions.create({
      model: provider.model,
      temperature,
      max_tokens: maxTokens,
      response_format: options.responseFormat === 'json' ? { type: 'json_object' } : undefined,
      messages: [
        { role: 'system', content: options.systemPrompt },
        { role: 'user', content: options.userPrompt },
      ],
    });

    const content = response.choices[0]?.message?.content ?? '';

    return {
      content,
      usage: response.usage
        ? {
            promptTokens: response.usage.prompt_tokens,
            completionTokens: response.usage.completion_tokens,
            totalTokens: response.usage.total_tokens,
          }
        : undefined,
    };
  }
}

/**
 * Complete an LLM request using an explicitly-provided provider config (no DB lookup)
 */
export async function completeWithExplicitProvider(
  provider: LLMExplicitProviderConfig,
  options: LLMCompletionOptions
): Promise<LLMCompletionResult> {
  const temperature = options.temperature ?? 0.7;
  const maxTokens = options.maxTokens ?? 2048;

  if (provider.type === 'anthropic') {
    const client = new Anthropic({ apiKey: provider.apiKey });
    const response = await client.messages.create({
      model: provider.model,
      max_tokens: maxTokens,
      temperature,
      system: options.systemPrompt,
      messages: [{ role: 'user', content: options.userPrompt }],
    });
    const content = response.content[0]?.type === 'text' ? response.content[0].text : '';
    return {
      content,
      usage: {
        promptTokens: response.usage.input_tokens,
        completionTokens: response.usage.output_tokens,
        totalTokens: response.usage.input_tokens + response.usage.output_tokens,
      },
    };
  } else {
    const client = new OpenAI({
      apiKey: provider.apiKey,
      baseURL: provider.baseUrl || undefined,
      defaultHeaders:
        provider.type === 'openrouter'
          ? { 'HTTP-Referer': 'https://github.com/node-gen-web', 'X-Title': 'Node Gen Web' }
          : undefined,
    });
    const response = await client.chat.completions.create({
      model: provider.model,
      temperature,
      max_tokens: maxTokens,
      response_format: options.responseFormat === 'json' ? { type: 'json_object' } : undefined,
      messages: [
        { role: 'system', content: options.systemPrompt },
        { role: 'user', content: options.userPrompt },
      ],
    });
    const content = response.choices[0]?.message?.content ?? '';
    return {
      content,
      usage: response.usage
        ? {
            promptTokens: response.usage.prompt_tokens,
            completionTokens: response.usage.completion_tokens,
            totalTokens: response.usage.total_tokens,
          }
        : undefined,
    };
  }
}

/**
 * Complete an LLM request with exponential backoff retry logic
 */
export async function completeWithRetry(
  options: LLMCompletionOptions,
  maxRetries?: number
): Promise<LLMCompletionResult> {
  const provider = await getActiveProvider();

  if (!provider) {
    throw new Error('No active LLM provider configured');
  }

  const retries = maxRetries ?? provider.maxRetries;
  let lastError: Error | null = null;

  for (let attempt = 0; attempt <= retries; attempt++) {
    try {
      return await completeWithCircuitBreaker(options);
    } catch (error) {
      lastError = error instanceof Error ? error : new Error(String(error));
      const classified = classifyLLMError(lastError);

      // Don't retry non-retryable errors
      if (!classified.retryable) {
        throw lastError;
      }

      // Log retry attempt
      console.log(`[LLM Retry] Attempt ${attempt + 1}/${retries + 1}: ${classified.userMessage}`);

      // Wait with exponential backoff + jitter before next attempt
      if (attempt < retries) {
        const delay = calculateRetryDelay(attempt);
        await new Promise((resolve) => setTimeout(resolve, delay));
      }
    }
  }

  throw lastError ?? new Error('LLM completion failed after retries');
}

/**
 * Parse JSON response from LLM, handling markdown code blocks
 */
export function parseJsonResponse<T>(content: string): T {
  // Try to extract JSON from markdown code blocks if present
  const jsonMatch = content.match(/```(?:json)?\s*([\s\S]*?)```/);
  const jsonStr = jsonMatch ? jsonMatch[1].trim() : content.trim();

  try {
    return JSON.parse(jsonStr) as T;
  } catch (error) {
    throw new Error(`Failed to parse LLM response as JSON: ${error instanceof Error ? error.message : String(error)}`);
  }
}

/**
 * Utility function to encrypt API key (for use in API routes)
 */
export { encryptApiKey };
