---
phase: 03-quality-control
plan: 01
subsystem: api
tags: [zod, validation, quality-control, retry-logic, generation-pipeline]

# Dependency graph
requires:
  - phase: 02-core-generation-pipeline
    provides: batch-processor with generation stages and transient error retries
provides:
  - Zod-based content validation before database save
  - Quality-based retry loop for low critic scores
  - Validation error reporting in SSE events
affects: [04-prompt-engineering, 05-batch-orchestration, 06-ui-integration]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Inner quality retry loop separate from outer transient retry loop"
    - "Validation checkpoint that fails immediately without retry"
    - "Best attempt tracking across quality retries"

key-files:
  created:
    - packages/backend/src/services/generation/content-validator.ts
  modified:
    - packages/backend/src/services/generation/batch-processor.ts
    - packages/backend/src/services/generation/streaming.ts

key-decisions:
  - "Quality retries capped at 2 attempts (maxQualityRetries parameter)"
  - "Validation failures fail immediately - no retry (structural issues)"
  - "validation.success gates quality retry decision (first condition in shouldRetry)"
  - "Quality retry only when: validation.success AND score < threshold AND no critical severity AND retries remaining"
  - "Best attempt tracking returns highest-scoring result on exhaustion"

patterns-established:
  - "Pattern 1: Two-layer retry architecture - inner quality loop, outer transient error loop"
  - "Pattern 2: ValidationResult interface with success/data/errors for type-safe validation"
  - "Pattern 3: Validation errors formatted as 'path.to.field: error message' for debugging"

# Metrics
duration: 2min
completed: 2026-01-25
---

# Phase 3 Plan 1: Quality Control Summary

**Zod validation layer with quality-based retry loop (max 2 attempts) ensures structurally valid content before database save**

## Performance

- **Duration:** 2 min
- **Started:** 2026-01-25T09:00:18Z
- **Completed:** 2026-01-25T09:02:47Z
- **Tasks:** 3
- **Files modified:** 3

## Accomplishments
- Content validator module using shared Zod schemas validates structure before save
- Quality retry loop in batch-processor automatically retries when critic score below threshold
- Validation checkpoint prevents quality retries on structural failures (immediate fail)
- SSE streaming endpoint validates content and reports errors before database save

## Task Commits

Each task was committed atomically:

1. **Task 1: Create content-validator.ts with Zod validation** - `e4c53e0` (feat)
2. **Task 2: Add quality retry loop to batch-processor.ts** - `af1c71c` (feat)
3. **Task 3: Add validation to streaming endpoint before database save** - `c25b2e4` (feat)

## Files Created/Modified
- `packages/backend/src/services/generation/content-validator.ts` - Zod validation using NodeContentSchema from @node-gen-web/shared
- `packages/backend/src/services/generation/batch-processor.ts` - Inner quality retry loop with maxQualityRetries parameter (default 2)
- `packages/backend/src/services/generation/streaming.ts` - Validation before database save with validationError in SSE complete event

## Decisions Made

- **Quality retry limit:** Set maxQualityRetries to 2 (3 total attempts including initial) - balances quality improvement vs generation time
- **Validation gates retry:** validation.success is first condition in shouldRetry expression - structural failures never retry
- **Best attempt tracking:** Keep highest-scoring attempt across retries, return on exhaustion to avoid wasted work
- **Validation vs quality:** Validation failures are structural (immediate fail), quality failures are score-based (retry if no critical issues)

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None - all tasks completed as planned with no blockers.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

**Ready for Phase 4 (Prompt Engineering):**
- Validation layer ensures generated content matches expected schema
- Quality retry loop provides feedback mechanism for prompt tuning
- Critic scoring rubric can be calibrated with validation guarantees
- SSE events include validation errors for debugging prompt issues

**Quality foundation complete:**
- Validation separates structural failures from quality issues
- Retry logic provides automatic quality improvement
- Best attempt tracking prevents total failures on exhaustion
- Database save protected by validation safety net

---
*Phase: 03-quality-control*
*Completed: 2026-01-25*
