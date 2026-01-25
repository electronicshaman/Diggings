/**
 * Content validator - Zod-based validation for generated content
 * Validates structure before database save using shared schemas
 */

import { NodeContentSchema } from '@node-gen-web/shared';
import { z } from 'zod';

export interface ValidationResult<T> {
  success: boolean;
  data?: T;
  errors?: string[];
}

/**
 * Validate node content against Zod schema
 * Returns structured validation result with formatted errors
 */
export function validateNodeContent(content: unknown): ValidationResult<z.infer<typeof NodeContentSchema>> {
  const result = NodeContentSchema.safeParse(content);

  if (result.success) {
    return { success: true, data: result.data };
  }

  return {
    success: false,
    errors: result.error.errors.map(err => `${err.path.join('.')}: ${err.message}`)
  };
}
