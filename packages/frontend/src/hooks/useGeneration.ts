/**
 * React hook for AI node generation with SSE streaming
 */

import { useCallback, useRef, useEffect } from 'react';
import { useMutation, useQueryClient } from '@tanstack/react-query';
import type { GenerationRequest, ProgressEvent, GenerationResponse, CriticResult } from '@node-gen-web/shared';
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
export function useDistributionGaps(_biome?: string, _nodeType?: string) {
  // TODO: Implement when backend supports gap analysis
  return {
    data: null,
    isLoading: false,
    error: null,
  };
}
