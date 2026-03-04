/**
 * SSE streaming client for real-time generation updates
 */

import type { ProgressEvent } from '@node-gen-web/shared';

// Reconnection constants
const INITIAL_RETRY_DELAY = 1000; // 1 second
const MAX_RETRY_DELAY = 30000;    // 30 seconds
// const MAX_RETRIES = 5; // Reserved for future retry logic
const BACKOFF_MULTIPLIER = 2;

export interface JobStatus {
  jobId: string;
  status: 'pending' | 'running' | 'completed' | 'failed';
  progress: number;
  currentStage: string | null;
  result: any;
  error: string | null;
  createdAt: string;
  updatedAt: string;
}

export interface StreamCallbacks {
  onProgress?: (event: ProgressEvent) => void;
  onComplete?: (data: unknown) => void;
  onError?: (error: string) => void;
  onReconnecting?: (attempt: number, delay: number) => void;
}

export interface StreamHandle {
  abort: () => void;
}

/**
 * Connect to an SSE endpoint and stream events
 */
export function streamGeneration(
  url: string,
  body: unknown,
  callbacks: StreamCallbacks
): StreamHandle {
  const abortController = new AbortController();

  (async () => {
    try {
      const response = await fetch(url, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Accept: 'text/event-stream',
        },
        body: JSON.stringify(body),
        signal: abortController.signal,
      });

      if (!response.ok) {
        const error = await response.json().catch(() => ({ error: 'Request failed' }));
        callbacks.onError?.(error.error || 'Request failed');
        return;
      }

      if (!response.body) {
        callbacks.onError?.('No response body');
        return;
      }

      const reader = response.body.getReader();
      const decoder = new TextDecoder();
      let buffer = '';

      while (true) {
        const { done, value } = await reader.read();

        if (done) break;

        buffer += decoder.decode(value, { stream: true });
        const lines = buffer.split('\n');
        buffer = lines.pop() || '';

        for (const line of lines) {
          if (line.startsWith('data: ')) {
            try {
              const data = JSON.parse(line.slice(6)) as ProgressEvent;

              if (data.stage === 'completed') {
                callbacks.onComplete?.(data.data);
              } else if (data.stage === 'error') {
                callbacks.onError?.(data.error || 'Unknown error');
              } else {
                callbacks.onProgress?.(data);
              }
            } catch {
              // Skip malformed JSON
            }
          }
        }
      }
    } catch (error) {
      if (error instanceof Error && error.name !== 'AbortError') {
        callbacks.onError?.(error.message);
      }
    }
  })();

  return {
    abort: () => abortController.abort(),
  };
}

/**
 * Calculate exponential backoff delay with jitter
 */
export function calculateBackoff(attemptNumber: number): number {
  const delay = Math.min(
    INITIAL_RETRY_DELAY * Math.pow(BACKOFF_MULTIPLIER, attemptNumber),
    MAX_RETRY_DELAY
  );
  // Add jitter (0-30%) to prevent thundering herd
  const jitter = Math.random() * 0.3 * delay;
  return Math.floor(delay + jitter);
}

/**
 * Reconnect to a job by fetching its current status
 */
export async function reconnectToJob(jobId: string): Promise<JobStatus | null> {
  const response = await fetch(`/api/generate/job/${jobId}`);
  if (!response.ok) {
    if (response.status === 404) return null; // Job expired or not found
    throw new Error('Failed to fetch job status');
  }
  const data = await response.json();
  return data.job;
}

/**
 * Parse SSE event from raw text
 */
export function parseSSEEvent(text: string): { type: string; data: unknown } | null {
  const lines = text.trim().split('\n');
  let eventType = 'message';
  let data = '';

  for (const line of lines) {
    if (line.startsWith('event: ')) {
      eventType = line.slice(7);
    } else if (line.startsWith('data: ')) {
      data += line.slice(6);
    }
  }

  if (!data) return null;

  try {
    return { type: eventType, data: JSON.parse(data) };
  } catch {
    return null;
  }
}
