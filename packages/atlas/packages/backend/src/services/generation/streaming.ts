/**
 * Server-Sent Events (SSE) support for streaming generation progress
 * Sends real-time updates to clients during content generation with heartbeat and job persistence
 */

import type { Context } from 'hono';
import { generateSingle, type NodeGenerationRequest, type GenerationProgress } from './batch-processor.js';
import { createJob, updateJobStatus, type JobStatus } from './job-tracker.js';

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
 * Classify errors as retryable or not
 */
function isRetryableError(error: Error | string): boolean {
  const errorMsg = typeof error === 'string' ? error : error.message;
  const lowerMsg = errorMsg.toLowerCase();

  // Retryable: rate limits, service unavailable, network errors
  if (
    lowerMsg.includes('429') ||
    lowerMsg.includes('rate limit') ||
    lowerMsg.includes('503') ||
    lowerMsg.includes('service unavailable') ||
    lowerMsg.includes('network') ||
    lowerMsg.includes('timeout') ||
    lowerMsg.includes('econnrefused') ||
    lowerMsg.includes('enotfound')
  ) {
    return true;
  }

  // Non-retryable: auth errors, bad requests, validation errors
  if (
    lowerMsg.includes('400') ||
    lowerMsg.includes('401') ||
    lowerMsg.includes('403') ||
    lowerMsg.includes('invalid') ||
    lowerMsg.includes('unauthorized') ||
    lowerMsg.includes('forbidden')
  ) {
    return false;
  }

  // Default to non-retryable for unknown errors
  return false;
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
        if (result.stage === 'completed') {
          // Update job to completed
          await updateJobStatus(jobId, {
            status: 'completed',
            progress: 100,
            currentStage: 'completed',
            result: result,
          });

          // Send completion event
          controller.enqueue(
            encoder.encode(
              formatSSE('complete', {
                jobId,
                outline: result.outline,
                content: result.content,
                critic: result.critic,
              })
            )
          );
        } else {
          // Update job to failed
          await updateJobStatus(jobId, {
            status: 'failed',
            progress: 100,
            currentStage: 'failed',
            error: result.error || 'Unknown error',
          });

          // Send error event
          const retryable = result.error ? isRetryableError(result.error) : false;
          controller.enqueue(
            encoder.encode(
              formatSSE('error', {
                jobId,
                error: result.error || 'Unknown error',
                retryable,
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
          currentStage: 'failed',
          error: errorMsg,
        });

        // Send error event
        const retryable = error instanceof Error ? isRetryableError(error) : false;
        controller.enqueue(
          encoder.encode(
            formatSSE('error', {
              jobId,
              error: errorMsg,
              retryable,
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
    failed: 'Generation failed.',
  };

  const baseMessage = messages[stage] || 'Processing...';
  return `${baseMessage} (${progress}%)`;
}

// Legacy exports for backward compatibility
export type { SSEMessage, SSEMessageType };

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
