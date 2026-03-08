// TypeScript types for generation schemas
// Re-export from schemas for convenience

export type {
  BeatOutline,
  ExpandedContent,
  CriticResult,
  GenerationRequest,
  BulkGenerationRequest,
  ProgressEvent,
  GenerationResponse,
  BatchGenerationResponse,
  CardGenerationRequest,
  BulkCardGenerationRequest,
} from '../schemas/generation.js';

// Extract CriticIssue type from CriticResult
import type { CriticResult as CR } from '../schemas/generation.js';
export type CriticIssue = CR['issues'][number];

// Re-export generation stages for frontend use
export type GenerationStage = 'idle' | 'outlining' | 'expanding' | 'reviewing' | 'completed' | 'error';
