import { useState, useCallback, useRef } from 'react';

interface UseFieldGenerationOptions {
  onFinish?: (fieldName: string, content: string) => void;
  onError?: (error: string) => void;
}

interface FieldContext {
  nodeType: string;
  biome: string;
  name?: string;
  themes?: string[];
  entityTypes?: string[];
  act?: number;
  nodeMetadata?: Record<string, unknown>;
}

interface GeneratedBeat {
  id: string;
  role: string;
  text: string;
}

export function useFieldGeneration(options?: UseFieldGenerationOptions) {
  const [generatingField, setGeneratingField] = useState<string | null>(null);
  const [streamedContent, setStreamedContent] = useState<string>('');
  const [error, setError] = useState<string | null>(null);
  const abortControllerRef = useRef<AbortController | null>(null);
  // Track final content separately to avoid race condition
  const finalContentRef = useRef<string>('');

  const generateField = useCallback(async (
    fieldType: 'narrative_hook' | 'beat',
    fieldName: string,
    context: FieldContext,
    extraParams?: Record<string, unknown>
  ) => {
    // Cancel any existing generation
    abortControllerRef.current?.abort();

    setGeneratingField(fieldName);
    setStreamedContent('');
    setError(null);
    finalContentRef.current = '';

    const endpoint = fieldType === 'narrative_hook'
      ? '/api/generate/field/narrative-hook'
      : '/api/generate/field/beat';

    const body = {
      nodeType: context.nodeType,
      biome: context.biome,
      name: context.name,
      themes: context.themes || [],
      entityTypes: context.entityTypes || [],
      act: context.act,
      ...extraParams,
    };

    abortControllerRef.current = new AbortController();

    try {
      const response = await fetch(endpoint, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(body),
        signal: abortControllerRef.current.signal,
      });

      if (!response.ok) {
        const errorData = await response.json().catch(() => ({}));
        throw new Error(errorData.error || `HTTP ${response.status}`);
      }

      const reader = response.body?.getReader();
      const decoder = new TextDecoder();
      let accumulated = '';
      let buffer = '';

      while (reader) {
        const { done, value } = await reader.read();
        if (done) break;

        buffer += decoder.decode(value, { stream: true });

        // Parse SSE format: "data: {...}\n\n"
        const lines = buffer.split('\n');
        buffer = lines.pop() || ''; // Keep incomplete line in buffer

        for (const line of lines) {
          if (line.startsWith('data: ')) {
            try {
              const data = JSON.parse(line.slice(6));
              if (data.type === 'token') {
                accumulated += data.content;
                setStreamedContent(accumulated);
              } else if (data.type === 'done') {
                // Store final content and update streamed content
                finalContentRef.current = data.content;
                setStreamedContent(data.content);
                // Call onFinish AFTER setting streamedContent to ensure UI consistency
                options?.onFinish?.(fieldName, data.content);
              } else if (data.type === 'error') {
                throw new Error(data.error);
              }
            } catch (parseError) {
              // Skip malformed JSON lines
              console.warn('Failed to parse SSE line:', line);
            }
          }
        }
      }
    } catch (err) {
      if (err instanceof Error && err.name === 'AbortError') {
        // Cancelled by user, not an error
        return;
      }
      const message = err instanceof Error ? err.message : 'Generation failed';
      setError(message);
      options?.onError?.(message);
    } finally {
      setGeneratingField(null);
      abortControllerRef.current = null;
    }
  }, [options]);

  const generateBeatList = useCallback(async (
    context: FieldContext & { narrativeHook?: string }
  ): Promise<GeneratedBeat[] | null> => {
    setError(null);

    try {
      const response = await fetch('/api/generate/field/beat-list', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          nodeType: context.nodeType,
          biome: context.biome,
          name: context.name,
          themes: context.themes || [],
          narrativeHook: context.narrativeHook,
        }),
      });

      if (!response.ok) {
        const errorData = await response.json().catch(() => ({}));
        throw new Error(errorData.error || `HTTP ${response.status}`);
      }

      const data = await response.json();
      return data.beats;
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Failed to generate beats';
      setError(message);
      options?.onError?.(message);
      return null;
    }
  }, [options]);

  const cancel = useCallback(() => {
    abortControllerRef.current?.abort();
    setGeneratingField(null);
    // Keep streamedContent so partial generation is visible
  }, []);

  return {
    generateField,
    generateBeatList,
    generatingField,
    streamedContent,
    isGenerating: generatingField !== null,
    error,
    cancel,
  };
}
