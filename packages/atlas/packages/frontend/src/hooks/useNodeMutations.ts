import { useMutation, useQueryClient } from '@tanstack/react-query';
import { createNode, updateNode, deleteNode } from '../lib/api';
import type { AnyNodeMetadata } from '@node-gen-web/shared';

export function useCreateNode() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (data: Omit<AnyNodeMetadata, 'id'>) => createNode(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['nodes'] });
      queryClient.invalidateQueries({ queryKey: ['nodeStats'] });
    },
  });
}

export function useUpdateNode() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({ nodeId, data }: { nodeId: string; data: Partial<AnyNodeMetadata> }) =>
      updateNode(nodeId, data),
    onSuccess: (updatedNode) => {
      queryClient.invalidateQueries({ queryKey: ['nodes'] });
      queryClient.invalidateQueries({ queryKey: ['node', updatedNode.id] });
      queryClient.invalidateQueries({ queryKey: ['nodeStats'] });
    },
  });
}

export function useDeleteNode() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (nodeId: string) => deleteNode(nodeId),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['nodes'] });
      queryClient.invalidateQueries({ queryKey: ['nodeStats'] });
    },
  });
}
