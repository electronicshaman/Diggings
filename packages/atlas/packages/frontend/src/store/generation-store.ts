import { create } from 'zustand';
import { persist } from 'zustand/middleware';
import type { GenerationStage, CriticResult } from '@atlas/shared';

const JOB_MAX_AGE_MS = 24 * 60 * 60 * 1000; // 24 hours

export interface GenerationJob {
  jobId: string;
  stage: GenerationStage;
  progress: number;
  message?: string;
  outline?: unknown;
  content?: unknown;
  criticScore?: number;
  criticResult?: CriticResult;
  error?: string;
  startedAt: number; // timestamp for age checking
}

interface GenerationState {
  activeJob: GenerationJob | null;
  connectionAttempts: number;

  // Actions
  setJob: (job: GenerationJob) => void;
  updateProgress: (update: Partial<GenerationJob>) => void;
  clearJob: () => void;
  incrementRetry: () => void;
  resetRetry: () => void;
}

export const useGenerationStore = create<GenerationState>()(
  persist(
    (set) => ({
      activeJob: null,
      connectionAttempts: 0,

      setJob: (job) => set({ activeJob: job }),

      updateProgress: (update) =>
        set((state) => ({
          activeJob: state.activeJob ? { ...state.activeJob, ...update } : null,
        })),

      clearJob: () => set({ activeJob: null }),

      incrementRetry: () =>
        set((state) => ({ connectionAttempts: state.connectionAttempts + 1 })),

      resetRetry: () => set({ connectionAttempts: 0 }),
    }),
    {
      name: 'node-gen-generation',
      version: 1,
      // Only persist activeJob, not connectionAttempts (ephemeral)
      partialize: (state) => ({ activeJob: state.activeJob }),
      // Merge function to discard stale jobs on hydration
      merge: (persistedState, currentState) => {
        const persisted = persistedState as Partial<GenerationState>;

        // Check if persisted job is stale
        if (persisted.activeJob) {
          const age = Date.now() - persisted.activeJob.startedAt;
          if (age > JOB_MAX_AGE_MS) {
            // Job too old, discard it
            return {
              ...currentState,
              activeJob: null,
            };
          }
        }

        // Job is fresh enough, keep it
        return {
          ...currentState,
          activeJob: persisted.activeJob ?? null,
        };
      },
    }
  )
);
