---
phase: 05-single-node-generation-ui
plan: 01
subsystem: ui
tags: [react, react-router, tanstack-query, zustand, sonner, toast, navigation]

# Dependency graph
requires:
  - phase: 04-frontend-streaming-client
    provides: useGenerateNode hook with streaming state management
  - phase: 03-quality-control
    provides: Critic scoring with threshold-based quality gates
provides:
  - Complete Quick Generate save workflow with database persistence
  - User feedback via toast notifications for success/error/cancellation
  - Navigation to node detail page after successful save
  - Stream cleanup on component unmount
  - Conditional regenerate button for low-quality generations
affects: [06-bulk-generation-ui, 07-parallel-generation]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Toast notifications via sonner for user feedback
    - Type-specific node creation with discriminated union handling
    - Cleanup effects with useEffect for stream lifecycle

key-files:
  created: []
  modified:
    - packages/frontend/src/components/generation/QuickGenerate.tsx
    - packages/frontend/src/components/generation/GenerationProgress.tsx

key-decisions:
  - "Type-specific defaults: Provide minimal type-specific fields (enemyTypeHooks, consequenceHooks, etc.) for quick generation without manual input"
  - "Toast feedback pattern: Use sonner for success/error/info notifications (cancel, save success, save error)"
  - "Fresh form values on retry: handleRetry re-submits current form values instead of captured values to support mid-generation edits"
  - "Threshold visibility: Explicitly pass threshold=70 to GenerationProgress for clarity"

patterns-established:
  - "Node save pattern: Build discriminated union from generated content + form metadata with type-specific defaults"
  - "Stream cleanup pattern: useEffect cleanup function calls abort() on unmount to prevent memory leaks"
  - "Quality-based UX: Show both Accept and Regenerate buttons when score < threshold, giving users choice"

# Metrics
duration: 5min
completed: 2026-01-26
---

# Phase 5 Plan 1: Quick Generate Save Workflow Summary

**Complete save workflow from generated content to persisted node with toast feedback, navigation, stream cleanup, and quality-based regeneration**

## Performance

- **Duration:** 5 min
- **Started:** 2026-01-26T04:17:11Z
- **Completed:** 2026-01-26T04:21:48Z
- **Tasks:** 4
- **Files modified:** 2

## Accomplishments
- Accept button saves generated content to database via useCreateNode mutation
- Toast notifications for save success, save errors, and cancellation
- Navigation to /nodes/:id after successful save
- useEffect cleanup aborts streaming on component unmount (prevents memory leaks)
- Conditional Regenerate button appears when criticScore < 70 threshold

## Task Commits

Each task was committed atomically:

1. **Task 1: Add save handler to QuickGenerate with navigation** - `a029cca` (feat)
2. **Task 2: Add useEffect cleanup and cancel handler with toast** - `3ef2d53` (feat)
3. **Task 3: Add regenerate button for low quality scores** - `6cdd131` (feat)
4. **Task 4: Add conditional Retry button for low scores in GenerationProgress** - `963f780` (feat)

## Files Created/Modified
- `packages/frontend/src/components/generation/QuickGenerate.tsx` - Added save handler with type-specific node creation, stream cleanup on unmount, cancel with toast, and fresh form values on retry
- `packages/frontend/src/components/generation/GenerationProgress.tsx` - Added conditional Regenerate button when score < threshold on completed stage

## Decisions Made

**Type-specific defaults for quick generation**
- Quick Generate provides minimal type-specific fields (enemyTypeHooks, consequenceHooks, dilemmaType, etc.) as defaults
- Enables zero-friction node creation without requiring manual entry of type-specific metadata
- Defaults are generic but valid (e.g., 'generic_enemy', 'practical' dilemma, 'safe' rest)
- Users can edit these fields later via full edit workflow

**Fresh form values on retry**
- handleRetry calls reset() then form.handleSubmit(onSubmit)() to use current form values
- Prevents stale data from captured closure values
- Enables users to tweak form inputs (name, acts, etc.) while viewing generated preview before regenerating

**Toast feedback pattern**
- Success: `${savedNode.name} has been created.` (personalized with node name)
- Error: Shows error.message or fallback 'Failed to save node'
- Cancel: 'Generation cancelled' (info toast)
- Uses sonner directly (not shadcn useToast wrapper)

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

**TypeScript type system for discriminated unions**
- Issue: createNodeMutation expects `Omit<AnyNodeMetadata, 'id'>` which is a discriminated union requiring type-specific fields
- Solution: Built type-specific node objects with if/else branches based on nodeType, providing required fields for each type
- Files: QuickGenerate.tsx handleAccept function
- Verification: TypeScript compilation passes, all union types satisfied

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

**Ready for bulk generation:**
- Single-node save workflow complete and tested
- Pattern established for building valid nodes from minimal input + generated content
- Toast feedback pattern ready to extend to bulk operations
- Quality threshold UX (conditional Regenerate) ready to apply to batch operations

**No blockers:**
- All planned functionality implemented
- TypeScript compilation clean
- Build succeeds
- Stream cleanup prevents memory leaks

---
*Phase: 05-single-node-generation-ui*
*Completed: 2026-01-26*
