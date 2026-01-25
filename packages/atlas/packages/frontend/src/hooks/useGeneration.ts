/**
 * React hook for AI node generation with SSE streaming
 */

import { useState, useCallback, useRef } from 'react';
import { useMutation, useQueryClient } from '@tanstack/react-query';
import type { GenerationRequest, ProgressEvent, GenerationResponse } from '@node-gen-web/shared';
import { streamGeneration, type StreamHandle } from '@/lib/streaming';

export interface GenerationState {
  stage: 'idle' | 'outlining' | 'expanding' | 'reviewing' | 'completed' | 'error';
  progress: number;
  message?: string;
  outline?: unknown;
  content?: unknown;
  criticScore?: number;
  error?: string;
}

const initialState: GenerationState = {
  stage: 'idle',
  progress: 0,
};

/**
 * Hook for generating a single node with streaming progress
 */
export function useGenerateNode() {
  const [state, setState] = useState<GenerationState>(initialState);
  const streamRef = useRef<StreamHandle | null>(null);
  const queryClient = useQueryClient();

  const reset = useCallback(() => {
    if (streamRef.current) {
      streamRef.current.abort();
      streamRef.current = null;
    }
    setState(initialState);
  }, []);

  const abort = useCallback(() => {
    if (streamRef.current) {
      streamRef.current.abort();
      streamRef.current = null;
    }
    setState((prev) => ({
      ...prev,
      stage: 'idle',
      error: 'Generation cancelled',
    }));
  }, []);

  const generate = useCallback(
    (request: GenerationRequest): Promise<GenerationResponse> => {
      return new Promise((resolve, reject) => {
        reset();

        setState({
          stage: 'outlining',
          progress: 0,
          message: 'Starting generation...',
        });

        streamRef.current = streamGeneration(
          '/api/generate/stream',
          request,
          {
            onProgress: (event: ProgressEvent) => {
              setState((prev) => ({
                ...prev,
                stage: event.stage as GenerationState['stage'],
                progress: event.progress,
                message: event.message,
                ...(event.data?.outline && { outline: event.data.outline }),
                ...(event.data?.content && { content: event.data.content }),
                ...(event.data?.criticScore && { criticScore: event.data.criticScore }),
              }));
            },
            onComplete: (data) => {
              const response = data as GenerationResponse;
              setState({
                stage: 'completed',
                progress: 100,
                content: response.content,
                criticScore: response.criticScore,
                message: 'Generation completed!',
              });
              queryClient.invalidateQueries({ queryKey: ['nodes'] });
              resolve(response);
            },
            onError: (error) => {
              setState((prev) => ({
                ...prev,
                stage: 'error',
                error,
              }));
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
