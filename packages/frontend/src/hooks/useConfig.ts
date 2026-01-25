import { useQuery } from '@tanstack/react-query';
import { getBiomes, getDistributions, getLookup } from '../lib/api';
import type { Biome } from '@node-gen-web/shared';

export function useBiomes() {
  return useQuery({
    queryKey: ['config', 'biomes'],
    queryFn: getBiomes,
    staleTime: Infinity,
  });
}

export function useDistributions() {
  return useQuery({
    queryKey: ['config', 'distributions'],
    queryFn: getDistributions,
    staleTime: Infinity,
  });
}

export function useLookup(type: string, biome?: Biome) {
  return useQuery({
    queryKey: ['config', 'lookup', type, biome],
    queryFn: () => getLookup(type, biome),
    enabled: !!type,
    staleTime: Infinity,
  });
}
