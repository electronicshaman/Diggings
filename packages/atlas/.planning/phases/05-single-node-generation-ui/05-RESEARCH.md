# Phase 5: Single-Node Generation UI - Research

**Researched:** 2026-01-26
**Domain:** React UI for streaming AI generation with preview, regenerate, cancel, and save workflows
**Confidence:** HIGH

## Summary

Phase 5 creates the complete Quick Generate user flow: minimal form input (type + biome + name + acts) → real-time streaming generation with 3-stage progress display → preview generated content → accept/regenerate controls → save to database. This is the primary user-facing feature that makes AI generation accessible.

The technical infrastructure is already complete: backend SSE streaming works (Phase 1), generation pipeline is wired (Phase 2), quality control is integrated (Phase 3), and the frontend streaming client with Zustand persistence is ready (Phase 4). Components exist but need integration.

**Key findings:**
- QuickGenerate.tsx exists with form and useGenerateNode hook wired
- GenerationProgress.tsx displays 3-stage pipeline with quality feedback
- QualityFeedback.tsx shows critic breakdown with issues/strengths
- Zustand generation store persists state across page refresh
- Missing: Save to database button, regenerate action, cancel streaming, node detail navigation

**Primary recommendation:** Enhance QuickGenerate component to add save/regenerate/navigate controls. Wire GenerationProgress accept button to call POST /api/nodes with generated content. Add abort controller integration for cancel.

## Standard Stack

The established libraries/tools for this domain:

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| React Hook Form | 7.53+ | Form state management | Industry standard for controlled forms, minimal re-renders, Zod integration |
| @hookform/resolvers | 3.9+ | Zod resolver for RHF | Official adapter for Zod validation in React Hook Form |
| Zustand | 4.5+ | Client state (generation) | Lightweight (1KB), persist middleware, already used in codebase |
| TanStack Query | 5.62+ | Server state | Already used for nodes API, cache invalidation on save |
| shadcn/ui | Latest | Component library | Already installed (19 components), Radix UI primitives, Tailwind styling |
| Zod | 3.22+ | Schema validation | Shared between frontend/backend, runtime type safety |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| React Router | 6.22+ | Client-side routing | Navigate to node detail after save, already in use |
| EventSource API | Native | SSE client | Browser native, polyfill not needed (modern browsers only) |
| Sonner | 1.5+ | Toast notifications | Already integrated in main.tsx, used for save confirmations |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Zustand | Jotai | Atomic state management, but Zustand already established in codebase |
| TanStack Query | SWR | Simpler API but less control over cache invalidation |
| EventSource | fetch streams | More control but EventSource handles reconnection automatically |

**Installation:**
```bash
# All dependencies already installed
# No additional packages needed for Phase 5
```

## Architecture Patterns

### Recommended Project Structure
Already in place from Phases 1-4:
```
packages/frontend/src/
├── components/generation/
│   ├── QuickGenerate.tsx         # Form + streaming integration (ENHANCE)
│   ├── GenerationProgress.tsx    # 3-stage progress display (COMPLETE)
│   ├── QualityFeedback.tsx       # Critic breakdown (COMPLETE)
│   └── index.ts                  # Exports
├── hooks/
│   ├── useGeneration.ts          # Streaming hook with Zustand (COMPLETE)
│   ├── useNodeMutations.ts       # Create/update/delete mutations (ADD save mutation)
│   └── useConfig.ts              # Biome config queries (COMPLETE)
├── store/
│   ├── generation-store.ts       # Zustand store with persist (COMPLETE)
│   └── ui-store.ts               # UI preferences (COMPLETE)
├── lib/
│   └── streaming.ts              # SSE client (COMPLETE)
└── routes/
    └── generate/index.tsx        # Route with 3 tabs (COMPLETE)
```

### Pattern 1: Streaming Generation with Preview Workflow

**What:** User submits form → stream generation → preview content → accept (save) or regenerate

**When to use:** For Quick Generate (minimal input) and Assisted Create (hybrid mode) flows

**Example:**
```typescript
// Source: Existing QuickGenerate.tsx + enhancement
export function QuickGenerate() {
  const { state, generate, abort, reset, isGenerating } = useGenerateNode();
  const createNodeMutation = useCreateNode(); // TanStack Query mutation
  const navigate = useNavigate();
  const { toast } = useToast();

  const form = useForm<QuickGenerateFormData>({
    resolver: zodResolver(quickGenerateSchema),
    defaultValues: { nodeType: 'combat', biome: 'township', name: '', acts: [1] },
  });

  const onSubmit = async (data: QuickGenerateFormData) => {
    const request: GenerationRequest = {
      nodeType: data.nodeType,
      biome: data.biome,
      name: data.name,
      acts: data.acts,
      themes: biomeConfig?.themes?.slice(0, 2) || ['survival'],
      entityTypes: ['character'],
      actVariant: false,
    };

    try {
      await generate(request);
      // Stream completes, state.stage becomes 'completed'
    } catch (error) {
      // Error handled in state.error
    }
  };

  const handleAccept = async () => {
    if (!state.content) return;

    try {
      // Save generated content to database via POST /api/nodes
      const savedNode = await createNodeMutation.mutateAsync({
        type: form.getValues('nodeType'),
        biome: form.getValues('biome'),
        name: form.getValues('name'),
        acts: form.getValues('acts'),
        themes: biomeConfig?.themes?.slice(0, 2) || ['survival'],
        entityTypes: ['character'],
        content: state.content, // Use generated content
        criticScore: state.criticScore,
        isReplaceable: true,
        replacementTags: [],
      });

      toast({
        title: 'Node saved!',
        description: `${savedNode.name} has been created.`,
      });

      // Navigate to node detail
      navigate(`/nodes/${savedNode.nodeId}`);

      // Reset form and state
      reset();
      form.reset();
    } catch (error) {
      toast({
        variant: 'destructive',
        title: 'Save failed',
        description: error instanceof Error ? error.message : 'Unknown error',
      });
    }
  };

  const handleRetry = () => {
    // Retry with same form values
    form.handleSubmit(onSubmit)();
  };

  const handleCancel = () => {
    abort(); // Abort SSE stream
    reset(); // Clear Zustand state
  };

  // Show form if idle, otherwise show progress
  if (state.stage !== 'idle') {
    return (
      <GenerationProgress
        state={state}
        onCancel={handleCancel}
        onRetry={handleRetry}
        onAccept={handleAccept}
        showContent
        threshold={70}
      />
    );
  }

  return (
    <Card>
      <CardHeader>
        <CardTitle>Quick Generate</CardTitle>
        <CardDescription>Generate a complete node with minimal input</CardDescription>
      </CardHeader>
      <CardContent>
        <Form {...form}>
          <form onSubmit={form.handleSubmit(onSubmit)}>
            {/* Form fields: nodeType, biome, name, acts */}
            <Button type="submit" disabled={isGenerating}>
              <Sparkles className="mr-2" />
              Generate Node
            </Button>
          </form>
        </Form>
      </CardContent>
    </Card>
  );
}
```

**Key insight:** Save happens AFTER preview, not during streaming. SSE streaming generates content without database persistence, user accepts/rejects in UI, then frontend calls POST /api/nodes to save.

### Pattern 2: Cancel In-Flight Generation

**What:** User clicks Cancel button → abort EventSource connection → update Zustand state to idle

**When to use:** During streaming stages (outlining, expanding, reviewing) before completion

**Example:**
```typescript
// Source: useGeneration.ts + streaming.ts (already implemented)
// abort() function in useGeneration hook:
const abort = useCallback(() => {
  if (streamRef.current) {
    streamRef.current.abort(); // Calls abortController.abort() in streaming.ts
    streamRef.current = null;
  }
  useGenerationStore.getState().updateProgress({
    stage: 'idle',
    error: 'Generation cancelled',
  });
}, []);

// In QuickGenerate component:
<Button variant="outline" onClick={() => abort()}>
  Cancel
</Button>
```

**Key insight:** Abort is client-side only. Backend job continues but frontend disconnects. This is acceptable because jobs auto-expire after 24 hours and user can reconnect if they change their mind (via Zustand persistence).

### Pattern 3: Regenerate with Same Parameters

**What:** User clicks Retry/Regenerate button → re-submit same form values → start new generation stream

**When to use:** When user is unsatisfied with quality score or content preview

**Example:**
```typescript
// Source: QuickGenerate.tsx pattern
const handleRetry = () => {
  // Reset state to clear previous result
  reset();

  // Re-submit form with current values (don't reset form)
  form.handleSubmit(onSubmit)();
};

// In GenerationProgress:
{stage === 'error' && (
  <Button variant="outline" onClick={onRetry}>
    Retry
  </Button>
)}
{stage === 'completed' && criticScore < threshold && (
  <Button variant="outline" onClick={onRetry}>
    Regenerate (Quality: {criticScore}/100)
  </Button>
)}
```

**Key insight:** Retry preserves form values but creates a new generation request. User doesn't have to re-enter data. Quality threshold check (70) determines if regenerate button is shown alongside accept.

### Pattern 4: Save Generated Content to Database

**What:** User accepts preview → frontend calls POST /api/nodes with generated content → invalidate TanStack Query cache → navigate to node detail

**When to use:** After generation completes and user clicks Accept/Save button

**Example:**
```typescript
// Source: useNodeMutations.ts (create mutation)
export function useCreateNode() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (data: CreateNodeData) => {
      const response = await fetch('/api/nodes', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data),
      });

      if (!response.ok) {
        const error = await response.json().catch(() => ({ error: 'Request failed' }));
        throw new Error(error.error || 'Failed to create node');
      }

      return response.json();
    },
    onSuccess: () => {
      // Invalidate nodes list query to trigger refetch
      queryClient.invalidateQueries({ queryKey: ['nodes'] });
    },
  });
}

// In QuickGenerate:
const createNodeMutation = useCreateNode();

const handleAccept = async () => {
  const savedNode = await createNodeMutation.mutateAsync({
    type: form.getValues('nodeType'),
    biome: form.getValues('biome'),
    name: form.getValues('name'),
    content: state.content, // Generated by AI
    criticScore: state.criticScore,
    // ... other fields
  });

  navigate(`/nodes/${savedNode.nodeId}`);
};
```

**Key insight:** POST /api/nodes is the standard CRUD endpoint, already implemented. No special "save AI node" endpoint needed. Generated content is just another node creation.

### Anti-Patterns to Avoid

- **Anti-pattern 1: Save during streaming** - Don't call POST /api/nodes during SSE streaming. User must preview first. Backend streaming.ts already saves on completion (Phase 2 decision), but Quick Generate flow should allow user to reject before database write.
  - **Solution:** Backend saves on streaming completion (for batch), but Quick Generate preview-first flow uses client-side save button.

- **Anti-pattern 2: EventSource manual reconnection** - Don't manually reconnect EventSource after abort(). Let Zustand persistence handle job recovery on page refresh.
  - **Solution:** Use abort() for intentional cancellation. Job recovery (Phase 4) handles unintentional disconnections.

- **Anti-pattern 3: Duplicate form state in Zustand** - Don't store form values in generation-store.ts. React Hook Form is source of truth for input.
  - **Solution:** Zustand stores generation results only (outline, content, critic). Form state stays in useForm().

## Don't Hand-Roll

Problems that look simple but have existing solutions:

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Form validation | Custom onChange validators | React Hook Form + Zod | Handles touched/dirty state, async validation, field arrays |
| SSE reconnection | setInterval polling | Zustand persist + reconnectToJob | Job recovery on mount (Phase 4), exponential backoff |
| Toast notifications | Custom overlay components | Sonner (already installed) | Accessible, stacked toasts, promise handling |
| Progress bars | <div> with width: ${percent}% | shadcn/ui Progress | Accessible (role="progressbar"), smooth transitions |
| Modal dialogs | Custom z-index management | shadcn/ui Dialog | Focus trap, escape key, overlay click, accessible |

**Key insight:** Frontend already has 19 shadcn/ui components installed. Use them consistently for UI primitives. Don't create custom button/card/dialog components.

## Common Pitfalls

### Pitfall 1: Race Condition Between Save and Navigation

**What goes wrong:** User clicks Accept → save mutation starts → navigate() fires before mutation completes → mutation succeeds but user sees old node list

**Why it happens:** async/await not properly awaited, navigate() called optimistically

**How to avoid:**
```typescript
const handleAccept = async () => {
  try {
    // MUST await mutation before navigate
    const savedNode = await createNodeMutation.mutateAsync({...});

    // THEN navigate (mutation completed)
    navigate(`/nodes/${savedNode.nodeId}`);
  } catch (error) {
    // Handle error, don't navigate
  }
};
```

**Warning signs:** User navigates to node detail but sees "Node not found", then page loads after delay

### Pitfall 2: Stale Form Values After Regenerate

**What goes wrong:** User edits form fields while generation is streaming → clicks Regenerate → new generation uses old values

**Why it happens:** Form values captured at submit time, not at regenerate time

**How to avoid:**
```typescript
const handleRetry = () => {
  // Always get fresh form values
  const currentValues = form.getValues();

  // Convert to GenerationRequest
  const request = buildGenerationRequest(currentValues);

  // Start new generation
  reset();
  generate(request);
};
```

**Warning signs:** User changes node type from combat to choice, clicks Regenerate, still generates combat node

### Pitfall 3: Memory Leak from Unaborted Streams

**What goes wrong:** User navigates away from /generate page while streaming → EventSource connection stays open → memory leak

**Why it happens:** useEffect cleanup not implemented

**How to avoid:**
```typescript
// In QuickGenerate or any component using useGenerateNode
useEffect(() => {
  return () => {
    // Cleanup on unmount
    if (isGenerating) {
      abort();
    }
  };
}, [isGenerating, abort]);
```

**Warning signs:** Browser network tab shows ongoing SSE connections after navigation, memory usage grows over time

### Pitfall 4: Lost Content on Page Refresh During Preview

**What goes wrong:** User generates content → sees preview → refreshes page → content lost

**Why it happens:** Zustand persist middleware only stores job metadata, not full content (too large for localStorage)

**How to avoid:** This is acceptable behavior (design decision). Job recovery (Phase 4) can fetch completed job status from backend, but content won't be in localStorage. Alternative: Add "Download JSON" button to export generated content before accepting.

**Warning signs:** User reports "I had a good generation but lost it after refresh"

## Code Examples

Verified patterns from existing codebase:

### Example 1: Quick Generate Form Submission
```typescript
// Source: packages/frontend/src/components/generation/QuickGenerate.tsx (lines 66-82)
const onSubmit = async (data: QuickGenerateFormData) => {
  const request: GenerationRequest = {
    nodeType: data.nodeType,
    biome: data.biome,
    name: data.name,
    acts: data.acts as [number, ...number[]],
    themes: biomeConfig?.themes?.slice(0, 2) || ['survival'],
    entityTypes: ['character'],
    actVariant: false,
  };

  try {
    await generate(request); // Starts SSE stream
  } catch {
    // Error handled in state.error
  }
};
```

### Example 2: Generation Progress Display with Actions
```typescript
// Source: packages/frontend/src/components/generation/GenerationProgress.tsx (lines 142-157)
{stage !== 'idle' && stage !== 'completed' && stage !== 'error' && onCancel && (
  <Button variant="outline" onClick={onCancel}>
    Cancel
  </Button>
)}
{stage === 'error' && onRetry && (
  <Button variant="outline" onClick={onRetry}>
    Retry
  </Button>
)}
{stage === 'completed' && onAccept && (
  <Button onClick={onAccept}>Accept & Save</Button>
)}
```

### Example 3: TanStack Query Node Creation Mutation
```typescript
// Source: packages/frontend/src/hooks/useNodeMutations.ts (NEEDS IMPLEMENTATION)
export function useCreateNode() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (data: AnyNodeMetadata) => {
      const response = await fetch('/api/nodes', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data),
      });

      if (!response.ok) {
        throw new Error('Failed to create node');
      }

      return response.json();
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['nodes'] });
    },
  });
}
```

### Example 4: Zustand State Selection for UI
```typescript
// Source: packages/frontend/src/hooks/useGeneration.ts (lines 30-39)
const state = useGenerationStore((state) => ({
  stage: state.activeJob?.stage ?? 'idle',
  progress: state.activeJob?.progress ?? 0,
  message: state.activeJob?.message,
  outline: state.activeJob?.outline,
  content: state.activeJob?.content,
  criticScore: state.activeJob?.criticScore,
  criticResult: state.activeJob?.criticResult,
  error: state.activeJob?.error,
}));
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Polling for progress | SSE streaming | Phase 1 (2026-01-25) | Real-time updates, no request spam |
| Generate + auto-save | Preview-first workflow | Phase 5 design | User control, quality gate |
| Simple numeric score | Rich critic feedback | Phase 3 (2026-01-25) | Actionable quality insights |
| useState for generation state | Zustand with persist | Phase 4 (2026-01-26) | Survives page refresh, reconnection |

**Deprecated/outdated:**
- **Direct EventSource usage**: Now wrapped in streamGeneration() utility (packages/frontend/src/lib/streaming.ts)
- **Manual retry loops**: Now handled by useGenerateNode hook with Zustand state
- **Component-local generation state**: Now centralized in generation-store.ts

## Open Questions

Things that couldn't be fully resolved:

1. **Should regenerate clear previous content preview?**
   - What we know: Current implementation clears via reset()
   - What's unclear: Should user be able to compare old/new generations side-by-side?
   - Recommendation: Clear for v1 (simpler UI), defer comparison view to Phase 6 (field-level assists)

2. **How to handle large content in localStorage?**
   - What we know: Zustand persist stores activeJob with outline/content
   - What's unclear: localStorage has 5-10MB limit, large nodes may exceed
   - Recommendation: Monitor size, add warning if content > 1MB, suggest user accept/save immediately

3. **Should cancel API terminate backend job?**
   - What we know: Current abort() only closes frontend EventSource
   - What's unclear: Backend job continues running, wasting LLM tokens
   - Recommendation: Add DELETE /api/generate/job/:jobId endpoint in Phase 7 (batch processing), defer for Phase 5

4. **Where to navigate after save?**
   - What we know: Node detail page (/nodes/:id) is logical target
   - What's unclear: Should user go to detail or stay on /generate to create another?
   - Recommendation: Navigate to detail (celebration of success), user can use browser back or sidebar to return

## Sources

### Primary (HIGH confidence)
- [Existing codebase] packages/frontend/src/components/generation/QuickGenerate.tsx - Form and streaming integration
- [Existing codebase] packages/frontend/src/hooks/useGeneration.ts - Zustand-based streaming hook
- [Existing codebase] packages/frontend/src/store/generation-store.ts - Persist middleware implementation
- [Existing codebase] packages/backend/src/routes/generate.ts - POST /api/nodes endpoint for save
- [Existing codebase] Phase 4 PLAN (04-01-PLAN.md) - Job recovery and reconnection patterns

### Secondary (MEDIUM confidence)
- React Hook Form docs (2026) - Form state management patterns
- TanStack Query docs v5 (2026) - Mutation patterns and cache invalidation
- shadcn/ui components (2026) - Button, Card, Dialog, Progress usage

### Tertiary (LOW confidence)
- None - all patterns verified in existing codebase

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - All libraries already in use, versions verified in package.json
- Architecture: HIGH - Components exist, patterns established in Phases 1-4
- Pitfalls: HIGH - Race conditions and cleanup issues common in streaming UIs

**Research date:** 2026-01-26
**Valid until:** 2026-02-26 (30 days - stable domain, no fast-moving dependencies)

**Codebase readiness:**
- QuickGenerate.tsx: 70% complete (form/streaming wired, save/navigation missing)
- GenerationProgress.tsx: 100% complete (all action buttons present)
- QualityFeedback.tsx: 100% complete (critic breakdown display ready)
- useGeneration.ts: 100% complete (streaming hook with abort/reset)
- generation-store.ts: 100% complete (Zustand persist with job recovery)

**Estimated implementation effort:**
- Enhance QuickGenerate with save handler: 30 min
- Add useCreateNode mutation hook: 20 min
- Wire navigation after save: 10 min
- Add useEffect cleanup for unmount: 10 min
- Test full workflow (generate → preview → accept → navigate): 30 min
- **Total:** ~2 hours
