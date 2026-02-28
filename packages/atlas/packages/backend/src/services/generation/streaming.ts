/**
 * Server-Sent Events (SSE) support for streaming generation progress
 * Sends real-time updates to clients during content generation with heartbeat and job persistence
 */

import type { Context } from 'hono';
import { generateSingle, type NodeGenerationRequest, type GenerationProgress } from './batch-processor.js';
import { createJob, updateJobStatus, type JobStatus } from './job-tracker.js';
import { classifyLLMError, type LLMError } from './error-handler.js';
import { saveNodeToDatabase } from '../../routes/generate.js';
import { validateNodeContent } from './content-validator.js';

/**
 * SSE message types
 */
export type SSEMessageType =
  | 'progress' // Progress update with stage/percentage
  | 'partial' // Partial results (outline after stage 1, content after stage 2)
  | 'complete' // Generation completed successfully
  | 'error' // Error occurred
  | 'ping'; // Keep-alive heartbeat

export interface SSEMessage {
  type: SSEMessageType;
  data: any;
}

/**
 * Format SSE message for transmission
 * Follows proper SSE format: event: type\ndata: json\n\n
 */
function formatSSE(event: string, data: any): string {
  return `event: ${event}\ndata: ${JSON.stringify(data)}\n\n`;
}


/**
 * Stream generation with SSE
 */
export async function streamGeneration(c: Context, request: NodeGenerationRequest, jobId: string) {
  // Set SSE headers with anti-buffering
  c.header('Content-Type', 'text/event-stream');
  c.header('Cache-Control', 'no-cache, no-store, must-revalidate');
  c.header('Connection', 'keep-alive');
  c.header('X-Accel-Buffering', 'no'); // Prevents nginx buffering
  c.header('X-Content-Type-Options', 'nosniff');

  const encoder = new TextEncoder();

  // Create ReadableStream for SSE
  const stream = new ReadableStream({
    async start(controller) {
      // Heartbeat interval (ping every 12 seconds)
      const heartbeat = setInterval(() => {
        try {
          controller.enqueue(encoder.encode(formatSSE('ping', { timestamp: Date.now() })));
        } catch (e) {
          // Stream closed, clear heartbeat
          clearInterval(heartbeat);
        }
      }, 12000);

      try {
        // Update job status to running
        await updateJobStatus(jobId, {
          status: 'running',
          currentStage: 'outlining',
          progress: 0,
        });

        // Start generation with progress callbacks
        const result = await generateSingle(request, {
          onProgress: async (progress: GenerationProgress) => {
            // Update job in database
            await updateJobStatus(jobId, {
              progress: progress.progress,
              currentStage: progress.stage,
            });

            // Send progress event
            controller.enqueue(
              encoder.encode(
                formatSSE('progress', {
                  jobId,
                  stage: progress.stage,
                  progress: progress.progress,
                  message: getStageMessage(progress.stage, progress.progress),
                })
              )
            );

            // Send partial results
            if (progress.stage === 'expanding' && progress.outline) {
              controller.enqueue(
                encoder.encode(
                  formatSSE('partial', {
                    jobId,
                    type: 'outline',
                    data: progress.outline,
                  })
                )
              );
            } else if (progress.stage === 'reviewing' && progress.content) {
              controller.enqueue(
                encoder.encode(
                  formatSSE('partial', {
                    jobId,
                    type: 'content',
                    data: progress.content,
                  })
                )
              );
            }
          },
        });

        // Handle completion or failure
        if (result.stage === 'completed' && result.content) {
          // Validate content before database save
          const validation = validateNodeContent(result.content);
          if (!validation.success) {
            // Validation failed - report but don't save
            await updateJobStatus(jobId, {
              status: 'completed',
              progress: 100,
              currentStage: 'completed',
              error: 'Content validation failed: ' + validation.errors?.join(', '),
            });

            controller.enqueue(
              encoder.encode(
                formatSSE('complete', {
                  jobId,
                  outline: result.outline,
                  content: result.content,
                  critic: result.critic,
                  validationError: validation.errors,
                })
              )
            );
            // Skip database save, close stream
            clearInterval(heartbeat);
            controller.close();
            return;
          }

          // Validation passed - proceed with save
          try {
            // Save to database
            const savedNodeId = await saveNodeToDatabase({
              nodeId: request.nodeId || undefined,
              nodeType: request.nodeType,
              biome: request.biome,
              name: request.name,
              themes: request.themes,
              entityTypes: request.entityTypes,
              content: result.content,
              criticScore: result.critic?.score,
              // Type-specific fields from nodeMetadata
              enemyTypeHooks: request.nodeMetadata?.enemyTypeHooks,
              environmentalContext: request.nodeMetadata?.environmentalContext,
              consequenceHooks: request.nodeMetadata?.consequenceHooks,
              dilemmaType: request.nodeMetadata?.dilemmaType,
              traderArchetype: request.nodeMetadata?.traderArchetype,
              pricingHooks: request.nodeMetadata?.pricingHooks,
              restType: request.nodeMetadata?.restType,
              interruptionChance: request.nodeMetadata?.interruptionChance,
              dreamHooks: request.nodeMetadata?.dreamHooks,
              travelEventHooks: request.nodeMetadata?.travelEventHooks,
              environmentalStorytelling: request.nodeMetadata?.environmentalStorytelling,
              conditionHooks: request.nodeMetadata?.conditionHooks,
              actChangeTrigger: request.nodeMetadata?.actChangeTrigger,
              narrativeSummary: request.nodeMetadata?.narrativeSummary,
              worldStateShifts: request.nodeMetadata?.worldStateShifts,
              estimatedCombatDifficulty: request.nodeMetadata?.estimatedCombatDifficulty,
            });

            // Update job with final nodeId
            await updateJobStatus(jobId, {
              status: 'completed',
              progress: 100,
              currentStage: 'completed',
              result: { ...result, nodeId: savedNodeId },
            });

            // Send completion event with nodeId
            controller.enqueue(
              encoder.encode(
                formatSSE('complete', {
                  jobId,
                  nodeId: savedNodeId,
                  outline: result.outline,
                  content: result.content,
                  critic: result.critic,
                })
              )
            );
          } catch (dbError) {
            // Database save failed, but generation succeeded
            // Still send completion but note the save failure
            console.error('Failed to save generated node to database:', dbError);

            await updateJobStatus(jobId, {
              status: 'completed',
              progress: 100,
              currentStage: 'completed',
              result: result,
              error: 'Generated but failed to save: ' + (dbError instanceof Error ? dbError.message : String(dbError)),
            });

            controller.enqueue(
              encoder.encode(
                formatSSE('complete', {
                  jobId,
                  outline: result.outline,
                  content: result.content,
                  critic: result.critic,
                  saveError: 'Failed to save to database',
                })
              )
            );
          }
        } else {
          // Update job to failed
          await updateJobStatus(jobId, {
            status: 'failed',
            progress: 100,
            currentStage: 'error',
            error: result.error || 'Unknown error',
          });

          // Send error event with user-friendly message
          const classified = classifyLLMError(result.error || 'Unknown error');
          controller.enqueue(
            encoder.encode(
              formatSSE('error', {
                jobId,
                stage: 'error',
                error: classified.technicalMessage,
                userMessage: classified.userMessage,
                retryable: classified.retryable,
                httpStatus: classified.httpStatus,
              })
            )
          );
        }

        // Clean up and close
        clearInterval(heartbeat);
        controller.close();
      } catch (error) {
        // Update job to failed
        const errorMsg = error instanceof Error ? error.message : String(error);
        await updateJobStatus(jobId, {
          status: 'failed',
          progress: 100,
          currentStage: 'error',
          error: errorMsg,
        });

        // Send error event with user-friendly message
        const classified = classifyLLMError(error);
        controller.enqueue(
          encoder.encode(
            formatSSE('error', {
              jobId,
              stage: 'error',
              error: classified.technicalMessage,
              userMessage: classified.userMessage,
              retryable: classified.retryable,
              httpStatus: classified.httpStatus,
            })
          )
        );

        clearInterval(heartbeat);
        controller.close();
      }
    },
  });

  return new Response(stream);
}

/**
 * Get user-friendly progress message
 */
function getStageMessage(stage: string, progress: number): string {
  const messages: Record<string, string> = {
    outlining: 'Generating narrative beat structure...',
    expanding: 'Expanding beats into full prose...',
    reviewing: 'Evaluating content quality...',
    completed: 'Generation completed successfully!',
    error: 'Generation failed.',
  };

  const baseMessage = messages[stage] || 'Processing...';
  return `${baseMessage} (${progress}%)`;
}

/**
 * Create SSE stream (deprecated - use streamGeneration)
 * @deprecated Use streamGeneration instead
 */
export function createSSEStream(c: Context, request: NodeGenerationRequest) {
  throw new Error('createSSEStream is deprecated. Use streamGeneration instead.');
}

/**
 * Stream SSE (deprecated - use streamGeneration)
 * @deprecated Use streamGeneration instead
 */
export function streamSSE(c: Context, request: NodeGenerationRequest) {
  throw new Error('streamSSE is deprecated. Use streamGeneration instead.');
}
