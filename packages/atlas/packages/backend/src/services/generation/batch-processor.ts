/**
 * Batch processor - Handles bulk generation with concurrency control
 * Processes multiple nodes concurrently with progress tracking and retries
 */

import { generateBeatOutline, type BeatOutline } from './beat-outliner.js';
import { expandBeatsToProse, type ExpandedContent } from './prose-expander.js';
import { evaluateContent, type CriticResult } from './critic.js';
import { validateNodeContent, type ValidationResult } from './content-validator.js';
import { db } from '../../db/index.js';
import { generationSettings } from '../../db/schema.js';
import type { NodeContentSchema } from '@atlas/shared';
import type { z } from 'zod';

export interface NodeGenerationRequest {
  nodeId: string;
  nodeType: string;
  biome: string;
  name: string;
  themes: string[];
  entityTypes: string[];
  act?: number;
  nodeMetadata: any;
}

export interface GenerationProgress {
  nodeId: string;
  stage: 'outlining' | 'expanding' | 'reviewing' | 'completed' | 'failed';
  progress: number; // 0-100
  outline?: BeatOutline;
  content?: ExpandedContent;
  critic?: CriticResult;
  error?: string;
}

export interface BatchGenerationResult {
  total: number;
  successful: number;
  failed: number;
  results: Map<string, GenerationProgress>;
}

export type ProgressCallback = (progress: GenerationProgress) => void;

/**
 * Generate content for a single node through all stages
 * Includes quality retry loop for low scores (separate from transient error retries)
 */
async function generateNodeContent(
  request: NodeGenerationRequest,
  onProgress?: ProgressCallback,
  enableCritic: boolean = true,
  criticThreshold: number = 70,
  maxQualityRetries: number = 2
): Promise<GenerationProgress> {
  let qualityAttempts = 0;
  let bestAttempt: GenerationProgress | null = null;
  let validation: ValidationResult<z.infer<typeof NodeContentSchema>> = { success: false };

  // INNER LOOP: Quality retry for low scores
  while (qualityAttempts <= maxQualityRetries) {
    const progress: GenerationProgress = {
      nodeId: request.nodeId,
      stage: 'outlining',
      progress: 0,
    };

    try {
      // Stage 1: Beat outlining
      if (onProgress) onProgress({ ...progress, stage: 'outlining', progress: 20 });

      const outline = await generateBeatOutline({
        nodeId: request.nodeId,
        nodeType: request.nodeType,
        biome: request.biome,
        name: request.name,
        themes: request.themes,
        entityTypes: request.entityTypes,
        act: request.act,
        nodeMetadata: request.nodeMetadata,
      });

      progress.outline = outline;

      // Stage 2: Prose expansion
      if (onProgress) onProgress({ ...progress, stage: 'expanding', progress: 50 });

      const content = await expandBeatsToProse({
        nodeId: request.nodeId,
        nodeType: request.nodeType,
        biome: request.biome,
        name: request.name,
        themes: request.themes,
        entityTypes: request.entityTypes,
        act: request.act,
        outline,
        nodeMetadata: request.nodeMetadata,
      });

      progress.content = content;

      // VALIDATION CHECKPOINT (runs each iteration)
      validation = validateNodeContent(progress.content);
      if (!validation.success) {
        // Validation failure = IMMEDIATE FAIL, no retry
        progress.stage = 'failed';
        progress.progress = 100;
        progress.error = `Validation failed: ${validation.errors?.join(', ')}`;
        if (onProgress) onProgress(progress);
        return progress;  // Return immediately, don't retry
      }

      // Stage 3: Critic evaluation (optional)
      let criticResult: CriticResult | undefined;
      if (enableCritic) {
        if (onProgress) onProgress({ ...progress, stage: 'reviewing', progress: 80 });

        criticResult = await evaluateContent({
          nodeId: request.nodeId,
          nodeType: request.nodeType,
          biome: request.biome,
          name: request.name,
          themes: request.themes,
          entityTypes: request.entityTypes,
          act: request.act,
          content,
          nodeMetadata: request.nodeMetadata,
        });

        progress.critic = criticResult;
      }

      // RETRY DECISION LOGIC - validation.success MUST gate retry
      const shouldRetry = (
        validation.success &&  // CRITICAL: Must be structurally valid to retry
        criticResult &&
        criticResult.score < criticThreshold &&
        !criticResult.issues.some(i => i.severity === 'critical') &&
        qualityAttempts < maxQualityRetries
      );

      if (shouldRetry) {
        qualityAttempts++;
        // Keep best attempt in case all retries fail
        if (!bestAttempt || (criticResult && criticResult.score > (bestAttempt.critic?.score || 0))) {
          bestAttempt = { ...progress };
        }
        continue;  // Retry from Stage 1
      }

      // Not retrying - check if pass
      if (criticResult && (!criticResult.pass || criticResult.score < criticThreshold)) {
        // Quality failure after exhausting retries
        // Return best attempt if we have one
        if (bestAttempt && bestAttempt.critic && criticResult && bestAttempt.critic.score > criticResult.score) {
          bestAttempt.stage = 'failed';
          bestAttempt.progress = 100;
          bestAttempt.error = `Best attempt: ${bestAttempt.critic.score}/100 after ${qualityAttempts + 1} tries`;
          if (onProgress) onProgress(bestAttempt);
          return bestAttempt;
        }
        progress.stage = 'failed';
        progress.progress = 100;
        progress.error = `Quality below threshold (${criticResult.score}/100). ${criticResult.repairInstructions || ''}`;
        if (onProgress) onProgress(progress);
        return progress;
      }

      // SUCCESS - passed validation and critic
      progress.stage = 'completed';
      progress.progress = 100;
      if (onProgress) onProgress(progress);
      return progress;

    } catch (error) {
      progress.stage = 'failed';
      progress.progress = 100;
      progress.error = error instanceof Error ? error.message : String(error);
      if (onProgress) onProgress(progress);
      return progress;
    }
  }

  // Should never reach here, but return best attempt just in case
  if (bestAttempt) {
    bestAttempt.stage = 'failed';
    bestAttempt.progress = 100;
    bestAttempt.error = bestAttempt.error || 'Exhausted quality retries';
    if (onProgress) onProgress(bestAttempt);
    return bestAttempt;
  }

  // Fallback error
  const fallback: GenerationProgress = {
    nodeId: request.nodeId,
    stage: 'failed',
    progress: 100,
    error: 'Unknown error in quality retry loop',
  };
  if (onProgress) onProgress(fallback);
  return fallback;
}

/**
 * Process batch of nodes with concurrency control
 */
export async function generateBatch(
  requests: NodeGenerationRequest[],
  options: {
    batchSize?: number;
    enableCritic?: boolean;
    criticThreshold?: number;
    maxRetries?: number;
    maxQualityRetries?: number;
    onProgress?: ProgressCallback;
  } = {}
): Promise<BatchGenerationResult> {
  // Get settings from database
  const settings = await db.select().from(generationSettings);
  const defaultSettings = settings[0];

  const batchSize = options.batchSize || defaultSettings?.batchSize || 5;
  const enableCritic = options.enableCritic ?? (defaultSettings?.enableCriticStage ?? true);
  const criticThreshold = options.criticThreshold || defaultSettings?.criticThreshold || 70;
  const maxRetries = options.maxRetries || defaultSettings?.maxRetries || 3;
  const maxQualityRetries = options.maxQualityRetries ?? 2;

  const results = new Map<string, GenerationProgress>();
  const queue = [...requests];
  let successful = 0;
  let failed = 0;

  // Process in batches
  while (queue.length > 0) {
    const batch = queue.splice(0, batchSize);

    const batchPromises = batch.map(async (request) => {
      let attempts = 0;
      let lastError: string | undefined;

      while (attempts <= maxRetries) {
        try {
          const result = await generateNodeContent(
            request,
            options.onProgress,
            enableCritic,
            criticThreshold,
            maxQualityRetries
          );

          if (result.stage === 'completed') {
            successful++;
            results.set(request.nodeId, result);
            return;
          } else if (result.stage === 'failed') {
            lastError = result.error;
            attempts++;

            if (attempts <= maxRetries) {
              // Wait before retry with exponential backoff
              await new Promise((resolve) => setTimeout(resolve, Math.pow(2, attempts) * 1000));
            }
          }
        } catch (error) {
          lastError = error instanceof Error ? error.message : String(error);
          attempts++;

          if (attempts <= maxRetries) {
            await new Promise((resolve) => setTimeout(resolve, Math.pow(2, attempts) * 1000));
          }
        }
      }

      // All retries exhausted
      failed++;
      results.set(request.nodeId, {
        nodeId: request.nodeId,
        stage: 'failed',
        progress: 100,
        error: lastError || 'Unknown error',
      });
    });

    await Promise.all(batchPromises);
  }

  return {
    total: requests.length,
    successful,
    failed,
    results,
  };
}

/**
 * Generate content for a single node with retries
 */
export async function generateSingle(
  request: NodeGenerationRequest,
  options: {
    enableCritic?: boolean;
    criticThreshold?: number;
    maxRetries?: number;
    maxQualityRetries?: number;
    onProgress?: ProgressCallback;
  } = {}
): Promise<GenerationProgress> {
  const result = await generateBatch([request], options);
  const nodeResult = result.results.get(request.nodeId);

  if (!nodeResult) {
    throw new Error('Generation failed with unknown error');
  }

  return nodeResult;
}
