import type {
  AnyNodeMetadata,
  NodeType,
  Biome,
  Act,
} from '@atlas/shared';

const API_BASE = '/api';

async function fetchApi<T>(endpoint: string, options?: RequestInit): Promise<T> {
  const res = await fetch(`${API_BASE}${endpoint}`, {
    headers: { 'Content-Type': 'application/json', ...options?.headers },
    ...options,
  });
  if (!res.ok) {
    const error = await res.json().catch(() => ({ message: 'Request failed' }));
    throw new Error(error.message || error.error || 'Request failed');
  }
  return res.json();
}

export interface NodesParams {
  type?: NodeType;
  biome?: Biome;
  acts?: Act[];
  limit?: number;
  offset?: number;
}

export interface NodesResponse {
  nodes: AnyNodeMetadata[];
  total: number;
  limit: number;
  offset: number;
}

interface BackendNodesResponse {
  data: AnyNodeMetadata[];
  pagination: {
    limit: number;
    offset: number;
    total: number;
  };
}

export interface SearchParams {
  q: string;
  limit?: number;
  offset?: number;
}

export interface SearchResponse {
  results: AnyNodeMetadata[];
  total: number;
  limit: number;
  offset: number;
}

export interface StatsResponse {
  total: number;
  byType: Record<string, number>;
  byBiome: Record<string, number>;
  byAct: Record<string, number>;
}

export interface BiomeConfig {
  id: Biome;
  name: string;
  description: string;
  themes: string[];
}

export interface DistributionConfig {
  biome: Biome;
  act: Act;
  weights: Record<NodeType, number>;
}

export interface LookupItem {
  id: number;
  biome?: string;
  hook: string;
  archetypeKey?: string;
}

export type LookupResponse = LookupItem[];

function normalizeNode(node: AnyNodeMetadata & { nodeId?: string }): AnyNodeMetadata {
  return {
    ...node,
    id: node.nodeId ?? node.id,
  } as AnyNodeMetadata;
}

export async function getNodes(params: NodesParams = {}): Promise<NodesResponse> {
  const searchParams = new URLSearchParams();
  if (params.type) searchParams.set('type', params.type);
  if (params.biome) searchParams.set('biome', params.biome);
  if (params.acts?.length) searchParams.set('acts', params.acts.join(','));
  if (params.limit !== undefined) searchParams.set('limit', String(params.limit));
  if (params.offset !== undefined) searchParams.set('offset', String(params.offset));

  const query = searchParams.toString();
  const response = await fetchApi<BackendNodesResponse>(`/nodes${query ? `?${query}` : ''}`);
  return {
    nodes: response.data.map((node) => normalizeNode(node as AnyNodeMetadata & { nodeId?: string })),
    total: response.pagination.total,
    limit: response.pagination.limit,
    offset: response.pagination.offset,
  };
}

export async function getNode(nodeId: string): Promise<AnyNodeMetadata> {
  const node = await fetchApi<AnyNodeMetadata & { nodeId?: string }>(
    `/nodes/${encodeURIComponent(nodeId)}`
  );
  return normalizeNode(node);
}

export async function createNode(
  data: Omit<AnyNodeMetadata, 'id'>
): Promise<AnyNodeMetadata> {
  const node = await fetchApi<AnyNodeMetadata & { nodeId?: string }>('/nodes', {
    method: 'POST',
    body: JSON.stringify(data),
  });
  return normalizeNode(node);
}

export async function updateNode(
  nodeId: string,
  data: Partial<AnyNodeMetadata>
): Promise<AnyNodeMetadata> {
  const node = await fetchApi<AnyNodeMetadata & { nodeId?: string }>(
    `/nodes/${encodeURIComponent(nodeId)}`,
    {
      method: 'PUT',
      body: JSON.stringify(data),
    }
  );
  return normalizeNode(node);
}

export async function deleteNode(nodeId: string): Promise<void> {
  await fetchApi<void>(`/nodes/${encodeURIComponent(nodeId)}`, {
    method: 'DELETE',
  });
}

export async function searchNodes(params: SearchParams): Promise<SearchResponse> {
  const searchParams = new URLSearchParams();
  searchParams.set('q', params.q);
  if (params.limit !== undefined) searchParams.set('limit', String(params.limit));
  if (params.offset !== undefined) searchParams.set('offset', String(params.offset));

  return fetchApi<SearchResponse>(`/search?${searchParams.toString()}`);
}

export async function getStats(): Promise<StatsResponse> {
  return fetchApi<StatsResponse>('/search/stats');
}

export async function getBiomes(): Promise<BiomeConfig[]> {
  return fetchApi<BiomeConfig[]>('/config/biomes');
}

export async function getDistributions(): Promise<DistributionConfig[]> {
  return fetchApi<DistributionConfig[]>('/config/distributions');
}

export async function getLookup(type: string, biome?: Biome): Promise<LookupResponse> {
  const searchParams = new URLSearchParams();
  if (biome) searchParams.set('biome', biome);
  const query = searchParams.toString();
  return fetchApi<LookupResponse>(
    `/config/lookup/${encodeURIComponent(type)}${query ? `?${query}` : ''}`
  );
}
