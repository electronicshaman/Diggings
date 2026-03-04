# LLM Generation Services

This directory contains the multi-stage LLM content generation pipeline for narrative nodes.

## Architecture

The generation system uses a three-stage pipeline:

1. **Beat Outliner** - Creates structural outlines with beat roles and mood
2. **Prose Expander** - Expands outlines into full prose with outcomes/options
3. **Critic** - Evaluates quality and provides pass/fail with repair instructions

## Files

### Core Services

- **`llm-client.ts`** - Multi-provider LLM client
  - Supports OpenAI, OpenRouter, and Anthropic
  - Reads provider config from database (`llmProviders` table)
  - Exponential backoff retry logic
  - Base64 API key encryption (TODO: upgrade to AES-256)

- **`prompt-builder.ts`** - Database-backed prompt construction
  - Loads biome tones from `styleGuide` table
  - Loads act tones from `actTones` table
  - Formatting utilities for prompt injection
  - Context builder for node generation

- **`beat-outliner.ts`** - Stage 1: Beat structure generation
  - Creates narrative beat outlines
  - Uses beat sequences from `beatSequences` table
  - Weight-based sequence selection with act/tag filtering
  - Returns `BeatOutline` with hook, beats, and mood

- **`prose-expander.ts`** - Stage 2: Prose expansion
  - Expands beat outlines into full text
  - Generates outcomes (victory/defeat/neutral) based on node type
  - Generates choice options for `choice` nodes
  - Returns `ExpandedContent` with beats and outcomes

- **`critic.ts`** - Stage 3: Quality evaluation
  - Evaluates content against quality criteria
  - Returns pass/fail with score (0-100)
  - Provides specific issues with severity levels
  - Includes repair instructions for failed content

### Utilities

- **`batch-processor.ts`** - Bulk generation with concurrency
  - Processes multiple nodes in parallel
  - Configurable batch size (default: 5)
  - Progress tracking with callbacks
  - Automatic retry logic for failures
  - Uses settings from `generationSettings` table

- **`streaming.ts`** - Server-Sent Events (SSE) support
  - Streams generation progress to clients
  - Real-time stage updates (outlining → expanding → reviewing)
  - Compatible with Hono's streaming responses

- **`index.ts`** - Main export file

## Usage

### Single Node Generation

```typescript
import { generateSingle } from './services/generation';

const result = await generateSingle({
  nodeId: 'combat_001',
  nodeType: 'combat',
  biome: 'the_diggings',
  name: 'Claim Jumper Ambush',
  themes: ['violence', 'greed'],
  entityTypes: ['digger', 'claim_jumper'],
  act: 1,
  nodeMetadata: {
    enemyTypeHooks: ['claim_jumper', 'desperate_digger'],
    environmentalContext: 'abandoned_claim',
    estimatedCombatDifficulty: 3,
  },
}, {
  enableCritic: true,
  criticThreshold: 70,
  onProgress: (progress) => {
    console.log(`${progress.stage}: ${progress.progress}%`);
  },
});

if (result.stage === 'completed') {
  console.log('Content:', result.content);
  console.log('Critic Score:', result.critic?.score);
}
```

### Batch Generation

```typescript
import { generateBatch } from './services/generation';

const requests = [
  { nodeId: 'combat_001', nodeType: 'combat', /* ... */ },
  { nodeId: 'choice_001', nodeType: 'choice', /* ... */ },
  { nodeId: 'rest_001', nodeType: 'rest', /* ... */ },
];

const batchResult = await generateBatch(requests, {
  batchSize: 5,
  enableCritic: true,
  criticThreshold: 70,
  maxRetries: 3,
  onProgress: (progress) => {
    console.log(`[${progress.nodeId}] ${progress.stage}: ${progress.progress}%`);
  },
});

console.log(`Success: ${batchResult.successful}/${batchResult.total}`);
```

### Streaming with SSE

```typescript
import { streamSSE } from './services/generation';

// In a Hono route handler:
app.post('/api/generate/stream', async (c) => {
  const request = await c.req.json();
  return streamSSE(c, request);
});

// Client-side:
const eventSource = new EventSource('/api/generate/stream');
eventSource.addEventListener('progress', (e) => {
  const data = JSON.parse(e.data);
  console.log(`${data.stage}: ${data.progress}%`);
});
eventSource.addEventListener('complete', (e) => {
  const data = JSON.parse(e.data);
  console.log('Generated content:', data.content);
});
```

## Database Tables Used

- **`llmProviders`** - LLM provider configuration (API keys, models, etc.)
- **`generationSettings`** - Global generation settings (batch size, thresholds)
- **`beatSequences`** - Beat structure templates per node type
- **`styleGuide`** - Biome-specific atmosphere and voice notes
- **`actTones`** - Act-specific narrative tone guidance

## Configuration

### LLM Provider Setup

1. Insert provider into `llmProviders` table:
```sql
INSERT INTO llm_providers (name, type, base_url, encrypted_api_key, model, temperature, is_active)
VALUES (
  'OpenRouter',
  'openrouter',
  'https://openrouter.ai/api/v1',
  'BASE64_ENCODED_API_KEY',
  'anthropic/claude-3.5-sonnet',
  70,
  true
);
```

2. Only one provider can be `is_active = true` at a time

### Generation Settings

Settings are stored in the `generationSettings` table:
- `batchSize`: Concurrent generation limit (default: 5)
- `criticThreshold`: Minimum score to pass (default: 70)
- `enableCriticStage`: Enable/disable critic evaluation (default: true)
- `defaultTemperature`: Default LLM temperature (default: 70, maps to 0.7)
- `maxRetries`: Max retry attempts (default: 3)

## System Prompts

System prompts are currently embedded in each service file:
- `BEAT_OUTLINER_SYSTEM_PROMPT` in `beat-outliner.ts`
- `PROSE_EXPANDER_SYSTEM_PROMPT` in `prose-expander.ts`
- `CRITIC_SYSTEM_PROMPT` in `critic.ts`

**TODO (Phase 4)**: Move these to `packages/shared/src/constants/` for consistency with CLI.

## Error Handling

All generation functions use retry logic with exponential backoff:
- Initial retry delay: 1 second
- Subsequent delays: 2^attempt seconds (2s, 4s, 8s, etc.)
- Auth errors (401/403) are not retried
- Progress callbacks receive failure notifications

## Security Notes

**Current API Key Encryption**: Simple Base64 encoding (NOT secure for production)

**TODO**: Implement proper encryption:
```typescript
// Use Node.js crypto or a library like `sodium-native`
import crypto from 'crypto';

const algorithm = 'aes-256-gcm';
const key = crypto.scryptSync(process.env.ENCRYPTION_KEY, 'salt', 32);

function encrypt(text: string): string {
  const iv = crypto.randomBytes(16);
  const cipher = crypto.createCipheriv(algorithm, key, iv);
  // ... implementation
}
```

## Testing

**TODO (Phase 7)**: Add comprehensive tests for:
- Mock LLM responses for each stage
- Beat sequence selection logic
- Batch processing concurrency
- SSE stream formatting
- Retry logic and error handling

## Performance Considerations

- **Batch Size**: Higher values = more parallel requests but higher memory usage
- **Critic Stage**: Optional; disable for faster generation if quality checks aren't needed
- **Temperature**: Lower values (0.3-0.5) = more consistent output; higher (0.7-0.9) = more creative
- **Token Limits**: Default max_tokens is 2048; adjust based on content length requirements

## Future Enhancements

1. **Caching**: Cache biome/act tone lookups to reduce DB queries
2. **Streaming Generation**: Stream tokens as they're generated (not just progress updates)
3. **Quality Metrics**: Track critic scores over time for analytics
4. **A/B Testing**: Support multiple beat sequences and compare performance
5. **Custom Prompts**: Allow per-biome or per-node-type prompt overrides
