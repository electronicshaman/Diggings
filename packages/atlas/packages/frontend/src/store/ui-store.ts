import { create } from 'zustand';
import { persist } from 'zustand/middleware';

interface NodeFilters {
  type?: string;
  biome?: string;
  acts?: number[];
  search?: string;
}

interface UIState {
  filters: NodeFilters;
  viewMode: 'cards' | 'table';
  setFilters: (filters: Partial<NodeFilters>) => void;
  resetFilters: () => void;
  setViewMode: (mode: 'cards' | 'table') => void;
}

export const useUIStore = create<UIState>()(
  persist(
    (set) => ({
      filters: {},
      viewMode: 'cards',
      setFilters: (newFilters) =>
        set((state) => ({ filters: { ...state.filters, ...newFilters } })),
      resetFilters: () => set({ filters: {} }),
      setViewMode: (viewMode) => set({ viewMode }),
    }),
    { name: 'node-gen-ui' }
  )
);
