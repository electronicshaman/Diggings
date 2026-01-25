/**
 * Circuit breaker for LLM completion calls
 * Prevents runaway costs when provider fails repeatedly
 */

import CircuitBreaker from 'opossum';
import { complete, type LLMCompletionOptions, type LLMCompletionResult } from './llm-client.js';

/**
 * Circuit breaker configuration based on ERR-01 requirements:
 * - Open after 50% failure rate in 10s window
 * - Require 5 requests before opening (prevent false positives)
 * - 60s timeout for slow LLM responses
 * - Auto-recovery attempt after 30s
 */
const circuitBreakerOptions: CircuitBreaker.Options = {
  timeout: 60000, // 60s - LLM calls can be slow
  errorThresholdPercentage: 50, // Open circuit after 50% failures
  resetTimeout: 30000, // Try recovery after 30s
  rollingCountTimeout: 10000, // 10s error window
  volumeThreshold: 5, // Require 5 requests before opening
  name: 'llm-completion',
};

/**
 * Fallback function when circuit breaker is open
 * Provides clear error message to user
 */
function fallback(): Promise<LLMCompletionResult> {
  throw new Error(
    'LLM service unavailable due to repeated failures. The circuit breaker is open. Please wait 30 seconds and try again.'
  );
}

/**
 * Create circuit breaker wrapping the complete() function
 */
const breaker = new CircuitBreaker<[LLMCompletionOptions], LLMCompletionResult>(
  complete,
  circuitBreakerOptions
);

// Set fallback
breaker.fallback(fallback);

// Event listeners for monitoring
breaker.on('open', () => {
  console.error('[Circuit Breaker] OPEN - LLM calls failing repeatedly. Entering fail-fast mode.');
});

breaker.on('halfOpen', () => {
  console.log('[Circuit Breaker] HALF-OPEN - Attempting recovery. Testing LLM provider...');
});

breaker.on('close', () => {
  console.log('[Circuit Breaker] CLOSED - LLM provider recovered. Normal operation resumed.');
});

/**
 * Complete an LLM request with circuit breaker protection
 * This is the primary function used by completeWithRetry()
 */
export async function completeWithCircuitBreaker(
  options: LLMCompletionOptions
): Promise<LLMCompletionResult> {
  return breaker.fire(options);
}

/**
 * Get circuit breaker state for monitoring
 * Returns current state and statistics
 */
export function getCircuitBreakerState(): {
  state: string;
  stats: {
    fires: number;
    failures: number;
    successes: number;
    rejects: number;
    timeouts: number;
    fallbacks: number;
    semaphoreRejections: number;
  };
} {
  return {
    state: breaker.opened ? 'open' : breaker.halfOpen ? 'half-open' : 'closed',
    stats: breaker.stats,
  };
}
