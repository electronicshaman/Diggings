import { useCallback, useRef, useState } from 'react';
import { useQueryClient } from '@tanstack/react-query';

export interface BulkGenerationProgress {
  status: 'idle' | 'running' | 'paused' | 'completed' | 'error';
  total: number;
  completed: number;
  failed: number;
  currentNode?: string;
  errors: string[];
}

export interface UseBulkGenerationOptions {
  endpoint?: string;
  invalidateKeys?: Array<readonly unknown[]>;
}

export function useBulkGeneration(options: UseBulkGenerationOptions = {}) {
  const [progress, setProgress] = useState<BulkGenerationProgress>({
    status: 'idle',
    total: 0,
    completed: 0,
    failed: 0,
    errors: [],
  });
  const abortRef = useRef<AbortController | null>(null);
  const queryClient = useQueryClient();

  const endpoint = options.endpoint ?? '/api/generate/bulk';
  const invalidateKeys = options.invalidateKeys ?? [
    ['nodes'],
    ['distribution-gaps'],
  ];

  const start = useCallback(async (request: unknown) => {
    abortRef.current = new AbortController();

    setProgress({
      status: 'running',
      total: 0,
      completed: 0,
      failed: 0,
      errors: [],
    });

    try {
      const response = await fetch(endpoint, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Accept: 'text/event-stream',
        },
        body: JSON.stringify(request),
        signal: abortRef.current.signal,
      });

      if (!response.ok) {
        const error = await response.json().catch(() => ({ error: 'Request failed' }));
        setProgress((prev) => ({
          ...prev,
          status: 'error',
          errors: [error.error || 'Bulk generation failed'],
        }));
        return;
      }

      if (!response.body) {
        setProgress((prev) => ({ ...prev, status: 'error', errors: ['No response body'] }));
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

        let eventType = '';
        for (const line of lines) {
          if (line.startsWith('event: ')) {
            eventType = line.slice(7);
          } else if (line.startsWith('data: ')) {
            try {
              const data = JSON.parse(line.slice(6));

              if (eventType === 'bulk_start') {
                setProgress((prev) => ({ ...prev, total: data.total }));
              } else if (eventType === 'node_progress') {
                setProgress((prev) => ({
                  ...prev,
                  completed: data.completed,
                  failed: data.failed,
                  total: data.total,
                  currentNode: data.nodeId,
                  errors: data.error
                    ? [...prev.errors, `${data.nodeId}: ${data.error}`]
                    : prev.errors,
                }));
              } else if (eventType === 'bulk_complete') {
                setProgress((prev) => ({
                  ...prev,
                  status: 'completed',
                  completed: data.successful,
                  failed: data.failed,
                  total: data.total,
                  currentNode: undefined,
                }));
                invalidateKeys.forEach((key) => {
                  queryClient.invalidateQueries({ queryKey: key });
                });
              } else if (eventType === 'bulk_error') {
                setProgress((prev) => ({
                  ...prev,
                  status: 'error',
                  errors: [...prev.errors, data.error],
                }));
              }
            } catch {
              // Skip malformed JSON
            }
            eventType = '';
          }
        }
      }
    } catch (error) {
      if (error instanceof Error && error.name !== 'AbortError') {
        setProgress((prev) => ({
          ...prev,
          status: 'error',
          errors: [...prev.errors, error.message],
        }));
      }
    }
  }, [endpoint, invalidateKeys, queryClient]);

  const cancel = useCallback(() => {
    if (abortRef.current) {
      abortRef.current.abort();
      abortRef.current = null;
    }
    setProgress({
      status: 'idle',
      total: 0,
      completed: 0,
      failed: 0,
      errors: [],
    });
  }, []);

  const reset = useCallback(() => {
    setProgress({
      status: 'idle',
      total: 0,
      completed: 0,
      failed: 0,
      errors: [],
    });
  }, []);

  return { progress, start, cancel, reset };
}
