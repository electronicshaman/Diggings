/**
 * SSE streaming client for real-time generation updates
 */

import type { ProgressEvent } from '@node-gen-web/shared';

export interface StreamCallbacks {
  onProgress?: (event: ProgressEvent) => void;
  onComplete?: (data: unknown) => void;
  onError?: (error: string) => void;
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
