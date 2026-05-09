# Feature Landscape: AI Narrative Generation Tools

**Domain:** AI-powered narrative/content generation for games and interactive fiction
**Researched:** 2026-01-25
**Confidence:** MEDIUM (based on established patterns in Sudowrite, NovelAI, AI Dungeon, Scenario.gg, Artbreeder Writer, and similar tools as of training cutoff)

## Table Stakes

Features users expect from AI narrative generation tools. Missing = product feels incomplete.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| **Real-time streaming generation** | Users expect to see text appear token-by-token, not wait for full completion | Medium | Industry standard since ChatGPT; UX expectation is <100ms to first token |
| **Regenerate/retry controls** | AI output varies; users need ability to roll the dice again | Low | Simple: same inputs, new generation. Critical for user agency |
| **Generation cancellation** | Long generations need abort capability | Low | Stop button that cancels in-flight API request |
| **Basic prompt templating** | Users expect contextual generation (e.g., "Generate combat for biome X") | Medium | Template variables + context injection. Not full prompt engineering UI |
| **Preview before save** | AI output is unpredictable; users need review step | Low | Show generated content in editable form before committing to database |
| **Multi-field generation** | Generate related fields together (e.g., narrative hook + beats + outcomes) | Medium | Either sequential API calls or structured output parsing |
| **Generation history/undo** | Users make mistakes; need to revert to previous generation | Medium | Store N previous generations in session state or temp storage |
| **Cost visibility** | AI APIs cost money; users need token/cost estimates | Low | Show estimated cost before generation, actual cost after |
| **Error handling with actionable feedback** | APIs fail; users need to understand why and what to do | Medium | Distinguish: rate limits, invalid input, API errors, timeout. Provide retry/edit options |
| **Basic quality indicators** | Users need signal on whether output is "good enough" | Medium | Length check, coherence heuristics, or simple scoring (1-10) |
| **Provider selection** | Users may have API keys for different providers | Low | Dropdown or settings to choose OpenAI/Anthropic/OpenRouter |
| **Generation presets/modes** | Users want "creative" vs "coherent" vs "concise" control | Low | Temperature/top_p presets with readable names |

## Differentiators

Features that set products apart. Not expected, but valued. Competitive advantages.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| **Critic/quality scoring LLM** | Automated quality assessment before user review | High | Second LLM evaluates first's output. Rare in narrative tools, common in code gen (e.g., Cursor's linting) |
| **Bulk generation with progress tracking** | Generate 50 nodes overnight vs manually generating 50 times | High | Job queue, resumable generation, partial success handling |
| **Field-level AI assists in manual forms** | Mix manual + AI work: write hook manually, AI generates beats | Medium | Inline "magic wand" buttons per field. Seen in Notion AI, less common in game tools |
| **Smart retry with variation controls** | Retry with hints: "Make this darker" or "Add more sensory detail" | Medium | Append user refinement to prompt without rewriting whole template |
| **Context-aware suggestions** | AI proposes what to generate next based on graph structure | High | Graph analysis + recommendation engine. Very differentiating |
| **Batch operations with constraints** | "Generate 10 combat nodes for Act 2 in The Waste biome, no duplicates" | High | Constraint solver + batch coordination. Powerful for filling gaps |
| **Version comparison view** | Side-by-side diff of multiple generations | Medium | UI complexity moderate; helps users choose between variants |
| **Prompt template customization** | Power users edit system prompts and templates | Medium | Dangerous (users break things) but empowering. Needs good defaults + reset |
| **Multi-provider fallback** | Auto-fallback to different provider if primary fails | Medium | Resilience + cost optimization. Requires compatible prompt translation |
| **Fine-tuned model support** | Use custom-trained models for domain-specific content | High | Requires training pipeline, hosting, or fine-tune management. Niche but powerful |
| **Collaborative prompt engineering** | Team shares and versions prompt templates | High | Multi-user, version control for prompts. Enterprise feature |
| **Generation analytics** | Track which prompts/providers produce best results | Medium | Logging + analytics dashboard. Helps optimize over time |
| **Conditional generation chains** | "Generate combat, then if difficulty > 7, generate consequence" | High | Workflow engine for multi-step generation with branching logic |
| **Content style transfer** | "Generate like this example node" with few-shot learning | Medium | Embed example in prompt or use semantic search for similar examples |

## Anti-Features

Features to explicitly NOT build. Common mistakes in AI generation tools.

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| **Fully automated "generate everything" button** | Removes human creative control; output quality degrades at scale; users feel replaced not assisted | Provide targeted generation for specific fields or small batches with review steps |
| **No preview/direct to database** | AI hallucinates and produces garbage; auto-save creates cleanup burden | Always show preview, make save explicit user action |
| **Editing generated prompts in UI** | Users break prompts with invalid syntax; support burden increases | Provide preset variations (temperature, length, tone) rather than freeform prompt editing. Advanced users can edit templates in config files |
| **Unlimited batch generation** | Cost explosion risk; API rate limits cause failures; users generate low-quality spam | Set reasonable limits (10-50 per batch), show cost estimates, require confirmation for large batches |
| **Synchronous generation blocking UI** | Poor UX for long generations (30s+); users perceive app as frozen | Use streaming for real-time feedback or async jobs with progress indicators |
| **Auto-regenerate on error** | Infinite retry loops on persistent errors; cost wastage | Fail explicitly, show error, let user decide to retry |
| **One-size-fits-all prompts** | Generic prompts produce generic content; biome/act context gets ignored | Context-aware templating with biome themes, act tone, node type patterns |
| **Storing full conversation history per node** | Database bloat; expensive to load; unclear value | Store final output + metadata (provider, model, cost). Optionally store 1-2 previous generations for undo |
| **Real-time collaborative editing of AI output** | Conflict resolution nightmare when AI and multiple users edit simultaneously | Single-user generation session; lock node during AI generation/preview |
| **AI-generated metadata/tags** | AI is unreliable for structured data; users need control over taxonomy | AI generates narrative content only; users select biomes, acts, themes from controlled vocabulary |
| **Free-tier with no rate limiting** | Cost explosion; abuse risk; unsustainable | Require API keys (BYO model access) or implement strict rate limits with paid tiers |

## Feature Dependencies

```
Foundation Layer:
├── Provider integration (OpenRouter/Anthropic/OpenAI)
├── API key management
└── Cost tracking

Generation Core:
├── Prompt templating (requires: provider integration)
├── Streaming generation (requires: prompt templating)
├── Cancel/abort (requires: streaming generation)
└── Error handling (requires: generation core)

Quality Control:
├── Preview before save (requires: generation core)
├── Regenerate/retry (requires: generation core)
├── Generation history (requires: preview before save)
└── Critic LLM scoring (requires: generation core)

Bulk Operations:
├── Batch generation (requires: generation core)
├── Progress tracking (requires: batch generation)
├── Job queue (requires: batch generation)
└── Constraint-based generation (requires: batch generation)

Advanced Features:
├── Field-level assists (requires: generation core)
├── Smart retry with hints (requires: regenerate/retry)
├── Context-aware suggestions (requires: graph analysis)
└── Prompt customization (requires: prompt templating)
```

## UX Patterns from Real Tools

### Pattern 1: Inline Field Assists (Notion AI, Sudowrite)
**What:** Small "AI assist" button next to each form field
**When:** User is manually creating content but wants help with specific field
**UX:**
- User fills some fields manually
- Clicks sparkle/wand icon on narrative_hook field
- Modal or popover shows streaming generation
- User can regenerate, edit, accept, or cancel
- Accepted content populates field, user continues form

**Implementation:**
```typescript
<Textarea value={narrativeHook} onChange={...} />
<Button onClick={() => generateField('narrative_hook', context)}>
  <Sparkles /> Generate
</Button>
```

### Pattern 2: Full-Node Generation (AI Dungeon, NovelAI)
**What:** Generate entire node structure at once
**When:** User wants to quickly create complete node with minimal input
**UX:**
- User selects node type, biome, act (minimal form)
- Click "Generate Node"
- Streaming shows progressive field population:
  - "Generating narrative hook..." (shows streaming text)
  - "Generating beats..." (shows list building)
  - "Generating options..." (shows streaming)
- Full preview shown at end with edit/regenerate/save options

**Implementation:**
- Sequential API calls for each field
- OR single structured output call with JSON schema
- Progress indicator shows which field is generating
- Each field appears as it completes

### Pattern 3: Batch Generation with Review Queue (Scenario.gg, Artbreeder)
**What:** Generate multiple items, review/approve/reject each
**When:** User needs to fill distribution targets (e.g., "need 20 combat nodes for Act 2")
**UX:**
- User specifies constraints: "10 combat nodes, The Waste, Act 2-3"
- Batch job runs in background
- Progress: "Generating 3/10..." with cancel option
- Review queue shows generated nodes one at a time
- User approves (save), rejects (skip), or edits (save modified)
- Summary: "Approved 8/10, rejected 2"

**Implementation:**
- Background job with websocket/polling for progress
- Temp storage for generated nodes
- Batch operations endpoint with POST /api/nodes/batch
- Review UI separate from creation form

### Pattern 4: Critic-Guided Iteration (Cursor, Copilot Edits)
**What:** AI generates, second AI critiques, user sees both
**When:** Quality is critical; user wants expert guidance
**UX:**
- User generates content
- Critic LLM scores on dimensions: coherence (8/10), atmosphere (6/10), originality (7/10)
- Specific feedback: "Atmosphere could be stronger. Consider adding sensory details about the environment."
- User can regenerate with critic feedback injected into prompt
- OR user manually edits based on suggestions

**Implementation:**
- After generation, async critic call
- Critic uses specialized prompt: "Evaluate this narrative content on..."
- Structured output: scores + specific suggestions
- UI shows scores as badges, suggestions as tooltip or expandable section

## MVP Recommendation

For MVP, prioritize table stakes that enable core workflow:

### Phase 1: Essential Generation
1. **Provider integration** (OpenRouter initially for multi-model access)
2. **Single-field streaming generation** (narrative_hook only)
3. **Preview before save** (show generated text, edit, save)
4. **Regenerate button** (simple retry with same inputs)
5. **Cancel generation** (abort in-flight request)
6. **Basic error handling** (show error message, allow retry)

**Rationale:** Prove AI integration works end-to-end with minimal scope.

### Phase 2: Full-Node Generation
7. **Multi-field generation** (all fields for a node type)
8. **Prompt templating** (context-aware prompts per node type/biome)
9. **Generation presets** (creative/balanced/coherent modes)
10. **Cost visibility** (estimate before, actual after)
11. **Generation history** (undo last 3 generations)

**Rationale:** Complete the single-node creation workflow.

### Phase 3: Quality & Efficiency
12. **Critic LLM scoring** (DIFFERENTIATOR - automated quality assessment)
13. **Field-level assists** (DIFFERENTIATOR - inline generation in manual forms)
14. **Smart retry with hints** (DIFFERENTIATOR - refine generation with feedback)

**Rationale:** Add differentiating features that improve quality and UX.

## Defer to Post-MVP

### Batch Generation Suite (Complex, requires job infrastructure)
- Bulk generation with progress tracking
- Batch operations with constraints
- Review queue workflow

**Reason to defer:** Requires background job system, websockets/polling, complex state management. Single-node generation must be solid first.

### Advanced Customization (Power user features)
- Prompt template editing UI
- Fine-tuned model support
- Collaborative prompt engineering

**Reason to defer:** Small user segment; requires robust defaults first. Can expose via config files initially.

### Analytics & Optimization (Post-launch insights)
- Generation analytics
- A/B testing prompts
- Cost optimization

**Reason to defer:** Need usage data first to understand patterns.

## Complexity Assessment

| Feature Category | Complexity | Dependencies |
|-----------------|------------|--------------|
| Provider integration | Medium | API clients, key management |
| Streaming generation | Medium | SSE or websockets, frontend state handling |
| Prompt templating | Low-Medium | Template engine, context injection |
| Preview/edit/save | Low | Form state management |
| Regenerate/cancel | Low | Request cancellation, state reset |
| Multi-field generation | Medium | Orchestration logic, error handling per field |
| Critic LLM | Medium-High | Second API call, scoring rubric design |
| Field-level assists | Low-Medium | UI integration, context assembly |
| Batch generation | High | Job queue, progress tracking, partial failure handling |
| Smart retry | Medium | Prompt engineering, feedback injection |

## Quality Control Feature Details

### Critic LLM Scoring
**What it evaluates:**
- Coherence: Does narrative flow logically?
- Atmosphere: Are mood/sensory details appropriate for biome/act?
- Originality: Does it avoid cliches/repetition?
- Length: Is it appropriate for field type?
- Consistency: Does it match existing graph context?

**Output format:**
```typescript
{
  overallScore: 7.5,
  dimensions: {
    coherence: { score: 8, feedback: "Narrative flows well but..." },
    atmosphere: { score: 6, feedback: "Could use more sensory detail..." },
    originality: { score: 8, feedback: "Fresh take on combat encounter" },
    length: { score: 9, feedback: "Appropriate length" }
  },
  recommendation: "ACCEPT" | "REVISE" | "REGENERATE"
}
```

### Smart Retry Patterns
**User wants to refine without full regeneration:**

1. **Tone adjustment:** "Make this darker/lighter/more humorous"
2. **Detail level:** "Add more sensory details" / "Make it more concise"
3. **Content shift:** "Focus more on character emotion" / "Emphasize environmental hazards"
4. **Consistency fix:** "Make it consistent with node X" / "Match Act 2 tone"

**Implementation:**
- Small text input next to Regenerate button
- Append user instruction to system prompt
- OR use separate "refinement" prompt that takes original + instruction
- Show both original and refined version for comparison

## Generation Mode Presets

Based on common creative AI patterns:

| Mode | Temperature | Top P | Use Case | Example |
|------|-------------|-------|----------|---------|
| **Focused** | 0.3 | 0.9 | Consistent, predictable content | Tutorial nodes, mechanical descriptions |
| **Balanced** | 0.7 | 0.95 | Default for most content | Standard combat, choices, passages |
| **Creative** | 0.9 | 0.98 | Varied, surprising content | Key story moments, unique encounters |
| **Exploratory** | 1.1 | 0.99 | Experimental, wild variations | Brainstorming, finding unusual angles |

## Cost Management Features

**Transparency is table stakes:**
- Show estimated tokens before generation
- Show actual cost after generation (with provider rate)
- Running total in session ("Generated 10 nodes, cost: $2.35")
- Budget warnings: "This batch will cost approximately $15-20"

**Cost optimization (differentiator):**
- Model selection per field type (cheap model for beats, expensive for critical hooks)
- Caching of common prompt components (provider-dependent)
- Multi-provider routing based on cost/quality tradeoff

## Confidence Assessment

| Feature Category | Confidence | Source |
|-----------------|------------|--------|
| Real-time streaming | HIGH | Industry standard since 2023; ChatGPT, Claude, all major LLM UIs use this |
| Regenerate/preview patterns | HIGH | Universal in AI writing tools (Sudowrite, NovelAI, Jasper, Copy.ai) |
| Critic LLM | MEDIUM | Common in code generation (Cursor, Copilot), less common in narrative tools but emerging pattern |
| Batch generation patterns | MEDIUM | Seen in Scenario.gg, Artbreeder, but UX varies significantly by tool |
| Field-level assists | HIGH | Standard in Notion AI, Google Docs AI, Confluence AI |
| Prompt customization | MEDIUM | Power user feature; implementation patterns vary |
| Cost management | HIGH | Critical for API-based tools; users demand transparency |

## Sources

**Note:** Due to research tool limitations, this analysis is based on training knowledge (cutoff January 2025) of established patterns in:
- Sudowrite (AI writing assistant for fiction)
- NovelAI (AI storytelling platform)
- AI Dungeon (AI-generated interactive fiction)
- Scenario.gg (AI game asset generation)
- Artbreeder Writer (AI creative writing)
- Notion AI, Google Docs AI (inline AI assists)
- Cursor, GitHub Copilot (code generation with quality feedback)

**Confidence caveat:** Feature landscape may have evolved since training cutoff. Recommend verifying current state of tools with WebSearch or official documentation for tools launched/updated in 2025-2026.
