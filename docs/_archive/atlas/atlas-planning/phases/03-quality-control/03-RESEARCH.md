# Phase 3: Quality Control - Research

**Researched:** 2026-01-25
**Domain:** LLM-based content evaluation, JSON validation, retry patterns, quality feedback UI
**Confidence:** HIGH

## Summary

Phase 3 builds on Phase 2's complete 3-stage generation pipeline to add quality control features. The critic stage currently exists but doesn't automatically retry low-quality outputs or validate JSON structure before database save. Research reveals that LLM-based evaluation (LLM-as-a-Judge) is a well-established pattern with specific best practices around rubric design, scoring scales, and validation.

The current implementation has a solid foundation: `critic.ts` evaluates content with a 0-100 score and structured feedback (issues, strengths, repair instructions). The batch processor checks critic scores against a threshold (default 70) but doesn't retry failures automatically. JSON validation is implicit through Zod schema inference but not explicitly enforced before database save. The frontend has basic quality score display but lacks detailed issue breakdown visualization.

Key findings:
- **LLM-as-a-Judge is mature**: 2026 best practices emphasize executable rubrics, lower-precision scoring (0-3 scales), chain-of-thought reasoning, and few-shot examples
- **Zod is the standard**: TypeScript-first runtime validation that bridges compile-time types and runtime checks - already in use for request validation
- **Retry patterns are well-defined**: Exponential backoff with jitter is standard; quality-based retries should include max attempts and different strategies per failure type
- **UI patterns favor visual clarity**: Color-coded confidence levels, categorical breakdowns, and actionable feedback over raw scores

**Primary recommendation:** Enhance existing critic implementation with refined rubric (per-node-type criteria), add explicit Zod validation layer before database save, implement quality-threshold retry loop with max attempts, and create detailed quality feedback UI component showing issue categories and suggestions.

## Standard Stack

The established libraries/tools for this domain:

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Zod | 3.x | Runtime JSON validation | TypeScript-first, already in use, provides both validation and type inference |
| RULERS framework concepts | N/A (pattern) | Executable rubric design | Latest research (2026) on reliable LLM evaluation with evidence-anchored scoring |
| Existing critic.ts | Current | LLM-based evaluation | Already implements structured evaluation with issues/strengths/repair instructions |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| batch-processor.ts | Current | Retry orchestration | Already handles retries at generation level; extend for quality-based retries |
| lucide-react icons | Current | UI feedback visualization | Already in use for stage icons (CheckCircle, XCircle, etc.) |
| shadcn/ui components | Current | Quality breakdown UI | Card, Badge, Progress already used in GenerationProgress.tsx |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Zod | AJV + JSON Schema | AJV is faster for pure runtime validation but Zod provides better TypeScript integration and is already project standard |
| LLM scoring | Rule-based validation | Rules catch structural issues but miss semantic quality (tone, atmosphere, distinctiveness) |
| Client-side validation only | Backend validation only | Both needed: client for UX feedback, backend for data integrity |

**Installation:**
```bash
# No new packages needed - Zod already installed
# Existing: zod@3.x in packages/shared
```

## Architecture Patterns

### Recommended Project Structure
```
packages/backend/src/services/generation/
├── critic.ts                    # Stage 3: Evaluation (ENHANCE)
├── batch-processor.ts           # Orchestration (ADD quality retry loop)
├── validators/                  # NEW: Explicit validation layer
│   ├── content-validator.ts     # Zod-based content validation
│   └── node-type-validators.ts  # Per-node-type validation rules
packages/frontend/src/components/generation/
├── GenerationProgress.tsx       # ENHANCE: Add quality breakdown
└── QualityFeedback.tsx          # NEW: Detailed issue visualization
```

### Pattern 1: Two-Layer Validation

**What:** Validate content structure with Zod BEFORE database save, separate from LLM critic evaluation

**When to use:** Always - prevents invalid data from reaching database regardless of critic opinion

**Example:**
```typescript
// Source: Current codebase + Zod best practices
import { NodeContentSchema } from '@node-gen-web/shared';

export function validateGeneratedContent(content: unknown, nodeType: string): {
  valid: boolean;
  errors: string[];
  data?: NodeContent;
} {
  try {
    // Zod parse with error handling
    const validated = NodeContentSchema.parse(content);
    return { valid: true, errors: [], data: validated };
  } catch (error) {
    if (error instanceof z.ZodError) {
      return {
        valid: false,
        errors: error.errors.map(e => `${e.path.join('.')}: ${e.message}`)
      };
    }
    return { valid: false, errors: ['Unknown validation error'] };
  }
}
```

### Pattern 2: Quality-Threshold Retry Loop

**What:** Retry generation if critic score falls below threshold, with different strategies for different failure types

**When to use:** After critic evaluation, before marking generation as complete

**Example:**
```typescript
// Source: batch-processor.ts + AWS retry patterns
async function generateWithQualityRetry(
  request: NodeGenerationRequest,
  options: GenerationOptions
): Promise<GenerationProgress> {
  const maxAttempts = options.maxRetries || 3;

  for (let attempt = 0; attempt < maxAttempts; attempt++) {
    const result = await generateNodeContent(request, options.onProgress);

    // Check critic result
    if (!result.critic) {
      throw new Error('Critic evaluation missing');
    }

    if (result.critic.pass && result.critic.score >= options.criticThreshold) {
      return result; // Success
    }

    // Failure - determine if retryable
    const criticalIssues = result.critic.issues.filter(i => i.severity === 'critical');
    if (criticalIssues.some(i => i.category === 'completeness')) {
      // Structural failure - likely won't improve with retry
      break;
    }

    if (attempt < maxAttempts - 1) {
      // Log retry with repair instructions
      console.log(`[Quality Retry] Attempt ${attempt + 1}/${maxAttempts}: Score ${result.critic.score}`);
      // Optionally: Include repair instructions in next attempt prompt
    }
  }

  return result; // Return last attempt even if failed
}
```

### Pattern 3: Node-Type-Specific Critic Rubrics

**What:** Different evaluation criteria per node type (combat emphasizes stakes, choice emphasizes dilemma clarity)

**When to use:** In critic system prompt construction

**Example:**
```typescript
// Source: Current critic.ts + RULERS framework concepts
function getNodeTypeRubric(nodeType: string): string {
  const baseRubric = `
### Required (Fail if not met)
1. Beat sequence completeness
2. Text length bounds (10-150 chars per beat)
3. Tone alignment with act
4. Historical authenticity (1850s Australian Gold Rush)
5. No clichés`;

  const typeSpecific: Record<string, string> = {
    combat: `
### Combat-Specific Quality Factors
- Stakes clarity: Player understands what's at risk (injury, resources, death)
- Enemy presence: Environmental description implies enemy type without stating it
- Tactical options: Beats suggest multiple approach vectors`,

    choice: `
### Choice-Specific Quality Factors
- Dilemma clarity: Two competing goods or two necessary evils, not good vs evil
- Consequence foreshadowing: Beats hint at outcomes without spoiling
- Moral weight: Player feels tension between options`,

    rest: `
### Rest-Specific Quality Factors
- Atmosphere shift: Contrast with previous tension (relief or unease)
- Vulnerability: Sense of exposure or safety depending on rest type
- Sensory richness: Smell of fire, sound of wind, texture of ground`
  };

  return baseRubric + '\n' + (typeSpecific[nodeType] || '');
}
```

### Pattern 4: Confidence Visualization with Categorical Breakdown

**What:** Show quality score with color-coded categories and specific issue details

**When to use:** In GenerationProgress component after critic evaluation completes

**Example:**
```typescript
// Source: GenerationProgress.tsx + 2026 UI patterns
interface QualityBreakdownProps {
  critic: CriticResult;
  threshold: number;
}

function QualityBreakdown({ critic, threshold }: QualityBreakdownProps) {
  const getCategoryColor = (category: string, severity: string) => {
    if (severity === 'critical') return 'text-red-500 bg-red-50';
    if (severity === 'major') return 'text-amber-500 bg-amber-50';
    return 'text-blue-500 bg-blue-50';
  };

  return (
    <Card>
      <CardHeader>
        <div className="flex items-center justify-between">
          <span className="text-sm font-medium">Quality Score</span>
          <span className={cn(
            'text-2xl font-bold',
            critic.score >= threshold ? 'text-green-500' : 'text-amber-500'
          )}>
            {critic.score}/100
          </span>
        </div>
      </CardHeader>
      <CardContent className="space-y-3">
        {/* Issues grouped by severity */}
        {critic.issues.length > 0 && (
          <div className="space-y-2">
            <p className="text-xs font-medium text-muted-foreground">Issues Found</p>
            {critic.issues.map((issue, idx) => (
              <div key={idx} className={cn('rounded-lg p-2', getCategoryColor(issue.category, issue.severity))}>
                <div className="flex items-start gap-2">
                  <Badge variant="outline" className="text-xs">{issue.category}</Badge>
                  <div className="flex-1 space-y-1">
                    <p className="text-xs font-medium">{issue.description}</p>
                    {issue.beatId && <p className="text-xs opacity-70">Beat: {issue.beatId}</p>}
                    <p className="text-xs italic">Suggestion: {issue.suggestion}</p>
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}

        {/* Strengths */}
        {critic.strengths.length > 0 && (
          <div className="space-y-2">
            <p className="text-xs font-medium text-muted-foreground">Strengths</p>
            {critic.strengths.map((strength, idx) => (
              <div key={idx} className="flex items-center gap-2">
                <CheckCircle className="size-3 text-green-500" />
                <p className="text-xs">{strength}</p>
              </div>
            ))}
          </div>
        )}
      </CardContent>
    </Card>
  );
}
```

### Anti-Patterns to Avoid

- **Validating only on client side:** Client validation can be bypassed; always validate on backend before database save
- **Retrying indefinitely:** Quality issues may be systematic (bad prompt, impossible constraints); cap retries at 3
- **Showing raw scores without context:** "Score: 65" is meaningless; show "Below threshold (70)" with specific issues
- **Treating all failures equally:** Structural failures (missing beats) won't improve with retry; semantic failures (weak tone) might
- **Ignoring critic pass/fail flag:** Score alone isn't enough; critic may fail on critical issues even if score is close to threshold

## Don't Hand-Roll

Problems that look simple but have existing solutions:

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Runtime JSON validation | Manual type checks with `typeof` | Zod with existing schemas | Zod provides detailed error messages, path tracking, and type inference - already project standard |
| Retry delay calculation | `setTimeout(attempt * 1000)` | `calculateRetryDelay()` in error-handler.ts | Already implements exponential backoff with jitter to prevent thundering herd |
| Quality score visualization | Custom progress bar component | Extend GenerationProgress.tsx with shadcn/ui | Existing component already handles stage icons, progress, error states - just add issue breakdown |
| Error classification | String matching in catch blocks | Extend `classifyLLMError()` | Already classifies 10+ error types with retryable flags and user messages |
| Critic rubric management | Hardcoded strings | Database-backed style guide system | `styleGuide`, `actTones`, `beatSequences` tables already exist for prompt customization |

**Key insight:** Phase 2 built comprehensive infrastructure (error classification, retry logic, circuit breaker, structured critic output). Phase 3 should extend these patterns rather than creating parallel systems.

## Common Pitfalls

### Pitfall 1: Validating Generated JSON Too Late

**What goes wrong:** Generated content is saved to database with invalid structure (missing required fields, incorrect types), causing runtime errors later when rendering nodes.

**Why it happens:** Assuming LLM will always return valid JSON because `responseFormat: 'json'` is set. LLMs can still return structurally valid JSON that violates application schemas (wrong field names, missing required fields).

**How to avoid:**
1. Add explicit Zod validation layer in batch-processor.ts AFTER content generation, BEFORE database save
2. Fail generation (not just log warning) if validation fails
3. Include validation errors in critic feedback for retry attempts

**Warning signs:**
- Database insert errors mentioning null constraints
- Frontend crashes when rendering generated content
- Type errors in components accessing content fields

### Pitfall 2: Infinite Quality Retry Loops

**What goes wrong:** System retries generation forever because content never reaches threshold, burning API credits and hanging UI.

**Why it happens:** Some combinations of node parameters are impossible to satisfy (conflicting themes, incompatible act tone + biome), or critic is miscalibrated and scores too harshly.

**How to avoid:**
1. Hard cap max retries at 3 (already in generation settings)
2. Track retry reason per attempt (structural vs semantic failure)
3. Break retry loop on repeated structural failures (completeness, length bounds)
4. Return best attempt if all retries exhausted, let user decide to retry manually

**Warning signs:**
- Generation progress stuck at "reviewing" stage
- LLM provider rate limits hit quickly
- User reports "generation never completes"

### Pitfall 3: Per-Node-Type Rubric Drift

**What goes wrong:** Critic rubric becomes too complex with per-node-type rules, leading to inconsistent scoring across node types and making threshold meaningless (70/100 for combat is easier than 70/100 for choice).

**Why it happens:** Adding node-specific criteria without recalibrating scoring weights. Current critic.ts has unified rubric; naive addition of per-type rules breaks score comparability.

**How to avoid:**
1. Keep core rubric (5 required factors) universal across all node types
2. Add node-specific criteria as "bonus" quality factors that influence score but don't change pass/fail
3. Use same 0-100 scale anchoring: 70 = "meets requirements, no major issues"
4. Test scoring consistency: Generate same biome/act content for different node types and verify score variance is reasonable

**Warning signs:**
- Combat nodes pass at 85+ but choice nodes fail at 75
- User confusion about why similar quality content has different scores
- Need to adjust threshold per node type

### Pitfall 4: Displaying Score Without Actionable Feedback

**What goes wrong:** User sees "Score: 68 (Failed)" with no explanation of what's wrong or how to fix it. Frustration leads to retrying with same parameters or abandoning generation.

**Why it happens:** Frontend shows only the numeric score from critic result without rendering `issues` array and `repairInstructions`.

**How to avoid:**
1. Always display critic issues grouped by severity (critical/major/minor)
2. Show suggestions per issue ("Make this more specific", "Add sensory detail")
3. If repair instructions exist, show them prominently
4. Allow user to see full critic output in expandable section for debugging

**Warning signs:**
- User repeatedly generates same node hoping for better score
- Support requests asking "why did this fail?"
- User modifies unrelated fields (biome, act) trying to improve score

### Pitfall 5: Critic Evaluating Its Own Repair Attempts

**What goes wrong:** When retrying after critic failure, new generation attempt includes previous critic's repair instructions but critic evaluates with same rubric, potentially penalizing the repair guidance itself or getting stuck in loops.

**Why it happens:** Naively passing `repairInstructions` into next generation attempt without context that these came from a previous critic evaluation.

**How to avoid:**
1. Keep retry attempts independent - don't feed repair instructions back into generation prompt
2. If including repair context, mark it clearly: "Previous attempt had issue X, address this"
3. Consider repair instructions as hints for user manual retry, not automatic retry
4. Track whether retry improved score; if 2 retries don't improve, stop (suggests systematic issue)

**Warning signs:**
- Scores get worse on retry instead of better
- Repair instructions mention the repair instructions themselves (meta-feedback loop)
- Content becomes overly verbose trying to address every critic suggestion

## Code Examples

Verified patterns from official sources and current codebase:

### Zod Validation with Error Handling

```typescript
// Source: Zod documentation + packages/shared/src/schemas/node.ts
import { NodeContentSchema, AnyNodeMetadataSchema } from '@node-gen-web/shared';
import { z } from 'zod';

export interface ValidationResult<T> {
  success: boolean;
  data?: T;
  errors?: string[];
}

export function validateNodeContent(content: unknown): ValidationResult<z.infer<typeof NodeContentSchema>> {
  const result = NodeContentSchema.safeParse(content);

  if (result.success) {
    return { success: true, data: result.data };
  }

  return {
    success: false,
    errors: result.error.errors.map(err => {
      const path = err.path.join('.');
      return `${path}: ${err.message}`;
    })
  };
}

export function validateCompleteNode(node: unknown, nodeType: string): ValidationResult<any> {
  // Use discriminated union schema for full node validation
  const result = AnyNodeMetadataSchema.safeParse(node);

  if (result.success) {
    return { success: true, data: result.data };
  }

  return {
    success: false,
    errors: result.error.errors.map(err => {
      const path = err.path.join('.');
      return `[${nodeType}] ${path}: ${err.message}`;
    })
  };
}
```

### Quality-Based Retry with Attempt Tracking

```typescript
// Source: batch-processor.ts + AWS retry patterns with jitter
async function generateWithQualityCheck(
  request: NodeGenerationRequest,
  options: {
    enableCritic: boolean;
    criticThreshold: number;
    maxRetries: number;
    onProgress?: ProgressCallback;
  }
): Promise<GenerationProgress> {
  let lastResult: GenerationProgress | null = null;
  let attempts = 0;

  while (attempts < options.maxRetries) {
    attempts++;

    // Generate content through all 3 stages
    const result = await generateNodeContent(
      request,
      options.onProgress,
      options.enableCritic,
      options.criticThreshold
    );

    lastResult = result;

    // If generation failed (non-quality issue), don't retry
    if (result.stage === 'failed' && !result.critic) {
      break;
    }

    // If critic passed, return success
    if (result.critic?.pass && result.critic.score >= options.criticThreshold) {
      return result;
    }

    // Quality failure - determine if retryable
    if (result.critic) {
      const criticalStructural = result.critic.issues.some(
        i => i.severity === 'critical' &&
             (i.category === 'completeness' || i.category === 'length')
      );

      if (criticalStructural) {
        // Structural issues unlikely to improve with retry
        console.log(`[Quality Check] Structural failure on attempt ${attempts}, not retrying`);
        break;
      }

      // Semantic issues might improve with retry
      if (attempts < options.maxRetries) {
        console.log(`[Quality Check] Attempt ${attempts}: Score ${result.critic.score}/${options.criticThreshold}, retrying...`);
        // Wait briefly before retry (avoid immediate re-generation)
        await new Promise(resolve => setTimeout(resolve, 1000));
        continue;
      }
    }

    break;
  }

  return lastResult || {
    nodeId: request.nodeId,
    stage: 'failed',
    progress: 100,
    error: 'Quality check failed after all retry attempts'
  };
}
```

### Enhanced Critic Prompt with Node-Type Specificity

```typescript
// Source: critic.ts + RULERS framework concepts
export function buildCriticSystemPrompt(nodeType: string): string {
  const basePrompt = `You are a narrative quality critic for an Australian Gold Rush cosmic horror game.

Your task is to evaluate generated content and provide a pass/fail judgment with specific feedback.

## Core Evaluation Criteria (All Node Types)

### Required (Fail if not met)
1. Beat sequence completeness - All required beats present
2. Text length bounds - Each beat 10-150 characters
3. Tone alignment - Matches act-appropriate mood
4. Historical authenticity - 1850s Australian Gold Rush setting
5. No clichés - Avoid generic horror tropes

### Quality Factors (Contribute to score)
1. Sensory richness - Uses sight, sound, smell, touch
2. Stakes clarity - Player understands what's at risk
3. Emotional impact - Beats feel meaningful
4. Pacing - Tension builds appropriately
5. Distinctiveness - Feels unique, not repetitive
6. Show don't tell - Concrete details imply meaning`;

  const nodeTypeRubrics: Record<string, string> = {
    combat: `

## Combat-Specific Criteria

### High Priority
- **Enemy presence implied**: Environmental description suggests enemy type without stating "you see a [enemy]"
- **Tactical options hinted**: Beats suggest multiple approach vectors (fight/flee/negotiate)
- **Consequences clear**: Victory/defeat outcomes show specific stakes (injury severity, resource loss)

### Pass Example
"The publican's eyes are too bright, his smile too wide. Your hand drifts toward your knife." [setup]
"He slides a glass across the bar. The liquid inside writhes." [escalation]
"His fingers are too long. Each one has an extra joint." [reveal]

### Fail Example
"A monster appears. It looks scary." [too vague, tells instead of shows]`,

    choice: `

## Choice-Specific Criteria

### High Priority
- **Dilemma clarity**: Two competing goods OR two necessary evils (not good vs evil)
- **Consequence foreshadowing**: Options hint at outcomes without spoiling
- **Moral weight**: Player feels genuine tension between options

### Pass Example
Option 1: "Share your rations" → Description: "They're starving, but so are you. Three days to the next township."
Option 2: "Keep moving" → Description: "You'll need every scrap to survive the Waste. They'll understand."

### Fail Example
Option 1: "Help the innocent person" [obviously good]
Option 2: "Be evil and cruel" [cartoonishly bad]`,

    rest: `

## Rest-Specific Criteria

### High Priority
- **Atmosphere shift**: Contrast with previous tension (relief or unease)
- **Vulnerability sense**: Player feels exposed or safe depending on rest type
- **Sensory detail**: Smell of fire, sound of wind, texture of ground

### Pass Example
"The fire cracks, sending sparks into the dark. Beyond the light, something shifts." [tension]
"Your swag is damp with red clay. The ground is hard, unforgiving." [sensory]
"Sleep comes slow. Your hand stays on your knife." [vulnerability]

### Fail Example
"You rest and feel refreshed." [no atmosphere, no detail]`,
  };

  const nodeSpecific = nodeTypeRubrics[nodeType] || '';

  return basePrompt + nodeSpecific + `

## Output Format
Return valid JSON:
{
  "pass": true/false,
  "score": 0-100,
  "issues": [
    {
      "severity": "critical|major|minor",
      "category": "completeness|length|tone|authenticity|cliche|quality",
      "description": "Specific issue description",
      "beatId": "affected_beat_id or null",
      "suggestion": "How to fix"
    }
  ],
  "strengths": ["What works well"],
  "repairInstructions": "If fail, specific instructions to fix" or null
}

## Scoring Scale
- 90-100: Exceptional quality, distinctive voice, strong sensory detail
- 70-89: Solid quality, meets all requirements, some memorable moments
- 50-69: Acceptable structure but weak execution (vague, tells not shows, generic)
- 0-49: Fails requirements (missing beats, wrong length, off-tone, clichéd)

Threshold for pass: 70+

Be constructive, not harsh. Note strengths before issues.`;
}
```

### UI Component for Quality Feedback

```typescript
// Source: GenerationProgress.tsx + 2026 UI confidence visualization patterns
import { CheckCircle, XCircle, AlertCircle, Info } from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Separator } from '@/components/ui/separator';
import { ScrollArea } from '@/components/ui/scroll-area';
import { cn } from '@/lib/utils';

interface CriticIssue {
  severity: 'critical' | 'major' | 'minor';
  category: string;
  description: string;
  beatId: string | null;
  suggestion: string;
}

interface CriticResult {
  pass: boolean;
  score: number;
  issues: CriticIssue[];
  strengths: string[];
  repairInstructions: string | null;
}

interface QualityFeedbackProps {
  critic: CriticResult;
  threshold: number;
  compact?: boolean;
}

function SeverityIcon({ severity }: { severity: string }) {
  switch (severity) {
    case 'critical':
      return <XCircle className="size-4 text-red-500" />;
    case 'major':
      return <AlertCircle className="size-4 text-amber-500" />;
    case 'minor':
      return <Info className="size-4 text-blue-500" />;
    default:
      return <Info className="size-4 text-gray-500" />;
  }
}

export function QualityFeedback({ critic, threshold, compact = false }: QualityFeedbackProps) {
  const passed = critic.pass && critic.score >= threshold;

  const getSeverityColor = (severity: string) => {
    switch (severity) {
      case 'critical': return 'bg-red-50 border-red-200';
      case 'major': return 'bg-amber-50 border-amber-200';
      case 'minor': return 'bg-blue-50 border-blue-200';
      default: return 'bg-gray-50 border-gray-200';
    }
  };

  return (
    <Card>
      <CardHeader>
        <CardTitle className="flex items-center justify-between">
          <div className="flex items-center gap-2">
            {passed ? (
              <CheckCircle className="size-5 text-green-500" />
            ) : (
              <XCircle className="size-5 text-amber-500" />
            )}
            <span>Quality Assessment</span>
          </div>
          <div className="flex items-center gap-2">
            <span className={cn(
              'text-2xl font-bold',
              passed ? 'text-green-500' : 'text-amber-500'
            )}>
              {critic.score}
            </span>
            <span className="text-sm text-muted-foreground">/100</span>
          </div>
        </CardTitle>
        <p className="text-sm text-muted-foreground">
          {passed
            ? `Passed quality check (threshold: ${threshold})`
            : `Below threshold (${threshold}) - review issues below`}
        </p>
      </CardHeader>

      <CardContent className="space-y-4">
        {/* Strengths */}
        {critic.strengths.length > 0 && (
          <div className="space-y-2">
            <h4 className="text-sm font-semibold text-green-600 flex items-center gap-2">
              <CheckCircle className="size-4" />
              Strengths ({critic.strengths.length})
            </h4>
            <ul className="space-y-1">
              {critic.strengths.map((strength, idx) => (
                <li key={idx} className="text-sm text-muted-foreground flex items-start gap-2">
                  <span className="text-green-500">•</span>
                  <span>{strength}</span>
                </li>
              ))}
            </ul>
          </div>
        )}

        {/* Issues */}
        {critic.issues.length > 0 && (
          <>
            {critic.strengths.length > 0 && <Separator />}
            <div className="space-y-3">
              <h4 className="text-sm font-semibold text-red-600 flex items-center gap-2">
                <AlertCircle className="size-4" />
                Issues Found ({critic.issues.length})
              </h4>

              <ScrollArea className={cn(compact ? 'max-h-48' : 'max-h-96')}>
                <div className="space-y-2">
                  {critic.issues.map((issue, idx) => (
                    <div
                      key={idx}
                      className={cn(
                        'rounded-lg border p-3 space-y-2',
                        getSeverityColor(issue.severity)
                      )}
                    >
                      <div className="flex items-start gap-2">
                        <SeverityIcon severity={issue.severity} />
                        <div className="flex-1 space-y-1">
                          <div className="flex items-center gap-2">
                            <Badge variant="outline" className="text-xs">
                              {issue.category}
                            </Badge>
                            <Badge variant="outline" className="text-xs capitalize">
                              {issue.severity}
                            </Badge>
                            {issue.beatId && (
                              <span className="text-xs text-muted-foreground">
                                Beat: {issue.beatId}
                              </span>
                            )}
                          </div>
                          <p className="text-sm font-medium">{issue.description}</p>
                          <p className="text-xs text-muted-foreground italic">
                            💡 {issue.suggestion}
                          </p>
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
              </ScrollArea>
            </div>
          </>
        )}

        {/* Repair Instructions */}
        {critic.repairInstructions && (
          <>
            <Separator />
            <div className="space-y-2">
              <h4 className="text-sm font-semibold text-blue-600 flex items-center gap-2">
                <Info className="size-4" />
                Repair Guidance
              </h4>
              <p className="text-sm text-muted-foreground bg-blue-50 border border-blue-200 rounded-lg p-3">
                {critic.repairInstructions}
              </p>
            </div>
          </>
        )}

        {/* No issues and no strengths case */}
        {critic.issues.length === 0 && critic.strengths.length === 0 && (
          <p className="text-sm text-muted-foreground text-center py-4">
            No detailed feedback available
          </p>
        )}
      </CardContent>
    </Card>
  );
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Binary pass/fail evaluation | 0-100 scoring with structured feedback | 2024-2025 | Allows nuanced quality thresholds and partial success tracking |
| Prompt-based rubrics | Executable rubrics with evidence anchoring (RULERS) | 2026 | More reliable LLM judging with verifiable criteria |
| High-precision scales (0-100) | Lower-precision scales (0-3) for reliability | 2025-2026 | Easier for LLMs to score consistently, better human agreement |
| JSON Schema + AJV | Zod for TypeScript-first validation | 2022-2023 | Better DX with type inference, but AJV still faster for pure runtime |
| Unlimited retries | Circuit breakers + retry budgets | 2024-2025 | Prevents runaway costs in production LLM systems |
| Raw score display | Confidence visualization with categorical breakdown | 2025-2026 | Users understand quality feedback better with visual cues |

**Deprecated/outdated:**
- **Manual JSON parsing**: Use Zod safeParse() instead of try/catch around JSON.parse()
- **Synchronous validation**: All validation should be async-compatible for future plugin extensibility
- **Generic error messages**: Users expect specific, actionable feedback per error type
- **Hidden quality scores**: Transparency trend means showing scores/feedback improves trust

## Open Questions

Things that couldn't be fully resolved:

1. **Should repair instructions feed into retry attempts?**
   - What we know: Critic generates `repairInstructions` when content fails, describing how to fix issues
   - What's unclear: Whether to include these in next generation prompt or keep retries independent
   - Recommendation: Keep retries independent (no repair instruction injection) to avoid meta-feedback loops; reserve repair instructions for user-facing display only

2. **How many retries before giving up?**
   - What we know: Generation settings has `maxRetries: 3` default, batch-processor implements exponential backoff
   - What's unclear: Should quality retries count against the same limit as transient error retries?
   - Recommendation: Separate counters - maxRetries for transient errors (429, 503), maxQualityRetries (default 2) for critic failures

3. **Should validation happen before or after critic stage?**
   - What we know: Zod validation is fast (~1ms), critic LLM call is slow (~2-5s)
   - What's unclear: Whether to fail fast on invalid JSON before critic, or let critic evaluate even invalid structure
   - Recommendation: Validate AFTER critic but BEFORE database save - critic might provide useful feedback even if JSON is malformed

4. **What to do with critic score on successful generation?**
   - What we know: Database has `criticScore` column on nodes table
   - What's unclear: Should this be saved even for manual node creation, or only for AI-generated content?
   - Recommendation: Save criticScore + generatedBy fields only when generation pipeline completes; leave null for manually created nodes

5. **Per-node-type quality thresholds?**
   - What we know: Different node types have different complexity (combat vs passage)
   - What's unclear: Whether to allow different thresholds per type or maintain universal 70/100 standard
   - Recommendation: Start with universal threshold (70/100); add per-type thresholds only if testing reveals systematic score disparities

## Sources

### Primary (HIGH confidence)

**LLM Evaluation:**
- [LLM Evaluation Metrics: The Ultimate Guide](https://www.confident-ai.com/blog/llm-evaluation-metrics-everything-you-need-for-llm-evaluation) - Comprehensive overview of LLM-as-a-Judge patterns
- [RULERS: Locked Rubrics and Evidence-Anchored Scoring](https://arxiv.org/abs/2601.08654) - 2026 research on executable rubric design
- [LLM-Rubric: A Multidimensional, Calibrated Approach](https://arxiv.org/html/2501.00274v1) - Multi-dimensional evaluation frameworks
- [Promptfoo LLM Rubric Documentation](https://www.promptfoo.dev/docs/configuration/expected-outputs/model-graded/llm-rubric/) - Production rubric implementation patterns
- [Databricks: Best Practices for LLM Evaluation](https://www.databricks.com/blog/LLM-auto-eval-best-practices-RAG) - Human-in-the-loop validation, lower-precision scales

**Zod Validation:**
- [Zod Official Documentation](https://zod.dev/) - Official Zod docs (v3.x)
- [Zod + TypeScript: Schema Validation Made Easy](https://www.telerik.com/blogs/zod-typescript-schema-validation-made-easy) - Integration patterns
- [How Zod Changed TypeScript Validation Forever](https://iamshadi.medium.com/how-zod-changed-typescript-validation-forever-the-power-of-runtime-and-compile-time-validation-531cd63799cf) - Runtime vs compile-time validation

**Retry Patterns:**
- [AWS Prescriptive Guidance: Retry with Backoff](https://docs.aws.amazon.com/prescriptive-guidance/latest/cloud-design-patterns/retry-backoff.html) - Exponential backoff best practices
- [AWS Builders Library: Timeouts, Retries, and Backoff with Jitter](https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/) - Jitter implementation patterns
- [How to Implement Retry Logic with Exponential Backoff in gRPC](https://oneuptime.com/blog/post/2026-01-08-grpc-retry-exponential-backoff/view) - January 2026 guide
- [Understanding Retry Pattern With Exponential Back-Off and Circuit Breaker](https://dzone.com/articles/understanding-retry-pattern-with-exponential-back) - Circuit breaker integration

**UI Patterns:**
- [Confidence Visualization UI Patterns (CVP)](https://agentic-design.ai/patterns/ui-ux-patterns/confidence-visualization-patterns) - Color-coded confidence levels for AI output
- [Building a UX Metrics Scorecard](https://measuringu.com/ux-scorecard/) - Score breakdown visualization
- [12 UI/UX Design Trends That Will Dominate 2026](https://www.index.dev/blog/ui-ux-design-trends) - WCAG 3.0 scoring models, data storytelling

### Secondary (MEDIUM confidence)

**Current Codebase:**
- `/packages/backend/src/services/generation/critic.ts` - Existing critic implementation with structured feedback
- `/packages/backend/src/services/generation/batch-processor.ts` - Retry orchestration with quality threshold checks
- `/packages/backend/src/services/generation/error-handler.ts` - Error classification and retry delay calculation
- `/packages/shared/src/schemas/node.ts` - Zod schemas for content validation
- `/packages/frontend/src/components/generation/GenerationProgress.tsx` - Basic quality score display

**Phase 2 Documentation:**
- `.planning/phases/02-core-generation-pipeline/02-VERIFICATION.md` - Complete pipeline flow verification

### Tertiary (LOW confidence - flagged for validation)

None - all findings verified with authoritative sources or direct code inspection.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Zod already in use, critic exists, UI framework established
- Architecture: HIGH - Patterns align with existing codebase structure (validators, batch-processor extension)
- Pitfalls: MEDIUM - Inferred from general patterns, not specific to this domain
- Code examples: HIGH - Derived from current codebase + official documentation

**Research date:** 2026-01-25
**Valid until:** 2026-02-25 (30 days - stable domain, but LLM evaluation patterns evolving rapidly)

**Key risks:**
- Critic rubric calibration is domain-specific (Australian Gold Rush cosmic horror); generic patterns may not transfer perfectly
- Per-node-type quality criteria require testing with real content to validate effectiveness
- UI patterns for quality feedback are conceptual; usability testing needed to confirm clarity

**Decisions needed before planning:**
1. Should repair instructions feed into retry attempts? → Recommendation: No, keep retries independent
2. Should quality retries have separate counter from transient error retries? → Recommendation: Yes, separate limits
3. Should validation happen before or after critic? → Recommendation: After critic, before DB save
4. Should all nodes have critic scores or only AI-generated? → Recommendation: Only AI-generated (track via generatedBy field)
