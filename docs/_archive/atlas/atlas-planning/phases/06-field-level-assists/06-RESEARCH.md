# Phase 6: Field-Level Assists - Research

**Researched:** 2026-01-26
**Domain:** AI-assisted form field generation with streaming inline buttons in manual node creation workflow
**Confidence:** HIGH

## Summary

Phase 6 adds field-level AI assist buttons to manual node creation forms, allowing users to generate individual fields (narrative hook, individual beats, choice options) without triggering full node generation. This is the "hybrid creation" mode: users manually fill base metadata but get AI help for creative writing tasks.

**Key architectural insight:** Field-level generation requires a different API pattern than full-node generation. The existing `/api/generate/stream` endpoint generates complete nodes through the 3-stage pipeline (outline → prose → critic). For field assists, we need targeted single-stage endpoints that generate only the requested field (e.g., just the narrative hook or just a single beat) without the full pipeline overhead.

**Current state:** AssistedCreate.tsx already has FieldAssistButton component and handleGenerateHook pattern, but it incorrectly calls the full generate() function which runs the 3-stage pipeline. The backend has individual stage functions (generateBeatOutline, expandBeatsToProse) but no endpoints that expose them individually for field-level requests.

**Primary recommendation:** Create new backend endpoints (`POST /api/generate/field/narrative-hook`, `POST /api/generate/field/beat`) that call individual pipeline stages. Use Vercel AI SDK's useCompletion hook pattern for streaming field content directly into form textareas. Add FieldAssistButton to BaseNodeForm content step and type-specific forms.

## Standard Stack

The established libraries/tools for this domain:

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| React Hook Form | 7.53+ | Form state management | Already used in all forms, setValue() API perfect for field updates |
| Vercel AI SDK | 4.x | Streaming AI completions | Industry standard for streaming text into UI, useCompletion hook designed for form fields |
| EventSource API | Native | SSE streaming | Already used in Phase 1-4 for full generation, can reuse for field streaming |
| Zod | 3.22+ | Schema validation | Shared schemas define what fields exist, which need assists |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Sonner | 1.5+ | Toast notifications | Already integrated, use for field generation errors |
| Zustand | 4.5+ | Ephemeral field state | Optional: track which field is currently generating to prevent concurrent requests |
| shadcn/ui Button | Latest | Assist button UI | Already used in AssistedCreate.tsx, reuse FieldAssistButton component |
| lucide-react | Latest | Wand2/Sparkles icons | Standard icons for AI assist actions |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| useCompletion (Vercel SDK) | Custom EventSource | More control but lose built-in state management, retry, abort |
| Field-specific endpoints | Single /generate/field endpoint with type param | Simpler backend but less type-safe, harder to document |
| Streaming | Non-streaming (fetch + await) | Simpler implementation but loses real-time feedback UX |

**Installation:**
```bash
# Add Vercel AI SDK to frontend
cd packages/frontend
pnpm add ai@latest

# No backend changes needed - Hono already supports SSE streaming
```

## Architecture Patterns

### Recommended Project Structure
```
packages/backend/src/routes/
├── generate.ts                    # Full node generation (Phase 1-5)
└── generate-field.ts              # NEW: Field-level generation endpoints

packages/backend/src/services/generation/
├── beat-outliner.ts               # Already exists, export for direct use
├── prose-expander.ts              # Already exists, has narrative_hook generation
└── field-generator.ts             # NEW: Thin wrappers for field-specific calls

packages/frontend/src/components/
├── forms/
│   ├── BaseNodeForm.tsx           # ENHANCE: Add narrative_hook assist (Step 3)
│   ├── CombatForm.tsx             # Already has type fields, no assists needed
│   ├── ChoiceForm.tsx             # ENHANCE: Add option generation assist
│   └── [other type forms]         # Type-specific fields, some may need assists
├── generation/
│   ├── FieldAssistButton.tsx      # Already exists in AssistedCreate, EXTRACT to standalone
│   └── StreamingTextarea.tsx      # NEW: Textarea with real-time streaming display
└── hooks/
    └── useFieldGeneration.ts      # NEW: Hook wrapping useCompletion for field generation
```

### Pattern 1: Inline Field Assist Button

**What:** Small button next to form field label that generates content for that specific field

**When to use:** Text fields where AI can provide creative value (narrative_hook, beat.text, option.description)

**Example:**
```typescript
// Source: Existing AssistedCreate.tsx FieldAssistButton (lines 59-85)
import { Wand2, Sparkles } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Tooltip, TooltipContent, TooltipProvider, TooltipTrigger } from '@/components/ui/tooltip';

interface FieldAssistButtonProps {
  onClick: () => void;
  isLoading?: boolean;
  disabled?: boolean;
  tooltip?: string;
}

export function FieldAssistButton({
  onClick,
  isLoading,
  disabled,
  tooltip = 'Generate with AI'
}: FieldAssistButtonProps) {
  return (
    <TooltipProvider>
      <Tooltip>
        <TooltipTrigger asChild>
          <Button
            type="button"
            variant="ghost"
            size="icon"
            className="size-8"
            onClick={onClick}
            disabled={disabled || isLoading}
          >
            {isLoading ? (
              <Sparkles className="size-4 animate-pulse" />
            ) : (
              <Wand2 className="size-4" />
            )}
          </Button>
        </TooltipTrigger>
        <TooltipContent>
          <p>{tooltip}</p>
        </TooltipContent>
      </Tooltip>
    </TooltipProvider>
  );
}

// Usage in form:
<FormField
  control={form.control}
  name="content.narrative_hook"
  render={({ field }) => (
    <FormItem>
      <div className="flex items-center justify-between">
        <FormLabel>Narrative Hook</FormLabel>
        <FieldAssistButton
          onClick={() => handleGenerateField('narrative_hook')}
          isLoading={generatingField === 'narrative_hook'}
          tooltip="Generate opening text with AI"
        />
      </div>
      <FormControl>
        <Textarea {...field} placeholder="Opening 1-3 sentences..." />
      </FormControl>
    </FormItem>
  )}
/>
```

**Key insight:** Button is small (size-8, ~32px), ghost variant blends with label, tooltip explains action. Loading state uses Sparkles icon with animate-pulse instead of spinner.

### Pattern 2: Streaming into Form Field

**What:** AI-generated text streams character-by-character into textarea field value

**When to use:** For fields with substantial text (narrative_hook, beat.text) where streaming provides progress feedback

**Example:**
```typescript
// NEW: useFieldGeneration hook wrapping Vercel AI SDK
import { useCompletion } from 'ai/react';
import { useFormContext } from 'react-hook-form';

export function useFieldGeneration() {
  const form = useFormContext();
  const [generatingField, setGeneratingField] = useState<string | null>(null);

  const {
    completion,
    isLoading,
    error,
    complete,
    stop,
  } = useCompletion({
    api: '/api/generate/field',
    onFinish: (prompt, completion) => {
      // Completion finished, update form field
      if (generatingField) {
        form.setValue(generatingField, completion);
        setGeneratingField(null);
      }
    },
    onError: (error) => {
      toast({
        variant: 'destructive',
        title: 'Generation failed',
        description: error.message,
      });
      setGeneratingField(null);
    },
  });

  const generateField = async (fieldName: string, context: any) => {
    setGeneratingField(fieldName);

    await complete(fieldName, {
      body: {
        fieldType: fieldName,
        nodeContext: {
          type: form.getValues('type'),
          biome: form.getValues('biome'),
          name: form.getValues('name'),
          themes: form.getValues('themes'),
          ...context,
        },
      },
    });
  };

  return {
    generateField,
    generatingField,
    streamedContent: generatingField ? completion : null,
    isGenerating: isLoading,
    cancel: stop,
    error,
  };
}

// In form component:
const { generateField, generatingField, streamedContent } = useFieldGeneration();

const handleGenerateHook = () => {
  generateField('narrative_hook', {
    enemyTypeHooks: form.getValues('enemyTypeHooks'),
    environmentalContext: form.getValues('environmentalContext'),
  });
};

// Show streamed content while generating
<Textarea
  {...field}
  value={generatingField === 'narrative_hook' ? streamedContent : field.value}
  disabled={generatingField === 'narrative_hook'}
/>
```

**Key insight:** useCompletion handles streaming state automatically. We wrap it to integrate with React Hook Form's setValue(). Field is disabled during generation to prevent user edits conflicting with stream. Streamed content replaces field value in real-time.

### Pattern 3: Field-Specific Backend Endpoints

**What:** Targeted endpoints that generate only the requested field without full 3-stage pipeline

**When to use:** For all field-level generation requests from frontend assist buttons

**Example:**
```typescript
// NEW: packages/backend/src/routes/generate-field.ts
import { Hono } from 'hono';
import { streamSSE } from 'hono/streaming';
import { zValidator } from '@hono/zod-validator';
import { z } from 'zod';
import {
  buildNodeContext,
  completeWithRetry,
  parseJsonResponse,
} from '../services/generation/index.js';

const app = new Hono();

const narrativeHookRequestSchema = z.object({
  nodeType: z.string(),
  biome: z.string(),
  name: z.string(),
  themes: z.array(z.string()),
  entityTypes: z.array(z.string()),
  act: z.number().optional(),
  // Type-specific context
  nodeMetadata: z.record(z.any()).optional(),
});

/**
 * POST /api/generate/field/narrative-hook
 * Generate just the narrative hook (1-3 sentence opening)
 */
app.post('/narrative-hook', zValidator('json', narrativeHookRequestSchema), async (c) => {
  const request = c.req.valid('json');

  return streamSSE(c, async (stream) => {
    try {
      const context = await buildNodeContext({
        biome: request.biome,
        act: request.act,
        nodeType: request.nodeType,
        nodeId: 'temp',
        name: request.name,
        themes: request.themes,
        entityTypes: request.entityTypes,
      });

      const systemPrompt = `You are a narrative writer for an Australian Gold Rush cosmic horror game.
Write a compelling narrative hook: 1-3 sentences that open this ${request.nodeType} node.

Biome: ${request.biome}
Themes: ${request.themes.join(', ')}
Act ${request.act || 1} tone: ${context.actTone?.description || 'frontier opportunity'}

Write in second person present tense. Be concise, evocative, sensory-rich.
Return only the narrative hook text, no JSON.`;

      const userPrompt = `Write the narrative hook for: ${request.name}`;

      // Stream token-by-token
      const result = await completeWithRetry({
        systemPrompt,
        userPrompt,
        temperature: 0.8,
        stream: true,
        onToken: async (token: string) => {
          await stream.writeSSE({
            data: JSON.stringify({ type: 'token', content: token }),
          });
        },
      });

      await stream.writeSSE({
        data: JSON.stringify({ type: 'done', content: result.content }),
      });
    } catch (error) {
      await stream.writeSSE({
        data: JSON.stringify({
          type: 'error',
          error: error instanceof Error ? error.message : 'Unknown error',
        }),
      });
    }
  });
});

/**
 * POST /api/generate/field/beat
 * Generate a single story beat
 */
app.post('/beat', zValidator('json', beatRequestSchema), async (c) => {
  // Similar pattern: stream single beat prose
});

export default app;
```

**Key insight:** Field endpoints bypass the 3-stage pipeline. They call LLM directly with field-specific prompts. Streaming is token-by-token for real-time display. System prompt reuses tone/theme logic from existing prompt-builder.ts but simplified for single-field output.

### Pattern 4: Beat List Generation (Suggest Multiple Beats)

**What:** "Suggest Beats" button that generates 3-5 beat outlines based on node type and beat sequence rules

**When to use:** When user wants AI to suggest the structure of story beats, not just fill one field

**Example:**
```typescript
// In beat editor component:
const handleSuggestBeats = async () => {
  const nodeType = form.getValues('type');
  const biome = form.getValues('biome');
  const narrativeHook = form.getValues('content.narrative_hook');

  const response = await fetch('/api/generate/field/beat-list', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      nodeType,
      biome,
      narrativeHook,
      beatSequence: getBeatSequenceForType(nodeType), // From beat-sequences config
    }),
  });

  const { beats } = await response.json();

  // Append suggested beats to existing beats array
  const currentBeats = form.getValues('content.beats') || [];
  form.setValue('content.beats', [
    ...currentBeats,
    ...beats.map((b: any, i: number) => ({
      id: `beat_${Date.now()}_${i}`,
      role: b.role,
      text: b.text,
    })),
  ]);

  toast({
    title: 'Beats suggested',
    description: `Added ${beats.length} story beats. Edit as needed.`,
  });
};

// UI:
<div className="flex items-center justify-between">
  <Label>Story Beats</Label>
  <div className="flex gap-2">
    <Button
      type="button"
      variant="outline"
      size="sm"
      onClick={handleSuggestBeats}
      disabled={!form.watch('content.narrative_hook')}
    >
      <Sparkles className="mr-2 size-4" />
      Suggest Beats
    </Button>
    <Button
      type="button"
      variant="outline"
      size="sm"
      onClick={handleAddBeat}
    >
      Add Beat Manually
    </Button>
  </div>
</div>

<BeatList beats={form.watch('content.beats')} />
```

**Key insight:** "Suggest Beats" is different from field-level generation. It generates structured data (array of beats with roles) not streaming prose. This uses non-streaming endpoint that returns JSON. User can then edit individual beat texts using field-level assists.

### Anti-Patterns to Avoid

- **Anti-pattern 1: Calling full 3-stage pipeline for field generation** - Don't use `/api/generate/stream` for field assists. It runs outline → prose → critic which takes 30-60s and generates full node content, wasting tokens and confusing UX.
  - **Solution:** Create dedicated field endpoints that call individual stage functions (expandBeatsToProse for narrative_hook) or direct LLM calls.

- **Anti-pattern 2: Concurrent field generation** - Don't allow multiple assist buttons to trigger simultaneously. Confusing which field is receiving streamed content.
  - **Solution:** Track `generatingField` state. Disable all assist buttons when any field is generating. Show spinner only on active button.

- **Anti-pattern 3: Overwriting user edits during stream** - If user starts typing while stream is active, their edits get clobbered by streaming tokens.
  - **Solution:** Disable textarea field during generation. Add "Cancel" button that calls stop() and re-enables field.

- **Anti-pattern 4: No context for field generation** - Generating narrative_hook without knowing node type, biome, themes produces generic content.
  - **Solution:** Always pass form context (type, biome, themes, type-specific fields) in field generation request. Backend uses same prompt-builder.ts logic as full generation.

## Don't Hand-Roll

Problems that look simple but have existing solutions:

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Streaming text state | Custom EventSource + useState | Vercel AI SDK useCompletion | Handles abort, retry, loading state, error handling, throttling |
| Token-by-token updates | SSE parser with manual string building | useCompletion with experimental_throttle | Built-in buffering prevents excessive re-renders |
| Field-to-field mapping | Custom context extraction logic | React Hook Form getValues() | Type-safe access to current form state for context |
| Streaming abort/cancel | EventSource.close() + manual cleanup | useCompletion stop() function | Handles in-flight request cleanup and state reset |
| Generate button UX | Custom loading spinner + icon swap | Existing FieldAssistButton pattern | Already solved in AssistedCreate.tsx, accessible with tooltip |

**Key insight:** Vercel AI SDK useCompletion is purpose-built for streaming text into form fields. It's a 1KB hook that eliminates custom SSE handling. Don't reimplement what it provides.

## Common Pitfalls

### Pitfall 1: Field Generation Without Enough Context

**What goes wrong:** User clicks "Generate narrative hook" on empty form → backend receives minimal context (just node type) → LLM generates generic content not specific to biome/themes

**Why it happens:** Field generation request doesn't capture current form state, only sends field name

**How to avoid:**
```typescript
const handleGenerateField = (fieldName: string) => {
  // Gather ALL relevant form context
  const formContext = {
    nodeType: form.getValues('type'),
    biome: form.getValues('biome'),
    name: form.getValues('name'),
    themes: form.getValues('themes'),
    entityTypes: form.getValues('entityTypes'),
    acts: form.getValues('acts'),
    // Type-specific fields
    ...(form.getValues('enemyTypeHooks') && {
      enemyTypeHooks: form.getValues('enemyTypeHooks'),
    }),
    ...(form.getValues('environmentalContext') && {
      environmentalContext: form.getValues('environmentalContext'),
    }),
  };

  // Validate required context
  if (!formContext.nodeType || !formContext.biome) {
    toast({
      variant: 'destructive',
      title: 'Cannot generate',
      description: 'Please fill in node type and biome first.',
    });
    return;
  }

  generateField(fieldName, formContext);
};
```

**Warning signs:** Generated narrative hooks mention "the location" instead of "the diggings", generic "enemy" instead of "bunyip"

### Pitfall 2: Lost Edits When Regenerating

**What goes wrong:** User clicks assist button → content streams in → user edits streamed text → clicks regenerate → edits are lost

**Why it happens:** No confirmation before overwriting field that already has content

**How to avoid:**
```typescript
const handleGenerateField = (fieldName: string) => {
  const currentValue = form.getValues(fieldName);

  // Warn if overwriting existing content
  if (currentValue && currentValue.trim().length > 0) {
    const confirmed = window.confirm(
      'This will replace existing content. Continue?'
    );
    if (!confirmed) return;
  }

  generateField(fieldName, getFormContext());
};

// Better: Add "Accept" and "Regenerate" buttons after generation
{generatingField === fieldName && streamedContent && (
  <div className="mt-2 flex gap-2">
    <Button
      size="sm"
      variant="outline"
      onClick={() => {
        form.setValue(fieldName, streamedContent);
        setGeneratingField(null);
      }}
    >
      Accept
    </Button>
    <Button
      size="sm"
      variant="outline"
      onClick={() => generateField(fieldName, getFormContext())}
    >
      Regenerate
    </Button>
    <Button
      size="sm"
      variant="ghost"
      onClick={() => {
        cancel();
        setGeneratingField(null);
      }}
    >
      Cancel
    </Button>
  </div>
)}
```

**Warning signs:** User reports "I had good text but it got erased when I clicked the button again"

### Pitfall 3: Streaming Performance Degradation

**What goes wrong:** Streaming narrative hook works fine, but streaming full beat list (5+ beats) causes form to re-render on every token, UI becomes sluggish

**Why it happens:** useCompletion triggers render per token by default, React Hook Form re-validates on every change

**How to avoid:**
```typescript
// Use experimental throttle to batch updates
const { completion, isLoading } = useCompletion({
  api: '/api/generate/field',
  experimental_throttle: 100, // Update UI max once per 100ms
  onFinish: (prompt, completion) => {
    form.setValue(fieldName, completion, {
      shouldValidate: false, // Skip validation during stream
      shouldDirty: true,
      shouldTouch: true,
    });
  },
});

// Validate only on finish
useEffect(() => {
  if (!isLoading && completion) {
    form.trigger(fieldName); // Trigger validation after stream completes
  }
}, [isLoading, completion, fieldName]);
```

**Warning signs:** Browser DevTools performance tab shows excessive renders during streaming, form feels laggy

### Pitfall 4: Missing Beat Sequence Validation

**What goes wrong:** User uses "Suggest Beats" → AI generates beats with roles [setup, setup, escalation] → violates beat sequence rules for combat nodes (setup* → escalation* → reveal)

**Why it happens:** Field generation endpoints don't enforce beat sequence templates from beat-sequences.ts

**How to avoid:**
```typescript
// Backend: Load beat sequence for node type
import { getBeatSequenceForNodeType } from '../config/beat-sequences.js';

app.post('/field/beat-list', async (c) => {
  const { nodeType, biome } = c.req.valid('json');

  const beatSequence = getBeatSequenceForNodeType(nodeType, biome);

  const systemPrompt = `Generate story beats following this structure:
${beatSequence.sequence.map((b) =>
  `- ${b.role}${b.required ? ' (required)' : ' (optional)'}: ${b.description}`
).join('\n')}

Return JSON array of beats matching this structure.`;

  // ... LLM call with enforced structure
});

// Frontend: Validate returned beats match sequence
const validateBeatsMatchSequence = (
  beats: StoryBeat[],
  sequence: BeatSequence
) => {
  const requiredRoles = sequence.sequence
    .filter((b) => b.required)
    .map((b) => b.role);

  const beatRoles = beats.map((b) => b.role);

  for (const required of requiredRoles) {
    if (!beatRoles.includes(required)) {
      throw new Error(`Missing required beat role: ${required}`);
    }
  }

  return true;
};
```

**Warning signs:** Generated nodes fail validation in critic stage with "Missing required beats" errors

## Code Examples

Verified patterns from existing codebase and Vercel AI SDK:

### Example 1: FieldAssistButton Component (Extract from AssistedCreate)
```typescript
// Source: packages/frontend/src/components/generation/AssistedCreate.tsx (lines 59-85)
import { Wand2, Sparkles } from 'lucide-react';
import { Button } from '@/components/ui/button';
import {
  Tooltip,
  TooltipContent,
  TooltipProvider,
  TooltipTrigger,
} from '@/components/ui/tooltip';

interface FieldAssistButtonProps {
  onClick: () => void;
  isLoading?: boolean;
  disabled?: boolean;
  tooltip?: string;
}

export function FieldAssistButton({
  onClick,
  isLoading,
  disabled,
  tooltip = 'Generate with AI',
}: FieldAssistButtonProps) {
  return (
    <TooltipProvider>
      <Tooltip>
        <TooltipTrigger asChild>
          <Button
            type="button"
            variant="ghost"
            size="icon"
            className="size-8"
            onClick={onClick}
            disabled={disabled || isLoading}
          >
            {isLoading ? (
              <Sparkles className="size-4 animate-pulse" />
            ) : (
              <Wand2 className="size-4" />
            )}
          </Button>
        </TooltipTrigger>
        <TooltipContent>
          <p>{tooltip}</p>
        </TooltipContent>
      </Tooltip>
    </TooltipProvider>
  );
}
```

### Example 2: useCompletion with Form Integration (Vercel AI SDK)
```typescript
// Source: Vercel AI SDK documentation + React Hook Form integration
import { useCompletion } from 'ai/react';
import { useFormContext } from 'react-hook-form';

export function useFieldGeneration() {
  const form = useFormContext();
  const [generatingField, setGeneratingField] = useState<string | null>(null);

  const {
    completion,
    isLoading,
    error,
    complete,
    stop,
    setCompletion,
  } = useCompletion({
    api: '/api/generate/field',
    experimental_throttle: 100, // Batch updates every 100ms
    onFinish: (prompt, completion) => {
      if (generatingField) {
        form.setValue(generatingField, completion, {
          shouldValidate: true,
          shouldDirty: true,
        });
        setGeneratingField(null);
      }
    },
    onError: (error) => {
      toast({
        variant: 'destructive',
        title: 'Generation failed',
        description: error.message,
      });
      setGeneratingField(null);
    },
  });

  const generateField = useCallback(
    async (fieldName: string, context: Record<string, any>) => {
      setGeneratingField(fieldName);
      setCompletion(''); // Clear previous completion

      await complete(fieldName, {
        body: {
          fieldType: fieldName,
          nodeContext: context,
        },
      });
    },
    [complete, setCompletion]
  );

  return {
    generateField,
    generatingField,
    streamedContent: completion,
    isGenerating: isLoading,
    cancel: stop,
    error,
  };
}
```

### Example 3: Narrative Hook Field with Assist Button
```typescript
// Pattern for adding assist to any textarea field
import { useFormContext } from 'react-hook-form';
import { FieldAssistButton } from '@/components/generation/FieldAssistButton';
import { useFieldGeneration } from '@/hooks/useFieldGeneration';

export function NarrativeHookField() {
  const form = useFormContext();
  const { generateField, generatingField, streamedContent, cancel } = useFieldGeneration();

  const handleGenerate = () => {
    // Validate required context
    const type = form.getValues('type');
    const biome = form.getValues('biome');

    if (!type || !biome) {
      toast({
        variant: 'destructive',
        title: 'Missing context',
        description: 'Please select node type and biome first.',
      });
      return;
    }

    generateField('content.narrative_hook', {
      nodeType: type,
      biome,
      name: form.getValues('name'),
      themes: form.getValues('themes'),
      entityTypes: form.getValues('entityTypes'),
    });
  };

  const isGenerating = generatingField === 'content.narrative_hook';
  const displayValue = isGenerating ? streamedContent : form.watch('content.narrative_hook');

  return (
    <FormField
      control={form.control}
      name="content.narrative_hook"
      render={({ field }) => (
        <FormItem>
          <div className="flex items-center justify-between">
            <FormLabel>Narrative Hook</FormLabel>
            <div className="flex gap-2">
              {isGenerating ? (
                <Button
                  type="button"
                  variant="ghost"
                  size="sm"
                  onClick={cancel}
                >
                  Cancel
                </Button>
              ) : (
                <FieldAssistButton
                  onClick={handleGenerate}
                  tooltip="Generate opening text with AI"
                />
              )}
            </div>
          </div>
          <FormControl>
            <Textarea
              {...field}
              value={displayValue || ''}
              onChange={isGenerating ? undefined : field.onChange}
              disabled={isGenerating}
              placeholder="1-3 sentences that draw players in..."
              className="min-h-24"
            />
          </FormControl>
          <FormDescription>
            Opening text for this encounter (20-500 characters)
          </FormDescription>
          <FormMessage />
        </FormItem>
      )}
    />
  );
}
```

### Example 4: Backend Field Generation Endpoint
```typescript
// Source: New pattern based on existing streaming.ts and prose-expander.ts
import { Hono } from 'hono';
import { streamSSE } from 'hono/streaming';
import { zValidator } from '@hono/zod-validator';
import { z } from 'zod';
import { buildNodeContext, completeWithRetry } from '../services/generation/index.js';

const fieldRequestSchema = z.object({
  fieldType: z.enum(['narrative_hook', 'beat', 'option']),
  nodeContext: z.object({
    nodeType: z.string(),
    biome: z.string(),
    name: z.string(),
    themes: z.array(z.string()),
    entityTypes: z.array(z.string()),
    act: z.number().optional(),
  }),
});

const app = new Hono();

app.post('/', zValidator('json', fieldRequestSchema), async (c) => {
  const { fieldType, nodeContext } = c.req.valid('json');

  return streamSSE(c, async (stream) => {
    try {
      const context = await buildNodeContext({
        biome: nodeContext.biome,
        act: nodeContext.act,
        nodeType: nodeContext.nodeType,
        nodeId: 'temp',
        name: nodeContext.name,
        themes: nodeContext.themes,
        entityTypes: nodeContext.entityTypes,
      });

      let systemPrompt = '';
      let userPrompt = '';

      if (fieldType === 'narrative_hook') {
        systemPrompt = `You are a narrative writer for an Australian Gold Rush cosmic horror game.
Write a compelling narrative hook: 1-3 sentences that open this ${nodeContext.nodeType} encounter.

Biome: ${nodeContext.biome} - ${context.biomeTone?.description || ''}
Act ${nodeContext.act || 1}: ${context.actTone?.description || ''}
Themes: ${nodeContext.themes.join(', ')}

Write in second person present tense. Be concise, evocative, sensory-rich.
Return only the narrative hook text (20-500 characters).`;

        userPrompt = `Write the narrative hook for: ${nodeContext.name}`;
      }

      // Stream token-by-token to frontend
      const result = await completeWithRetry({
        systemPrompt,
        userPrompt,
        temperature: 0.8,
        stream: true,
        onToken: async (token: string) => {
          await stream.writeSSE({
            data: JSON.stringify({ type: 'token', content: token }),
          });
        },
      });

      await stream.writeSSE({
        data: JSON.stringify({ type: 'done', content: result.content }),
      });
    } catch (error) {
      await stream.writeSSE({
        data: JSON.stringify({
          type: 'error',
          error: error instanceof Error ? error.message : 'Unknown error',
        }),
      });
    }
  });
});

export default app;
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Full node generation only | Field-level + full generation | Phase 6 (2026-01-26) | Users have hybrid option: manual base + AI creative fields |
| Custom EventSource streaming | Vercel AI SDK useCompletion | 2025-2026 | Built-in state management, abort, retry, throttling |
| Single "Generate" button | Per-field assist buttons | Phase 6 design | Granular control, users keep what they want |
| Generate all beats at once | Suggest beats + edit individually | Phase 6 design | AI provides structure, user refines prose |

**Deprecated/outdated:**
- **Full generation as only option**: Phases 1-5 only support "generate everything" workflow. Phase 6 adds field-level assists.
- **AssistedCreate full generate**: Current AssistedCreate.tsx calls full 3-stage pipeline even for field buttons (incorrect). Phase 6 fixes with field endpoints.
- **EventSource for completion streaming**: Vercel AI SDK useCompletion is now standard for form field streaming, not raw EventSource.

## Open Questions

Things that couldn't be fully resolved:

1. **Should beat text assists use streaming or instant?**
   - What we know: Narrative hook benefits from streaming (200+ chars). Single beat text is 50-150 chars.
   - What's unclear: Is streaming visual feedback worth the complexity for short fields?
   - Recommendation: Start with streaming for all text fields (consistent UX), measure if <100 char fields feel sluggish. Can switch short fields to instant (non-streaming) in iteration.

2. **How to handle field generation quota/rate limits?**
   - What we know: Field generation calls LLM API, costs tokens per request
   - What's unclear: Should we limit field generation attempts (e.g., 10 per session)? Add cost estimate?
   - Recommendation: Track field generation metrics (count, tokens used) in Phase 6, defer quota enforcement to Phase 8 (cost management).

3. **Beat editor UI: inline edit vs modal?**
   - What we know: Beats are array fields with role + text. Current forms use field arrays.
   - What's unclear: Should beat text assists open inline textareas or modal for better focus?
   - Recommendation: Start inline (simpler, consistent with other fields). User feedback may suggest modal for distraction-free editing.

4. **Should "Suggest Beats" clear existing beats or append?**
   - What we know: Users may manually add some beats then want AI to suggest more
   - What's unclear: Appending risks duplicating roles (two "setup" beats), clearing loses manual work
   - Recommendation: Append by default with validation warning if duplicate roles detected. Add "Replace all beats" variant behind confirmation dialog.

## Sources

### Primary (HIGH confidence)
- [Existing codebase] packages/frontend/src/components/generation/AssistedCreate.tsx - FieldAssistButton pattern
- [Existing codebase] packages/backend/src/services/generation/prose-expander.ts - narrative_hook generation logic
- [Existing codebase] packages/backend/src/services/generation/streaming.ts - SSE streaming infrastructure
- [Vercel AI SDK documentation](https://ai-sdk.dev/docs/reference/ai-sdk-ui/use-completion) - useCompletion API reference
- [Vercel AI SDK documentation](https://ai-sdk.dev/docs/ai-sdk-ui/completion) - Completion pattern with forms

### Secondary (MEDIUM confidence)
- [The React + AI Stack for 2026](https://www.builder.io/blog/react-ai-stack-2026) - React Hook Form + AI SDK patterns
- [AI SDK UI: useCompletion](https://ai-sdk.dev/docs/reference/ai-sdk-ui/use-completion) - Streaming text into form fields
- [Multi-field Forms for Completion · Issue #579 · vercel/ai](https://github.com/vercel/ai/issues/579) - Multi-field form integration
- [AI Content Generation in 2026](https://www.roboticmarketer.com/ai-content-generation-in-2026-brand-voice-strategy-and-scaling/) - Structured human-in-the-loop workflows

### Tertiary (LOW confidence)
- [12 Form UI/UX Design Best Practices to Follow in 2026](https://www.designstudiouiux.com/blog/form-ux-design-best-practices/) - General form UX, not AI-specific
- [10 AI-Driven UX Patterns Transforming SaaS in 2026](https://www.orbix.studio/blogs/ai-driven-ux-patterns-saas-2026) - High-level trends, no implementation details

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Vercel AI SDK is industry standard, React Hook Form already in use, patterns verified in AssistedCreate.tsx
- Architecture: HIGH - Backend infrastructure ready (streaming.ts, individual stage functions), frontend needs hook extraction
- Pitfalls: HIGH - Context gathering, overwrite confirmation, streaming performance are known React Hook Form + streaming issues

**Research date:** 2026-01-26
**Valid until:** 2026-02-26 (30 days - stable domain, Vercel AI SDK mature)

**Codebase readiness:**
- FieldAssistButton: 100% complete (exists in AssistedCreate.tsx, needs extraction)
- Backend field endpoints: 0% complete (need new routes/generate-field.ts)
- useFieldGeneration hook: 0% complete (need new hook wrapping useCompletion)
- Form integration: 20% complete (AssistedCreate has pattern, needs replication to BaseNodeForm, type forms)

**Estimated implementation effort:**
- Install Vercel AI SDK: 5 min
- Extract FieldAssistButton to standalone component: 15 min
- Create useFieldGeneration hook: 45 min
- Create backend generate-field.ts routes: 2 hours
- Add narrative_hook assist to BaseNodeForm: 30 min
- Add beat text assists to beat editor: 1 hour
- Add "Suggest Beats" button and beat-list endpoint: 1.5 hours
- Add choice option assists to ChoiceForm: 45 min
- Test field generation across all node types: 1 hour
- **Total:** ~8 hours
