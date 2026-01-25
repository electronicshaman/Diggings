/**
 * LLM error classification and user-friendly message generation
 * Provides structured error handling for all LLM provider errors
 */

export interface LLMError {
  retryable: boolean;
  userMessage: string;
  technicalMessage: string;
  httpStatus?: number;
  retryAfterMs?: number; // Parsed from Retry-After header if available
}

export function classifyLLMError(error: Error | unknown): LLMError {
  const errorMsg = error instanceof Error ? error.message : String(error);
  const lowerMsg = errorMsg.toLowerCase();

  // Auth errors (non-retryable)
  if (lowerMsg.includes('401') || lowerMsg.includes('invalid api key') ||
      lowerMsg.includes('unauthorized')) {
    return {
      retryable: false,
      userMessage: 'Authentication failed. Please check your API key in Settings > LLM Providers.',
      technicalMessage: errorMsg,
      httpStatus: 401,
    };
  }

  // Forbidden (non-retryable)
  if (lowerMsg.includes('403') || lowerMsg.includes('forbidden')) {
    return {
      retryable: false,
      userMessage: 'Access denied. Your API key may not have permission for this model.',
      technicalMessage: errorMsg,
      httpStatus: 403,
    };
  }

  // Bad request (non-retryable)
  if (lowerMsg.includes('400') || lowerMsg.includes('invalid_request') ||
      lowerMsg.includes('validation')) {
    return {
      retryable: false,
      userMessage: 'Invalid request. Please check your node configuration and try again.',
      technicalMessage: errorMsg,
      httpStatus: 400,
    };
  }

  // Rate limiting (retryable)
  if (lowerMsg.includes('429') || lowerMsg.includes('rate limit')) {
    return {
      retryable: true,
      userMessage: 'Rate limit reached. Automatically retrying with backoff...',
      technicalMessage: errorMsg,
      httpStatus: 429,
    };
  }

  // Service overload - Anthropic 529 (retryable)
  if (lowerMsg.includes('529') || lowerMsg.includes('overloaded')) {
    return {
      retryable: true,
      userMessage: 'LLM service is temporarily overloaded. Retrying...',
      technicalMessage: errorMsg,
      httpStatus: 529,
    };
  }

  // Service unavailable (retryable)
  if (lowerMsg.includes('503') || lowerMsg.includes('service unavailable')) {
    return {
      retryable: true,
      userMessage: 'LLM service temporarily unavailable. Retrying...',
      technicalMessage: errorMsg,
      httpStatus: 503,
    };
  }

  // Network errors (retryable)
  if (lowerMsg.includes('timeout') || lowerMsg.includes('econnrefused') ||
      lowerMsg.includes('enotfound') || lowerMsg.includes('network')) {
    return {
      retryable: true,
      userMessage: 'Network error occurred. Retrying...',
      technicalMessage: errorMsg,
    };
  }

  // Content filter (non-retryable)
  if (lowerMsg.includes('content_filter') || lowerMsg.includes('content_policy') ||
      lowerMsg.includes('safety')) {
    return {
      retryable: false,
      userMessage: 'Content rejected by safety filters. Try adjusting themes or node parameters.',
      technicalMessage: errorMsg,
      httpStatus: 400,
    };
  }

  // Circuit breaker open (non-retryable, wait required)
  if (lowerMsg.includes('circuit breaker') || lowerMsg.includes('breaker is open')) {
    return {
      retryable: false,
      userMessage: 'Generation service temporarily unavailable due to repeated failures. Please wait 30 seconds and try again.',
      technicalMessage: errorMsg,
      httpStatus: 503,
    };
  }

  // No active provider (non-retryable, config issue)
  if (lowerMsg.includes('no active') || lowerMsg.includes('no provider')) {
    return {
      retryable: false,
      userMessage: 'No LLM provider configured. Please add a provider in Settings > LLM Providers.',
      technicalMessage: errorMsg,
    };
  }

  // Default unknown error (non-retryable)
  return {
    retryable: false,
    userMessage: 'An unexpected error occurred. Please try again or check the logs for details.',
    technicalMessage: errorMsg,
  };
}

/**
 * Calculate retry delay with exponential backoff and jitter
 */
export function calculateRetryDelay(attempt: number, baseMs: number = 1000): number {
  const exponentialDelay = Math.pow(2, attempt) * baseMs;
  const jitter = Math.random() * 1000; // 0-1000ms random jitter
  return exponentialDelay + jitter;
}
