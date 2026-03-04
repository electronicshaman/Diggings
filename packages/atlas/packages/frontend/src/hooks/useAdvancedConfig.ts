import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import type {
  BeatRoleRecord,
  BeatRoleCreate,
  BeatSequenceRecord,
  BeatSequenceCreate,
  BeatSequenceUpdate,
  StyleGuideRecord,
  StyleGuideUpdate,
  VernacularRecord,
  VernacularCreate,
  VernacularUpdate,
  ActToneRecord,
  ActToneUpdate,
  GenerationSettings,
  GenerationSettingsUpdate,
} from '@node-gen-web/shared';

const API_BASE = '';

// ============================================================================
// BEAT ROLES
// ============================================================================

export function useBeatRoles() {
  return useQuery<BeatRoleRecord[]>({
    queryKey: ['beat-roles'],
    queryFn: async () => {
      const res = await fetch(`${API_BASE}/api/config/advanced/beat-roles`);
      if (!res.ok) throw new Error('Failed to fetch beat roles');
      return res.json();
    },
  });
}

export function useCreateBeatRole() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async (data: BeatRoleCreate) => {
      const res = await fetch(`${API_BASE}/api/config/advanced/beat-roles`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data),
      });
      if (!res.ok) throw new Error('Failed to create beat role');
      return res.json();
    },
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['beat-roles'] }),
  });
}

export function useUpdateBeatRole() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async ({ id, updates }: { id: number; updates: Partial<BeatRoleCreate> }) => {
      const res = await fetch(`${API_BASE}/api/config/advanced/beat-roles/${id}`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(updates),
      });
      if (!res.ok) throw new Error('Failed to update beat role');
      return res.json();
    },
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['beat-roles'] }),
  });
}

export function useDeleteBeatRole() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async (id: number) => {
      const res = await fetch(`${API_BASE}/api/config/advanced/beat-roles/${id}`, {
        method: 'DELETE',
      });
      if (!res.ok) throw new Error('Failed to delete beat role');
      return res.json();
    },
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['beat-roles'] }),
  });
}

// ============================================================================
// BEAT SEQUENCES
// ============================================================================

export function useBeatSequences(nodeType?: string) {
  return useQuery<BeatSequenceRecord[]>({
    queryKey: ['beat-sequences', nodeType],
    queryFn: async () => {
      const url = nodeType
        ? `${API_BASE}/api/config/advanced/beat-sequences?nodeType=${nodeType}`
        : `${API_BASE}/api/config/advanced/beat-sequences`;
      const res = await fetch(url);
      if (!res.ok) throw new Error('Failed to fetch beat sequences');
      return res.json();
    },
  });
}

export function useCreateBeatSequence() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async (data: BeatSequenceCreate) => {
      const res = await fetch(`${API_BASE}/api/config/advanced/beat-sequences`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data),
      });
      if (!res.ok) throw new Error('Failed to create beat sequence');
      return res.json();
    },
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['beat-sequences'] }),
  });
}

export function useUpdateBeatSequence() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async ({ id, updates }: { id: number; updates: BeatSequenceUpdate }) => {
      const res = await fetch(`${API_BASE}/api/config/advanced/beat-sequences/${id}`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(updates),
      });
      if (!res.ok) throw new Error('Failed to update beat sequence');
      return res.json();
    },
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['beat-sequences'] }),
  });
}

export function useDeleteBeatSequence() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async (id: number) => {
      const res = await fetch(`${API_BASE}/api/config/advanced/beat-sequences/${id}`, {
        method: 'DELETE',
      });
      if (!res.ok) throw new Error('Failed to delete beat sequence');
      return res.json();
    },
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['beat-sequences'] }),
  });
}

// ============================================================================
// STYLE GUIDE
// ============================================================================

export function useStyleGuides() {
  return useQuery<StyleGuideRecord[]>({
    queryKey: ['style-guides'],
    queryFn: async () => {
      const res = await fetch(`${API_BASE}/api/config/advanced/style-guide`);
      if (!res.ok) throw new Error('Failed to fetch style guides');
      return res.json();
    },
  });
}

export function useStyleGuide(biome: string) {
  return useQuery<StyleGuideRecord>({
    queryKey: ['style-guides', biome],
    queryFn: async () => {
      const res = await fetch(`${API_BASE}/api/config/advanced/style-guide?biome=${biome}`);
      if (!res.ok) throw new Error('Failed to fetch style guide');
      return res.json();
    },
    enabled: !!biome,
  });
}

export function useUpdateStyleGuide() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async ({ biome, updates }: { biome: string; updates: StyleGuideUpdate }) => {
      const res = await fetch(`${API_BASE}/api/config/advanced/style-guide/${biome}`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(updates),
      });
      if (!res.ok) throw new Error('Failed to update style guide');
      return res.json();
    },
    onSuccess: (_, variables) => {
      queryClient.invalidateQueries({ queryKey: ['style-guides'] });
      queryClient.invalidateQueries({ queryKey: ['style-guides', variables.biome] });
    },
  });
}

// ============================================================================
// VERNACULAR
// ============================================================================

export function useVernacular() {
  return useQuery<VernacularRecord[]>({
    queryKey: ['vernacular'],
    queryFn: async () => {
      const res = await fetch(`${API_BASE}/api/config/advanced/vernacular`);
      if (!res.ok) throw new Error('Failed to fetch vernacular');
      return res.json();
    },
  });
}

export function useCreateVernacular() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async (data: VernacularCreate) => {
      const res = await fetch(`${API_BASE}/api/config/advanced/vernacular`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data),
      });
      if (!res.ok) throw new Error('Failed to create vernacular term');
      return res.json();
    },
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['vernacular'] }),
  });
}

export function useUpdateVernacular() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async ({ id, updates }: { id: number; updates: VernacularUpdate }) => {
      const res = await fetch(`${API_BASE}/api/config/advanced/vernacular/${id}`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(updates),
      });
      if (!res.ok) throw new Error('Failed to update vernacular term');
      return res.json();
    },
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['vernacular'] }),
  });
}

export function useDeleteVernacular() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async (id: number) => {
      const res = await fetch(`${API_BASE}/api/config/advanced/vernacular/${id}`, {
        method: 'DELETE',
      });
      if (!res.ok) throw new Error('Failed to delete vernacular term');
      return res.json();
    },
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['vernacular'] }),
  });
}

// ============================================================================
// ACT TONES
// ============================================================================

export function useActTones() {
  return useQuery<ActToneRecord[]>({
    queryKey: ['act-tones'],
    queryFn: async () => {
      const res = await fetch(`${API_BASE}/api/config/advanced/act-tones`);
      if (!res.ok) throw new Error('Failed to fetch act tones');
      return res.json();
    },
  });
}

export function useActTone(act: number) {
  return useQuery<ActToneRecord>({
    queryKey: ['act-tones', act],
    queryFn: async () => {
      const res = await fetch(`${API_BASE}/api/config/advanced/act-tones?act=${act}`);
      if (!res.ok) throw new Error('Failed to fetch act tone');
      return res.json();
    },
    enabled: !!act,
  });
}

export function useUpdateActTone() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async ({ act, updates }: { act: number; updates: ActToneUpdate }) => {
      const res = await fetch(`${API_BASE}/api/config/advanced/act-tones/${act}`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(updates),
      });
      if (!res.ok) throw new Error('Failed to update act tone');
      return res.json();
    },
    onSuccess: (_, variables) => {
      queryClient.invalidateQueries({ queryKey: ['act-tones'] });
      queryClient.invalidateQueries({ queryKey: ['act-tones', variables.act] });
    },
  });
}

// ============================================================================
// GENERATION SETTINGS
// ============================================================================

export function useGenerationSettings() {
  return useQuery<GenerationSettings>({
    queryKey: ['generation-settings'],
    queryFn: async () => {
      const res = await fetch(`${API_BASE}/api/config/advanced/generation-settings`);
      if (!res.ok) throw new Error('Failed to fetch generation settings');
      return res.json();
    },
  });
}

export function useUpdateGenerationSettings() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async (updates: GenerationSettingsUpdate) => {
      const res = await fetch(`${API_BASE}/api/config/advanced/generation-settings`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(updates),
      });
      if (!res.ok) throw new Error('Failed to update generation settings');
      return res.json();
    },
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['generation-settings'] }),
  });
}

// ============================================================================
// DISTRIBUTION GAPS
// ============================================================================

export interface DistributionGap {
  biome: string;
  nodeType: string;
  target: number;
  actual: number;
  gap: number;
  needsGeneration: boolean;
}

export interface DistributionGapsResponse {
  gaps: DistributionGap[];
  totalGaps: number;
  totalNodesNeeded: number;
}

export function useDistributionGaps() {
  return useQuery<DistributionGapsResponse>({
    queryKey: ['distribution-gaps'],
    queryFn: async () => {
      const res = await fetch(`${API_BASE}/api/config/advanced/distributions/gaps`);
      if (!res.ok) throw new Error('Failed to fetch distribution gaps');
      return res.json();
    },
  });
}
