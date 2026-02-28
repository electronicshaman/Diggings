import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import type {
  LLMProvider,
  LLMProviderConfig,
  LLMProviderUpdate,
  LLMProviderTestResult,
} from '@node-gen-web/shared';

interface ProviderWithApiKey extends Omit<LLMProvider, 'encryptedApiKey'> {
  hasApiKey: boolean;
}

/**
 * Fetch all LLM providers
 */
export function useLLMProviders() {
  return useQuery<ProviderWithApiKey[]>({
    queryKey: ['llm-providers'],
    queryFn: async () => {
      const res = await fetch(`/api/llm/providers`);
      if (!res.ok) {
        throw new Error('Failed to fetch providers');
      }
      return res.json();
    },
  });
}

/**
 * Fetch a single LLM provider
 */
export function useLLMProvider(id: number | undefined) {
  return useQuery<ProviderWithApiKey>({
    queryKey: ['llm-providers', id],
    queryFn: async () => {
      const res = await fetch(`/api/llm/providers/${id}`);
      if (!res.ok) {
        throw new Error('Failed to fetch provider');
      }
      return res.json();
    },
    enabled: !!id,
  });
}

/**
 * Create a new LLM provider
 */
export function useCreateProvider() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (config: LLMProviderConfig) => {
      const res = await fetch(`/api/llm/providers`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(config),
      });
      if (!res.ok) {
        const error = await res.json();
        throw new Error(error.error || 'Failed to create provider');
      }
      return res.json();
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['llm-providers'] });
    },
  });
}

/**
 * Update an existing LLM provider
 */
export function useUpdateProvider() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({ id, updates }: { id: number; updates: LLMProviderUpdate }) => {
      const res = await fetch(`/api/llm/providers/${id}`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(updates),
      });
      if (!res.ok) {
        const error = await res.json();
        throw new Error(error.error || 'Failed to update provider');
      }
      return res.json();
    },
    onSuccess: (_, variables) => {
      queryClient.invalidateQueries({ queryKey: ['llm-providers'] });
      queryClient.invalidateQueries({ queryKey: ['llm-providers', variables.id] });
    },
  });
}

/**
 * Delete an LLM provider
 */
export function useDeleteProvider() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (id: number) => {
      const res = await fetch(`/api/llm/providers/${id}`, {
        method: 'DELETE',
      });
      if (!res.ok) {
        const error = await res.json();
        throw new Error(error.error || 'Failed to delete provider');
      }
      return res.json();
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['llm-providers'] });
    },
  });
}

/**
 * Test an LLM provider connection
 */
export function useTestProvider() {
  return useMutation({
    mutationFn: async (params: { providerId?: number; providerConfig?: LLMProviderConfig }) => {
      const res = await fetch(`/api/llm/test`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(params),
      });
      if (!res.ok) {
        let detail = `HTTP ${res.status}`;
        try {
          const body = await res.json();
          detail = body.error || JSON.stringify(body);
        } catch {
          detail += ` ${res.statusText}`;
        }
        throw new Error(detail);
      }
      return res.json() as Promise<LLMProviderTestResult>;
    },
  });
}

/**
 * Fetch available models from an Ollama server
 */
export function useOllamaModels(baseUrl: string | undefined) {
  return useQuery<string[]>({
    queryKey: ['ollama-models', baseUrl],
    queryFn: async () => {
      const res = await fetch(
        `/api/llm/providers/ollama-models?baseUrl=${encodeURIComponent(baseUrl!)}`
      );
      if (!res.ok) {
        const err = await res.json();
        throw new Error(err.error || 'Failed to fetch Ollama models');
      }
      const data = await res.json();
      return data.models as string[];
    },
    enabled: !!baseUrl,
    retry: false,
    staleTime: 30_000,
  });
}

/**
 * Get the active provider
 */
export function useActiveProvider() {
  const { data: providers } = useLLMProviders();
  return providers?.find((p) => p.isActive);
}
