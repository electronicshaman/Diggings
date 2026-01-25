import { useQuery } from '@tanstack/react-query';
import { getNodes, getNode, getStats, type NodesParams } from '../lib/api';

export function useNodes(filters: NodesParams = {}) {
  return useQuery({
    queryKey: ['nodes', filters],
    queryFn: () => getNodes(filters),
  });
}

export function useNode(nodeId: string | undefined) {
  return useQuery({
    queryKey: ['node', nodeId],
    queryFn: () => getNode(nodeId!),
    enabled: !!nodeId,
  });
}

export function useNodeStats() {
  return useQuery({
    queryKey: ['nodeStats'],
    queryFn: getStats,
  });
}
