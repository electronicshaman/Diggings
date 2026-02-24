/**
 * React hook for AI node generation with SSE streaming
 */

import { useState, useCallback, useRef, useEffect } from 'react';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import type { GenerationRequest, ProgressEvent, GenerationResponse, CriticResult, BulkGenerationRequest } from '@node-gen-web/shared';
import { streamGeneration, reconnectToJob, type StreamHandle } from '@/lib/streaming';
import { useGenerationStore, type GenerationJob } from '@/store/generation-store';

export interface GenerationState {
  stage: 'idle' | 'outlining' | 'expanding' | 'reviewing' | 'completed' | 'error';
  progress: number;
  message?: string;
  outline?: unknown;
  content?: unknown;
  criticScore?: number;
  criticResult?: CriticResult;
  error?: string;
}

/**
 * Hook for generating a single node with streaming progress
 */
export function useGenerateNode() {
  const streamRef = useRef<StreamHandle | null>(null);
  const queryClient = useQueryClient();

  // Get state from Zustand store
  const state = useGenerationStore((state) => ({
    stage: state.activeJob?.stage ?? 'idle',
    progress: state.activeJob?.progress ?? 0,
    message: state.activeJob?.message,
    outline: state.activeJob?.outline,
    content: state.activeJob?.content,
    criticScore: state.activeJob?.criticScore,
    criticResult: state.activeJob?.criticResult,
    error: state.activeJob?.error,
  }));

  // Job recovery on mount
  useEffect(() => {
    const activeJob = useGenerationStore.getState().activeJob;

    if (activeJob && activeJob.stage !== 'completed' && activeJob.stage !== 'error') {
      // Job exists and is incomplete - check if still running
      const ageMinutes = (Date.now() - activeJob.startedAt) / 60000;

      if (ageMinutes < 60) {
        // Within reasonable window - query job status from backend
        reconnectToJob(activeJob.jobId)
          .then((jobStatus) => {
            if (!jobStatus) {
              // Job not found (expired)
              useGenerationStore.getState().clearJob();
              return;
            }

            if (jobStatus.status === 'running') {
              // Job still running - update local state with latest progress
              useGenerationStore.getState().updateProgress({
                stage: (jobStatus.currentStage || 'outlining') as GenerationJob['stage'],
                progress: jobStatus.progress,
              });
            } else if (jobStatus.status === 'completed') {
              // Job finished while disconnected
              useGenerationStore.getState().updateProgress({
                stage: 'completed',
                progress: 100,
                content: jobStatus.result?.content,
                criticScore: jobStatus.result?.critic?.score,
                criticResult: jobStatus.result?.critic,
              });
            } else if (jobStatus.status === 'failed') {
              useGenerationStore.getState().updateProgress({
                stage: 'error',
                error: jobStatus.error || 'Generation failed',
              });
            } else {
              // Pending or unknown - clear
              useGenerationStore.getState().clearJob();
            }
          })
          .catch(() => {
            // Network error - keep local state, user can retry
          });
      } else {
        // Too old, likely expired
        useGenerationStore.getState().clearJob();
      }
    }
  }, []); // Run once on mount

  const reset = useCallback(() => {
    if (streamRef.current) {
      streamRef.current.abort();
      streamRef.current = null;
    }
    useGenerationStore.getState().clearJob();
  }, []);

  const abort = useCallback(() => {
    if (streamRef.current) {
      streamRef.current.abort();
      streamRef.current = null;
    }
    useGenerationStore.getState().updateProgress({
      stage: 'idle',
      error: 'Generation cancelled',
    });
  }, []);

  const generate = useCallback(
    (request: GenerationRequest): Promise<GenerationResponse> => {
      return new Promise((resolve, reject) => {
        reset();

        // Initialize new job in store
        const jobId = crypto.randomUUID();
        useGenerationStore.getState().setJob({
          jobId,
          stage: 'outlining',
          progress: 0,
          message: 'Starting generation...',
          startedAt: Date.now(),
        });

        streamRef.current = streamGeneration(
          '/api/generate/stream',
          request,
          {
            onProgress: (event: ProgressEvent) => {
              useGenerationStore.getState().updateProgress({
                stage: event.stage as GenerationJob['stage'],
                progress: event.progress,
                message: event.message,
                ...(event.data?.outline && { outline: event.data.outline }),
                ...(event.data?.content && { content: event.data.content }),
                ...(event.data?.criticScore && { criticScore: event.data.criticScore }),
              });
            },
            onComplete: (data) => {
              const response = data as GenerationResponse;
              useGenerationStore.getState().updateProgress({
                stage: 'completed',
                progress: 100,
                content: response.content,
                criticScore: response.criticScore,
                criticResult: response.criticResult,
                message: 'Generation completed!',
              });
              queryClient.invalidateQueries({ queryKey: ['nodes'] });
              resolve(response);
            },
            onError: (error) => {
              useGenerationStore.getState().updateProgress({
                stage: 'error',
                error,
              });
              reject(new Error(error));
            },
          }
        );
      });
    },
    [reset, queryClient]
  );

  return {
    state,
    generate,
    abort,
    reset,
    isGenerating: state.stage !== 'idle' && state.stage !== 'completed' && state.stage !== 'error',
  };
}

/**
 * Hook for generating a node without streaming (simple mutation)
 */
export function useGenerateNodeMutation() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (request: GenerationRequest): Promise<GenerationResponse> => {
      const response = await fetch('/api/generate/node', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(request),
      });

      if (!response.ok) {
        const error = await response.json().catch(() => ({ error: 'Request failed' }));
        throw new Error(error.error || 'Generation failed');
      }

      return response.json();
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['nodes'] });
    },
  });
}

/**
 * Hook for fetching distribution gaps (for bulk generation)
 */
export function useDistributionGaps() {
  return useQuery({
    queryKey: ['distribution-gaps'],
    queryFn: async () => {
      const response = await fetch('/api/config/advanced/distributions/gaps');
      if (!response.ok) throw new Error('Failed to fetch distribution gaps');
      return response.json();
    },
  });
}

/**
 * Bulk generation progress state
 */
export interface BulkGenerationProgress {
  status: 'idle' | 'running' | 'paused' | 'completed' | 'error';
  total: number;
  completed: number;
  failed: number;
  currentNode?: string;
  errors: string[];
}

/**
 * Hook for bulk generation with SSE streaming
 */
export function useBulkGeneration() {
  const [progress, setProgress] = useState<BulkGenerationProgress>({
    status: 'idle',
    total: 0,
    completed: 0,
    failed: 0,
    errors: [],
  });
  const abortRef = useRef<AbortController | null>(null);
  const queryClient = useQueryClient();

  const start = useCallback(async (request: BulkGenerationRequest) => {
    abortRef.current = new AbortController();

    setProgress({
      status: 'running',
      total: 0,
      completed: 0,
      failed: 0,
      errors: [],
    });

    try {
      const response = await fetch('/api/generate/bulk', {
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
                queryClient.invalidateQueries({ queryKey: ['nodes'] });
                queryClient.invalidateQueries({ queryKey: ['distribution-gaps'] });
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
          errors: [...prev.errors, error instanceof Error ? error.message : 'Unknown error'],
        }));
      }
    }
  }, [queryClient]);

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
