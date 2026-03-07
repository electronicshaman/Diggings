/**
 * Generation services index
 * Exports all LLM-based content generation functionality
 */

// LLM Client
export {
  complete,
  completeWithRetry,
  parseJsonResponse,
  getActiveProvider,
  encryptApiKey,
  type LLMProvider,
  type LLMProviderType,
  type LLMCompletionOptions,
  type LLMCompletionResult,
} from './llm-client.js';

// Circuit Breaker
export { getCircuitBreakerState } from './circuit-breaker.js';

// Error Handler
export { classifyLLMError, calculateRetryDelay, type LLMError } from './error-handler.js';

// Prompt Builder
export {
  getBiomeTone,
  getActTone,
  formatBiomeToneForPrompt,
  formatAntipatternsForPrompt,
  formatActToneForPrompt,
  getVernacularHint,
  getExemplarHint,
  buildNodeContext,
  type BiomeTone,
  type ActTone,
  type NodeGenerationContext,
} from './prompt-builder.js';

// Beat Outliner
export {
  generateBeatOutline,
  BEAT_OUTLINER_SYSTEM_PROMPT,
  type BeatOutline,
  type BeatTemplate,
  type BeatSequence,
} from './beat-outliner.js';

// Prose Expander
export {
  expandBeatsToProse,
  PROSE_EXPANDER_SYSTEM_PROMPT,
  type ExpandedContent,
  type StoryBeat,
  type OutcomeText,
  type ChoiceOption,
} from './prose-expander.js';

// Critic
export {
  evaluateContent,
  CRITIC_SYSTEM_PROMPT,
  type CriticResult,
  type CriticIssue,
} from './critic.js';

// Batch Processor
export {
  generateBatch,
  generateSingle,
  type NodeGenerationRequest,
  type GenerationProgress,
  type BatchGenerationResult,
  type ProgressCallback,
} from './batch-processor.js';

// Streaming
export {
  streamGeneration,
  createSSEStream,
  streamSSE,
  type SSEMessage,
  type SSEMessageType,
} from './streaming.js';

// Job Tracker
export {
  createJob,
  updateJobStatus,
  getJob,
  cleanupOldJobs,
  type JobStatus,
  type JobUpdate,
} from './job-tracker.js';
