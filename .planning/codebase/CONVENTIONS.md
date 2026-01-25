# Coding Conventions

**Analysis Date:** 2026-01-25

## Naming Patterns

**Files:**
- PascalCase for React components: `ErrorBoundary.tsx`, `NodeListPage.tsx`, `ReviewStep.tsx`
- camelCase for services, hooks, utilities: `llm-client.ts`, `form-store.ts`, `useNodes.ts`
- kebab-case for directory names containing multiple related files: `config-advanced.ts`, `batch-processor.ts`
- Index files for barrel exports: `packages/shared/src/schemas/index.ts`, `packages/frontend/src/components/forms/index.ts`

**Functions:**
- camelCase for all function names: `generateNodeId()`, `getActiveProvider()`, `normalizeNode()`
- Prefix async functions consistently: `async function getNodes()`, `async function getActiveProvider()`
- Prefix utility functions with action verbs: `format*` (e.g., `formatBiomeToneForPrompt()`), `create*` (e.g., `createOpenAIClient()`), `encrypt*/decrypt*`
- React component functions are PascalCase: `function StepIndicator()`, `function NodeListPage()`
- Custom hooks follow pattern `useXxx`: `useNodes()`, `useNode()`, `useFormStore()`, `useCreateNode()`

**Variables:**
- camelCase for all local and module-level variables: `dbData`, `apiKey`, `connectionString`, `queryKey`
- Descriptive names over abbreviations: `nodeId` not `nId`, `searchParams` not `sp`
- Boolean variables/flags prefixed with `is` or `has`: `isActive`, `isReplaceable`, `hasError`, `enabled`
- Constants in UPPER_SNAKE_CASE only when exported as global constants: `API_BASE`, `STEP_LABELS`
- Private implementation details use leading underscore if needed internally (rare pattern in codebase)

**Types:**
- PascalCase for all TypeScript types and interfaces: `LLMProvider`, `LLMCompletionOptions`, `FormState`, `ErrorInfo`
- Discriminated union types named with descriptor: `AnyNodeMetadata`, `AnyNodeCreateSchema` (prefix with "Any" for unions)
- Schema types follow pattern `*Schema`: `CombatNodeSchema`, `ChoiceNodeSchema`, `AnyNodeMetadataSchema`
- Inferred types from Zod use pattern `z.infer<typeof SomeSchema>`: `type TypeSpecificFormData = z.infer<typeof typeSpecificSchema>`
- React prop interfaces named `*Props`: `ButtonProps`, `Props` (simple when component-specific)

## Code Style

**Formatting:**
- No explicit linter/formatter configured in project (no `.eslintrc`, `.prettierrc`)
- Manual formatting observed:
  - 2-space indentation (consistent across TS/TSX/JS)
  - Single quotes for imports and strings
  - Template literals for multiline strings and interpolation
  - Line breaks around major sections using comment separators: `// ============================================================================`

**Linting:**
- TypeScript strict mode enabled: `"strict": true` in all tsconfig.json files
- `noUnusedLocals` and `noUnusedParameters` enforced in frontend tsconfig
- `noFallthroughCasesInSwitch` enforced in frontend
- Import extensions required in ES modules: `.js` extension on relative imports (`import { db } from '../db/index.js'`)

## Import Organization

**Order (observed pattern):**
1. Third-party packages (React, libraries): `import { Hono } from 'hono'`
2. Internal shared packages: `import { AnyNodeMetadata } from '@node-gen-web/shared'`
3. Internal local imports: `import { db } from '../db/index.js'`
4. Types and interfaces declared after imports but before implementations

**Path Aliases:**
- `@/*` maps to `./src/*` in frontend: used for components, hooks, lib, store
  - Example: `import { Button } from '@/components/ui/button'`
- No path aliases configured in backend or shared packages
- Relative imports used in backend: `import { db } from '../db/index.js'`

**Module Pattern:**
- Barrel files export multiple related exports: `packages/shared/src/schemas/index.ts`
- Shared exports via subpath exports in package.json:
  ```json
  "exports": {
    ".": "./src/index.ts",
    "./schemas": "./src/schemas/index.ts",
    "./types": "./src/types/index.ts",
    "./constants": "./src/constants/index.ts"
  }
  ```

## Error Handling

**Patterns:**
- Try-catch blocks for database operations and external API calls:
  ```typescript
  try {
    const result = await db.select().from(nodes);
    return c.json({ data: result });
  } catch (error) {
    console.error('Error fetching beat roles:', error);
    return c.json({ error: error.message }, 500);
  }
  ```
- HTTP response codes returned directly: `return c.json({ error: 'Node not found' }, 404);`
- Early returns for validation failures (route handlers check existence before updates)
- Throw errors for configuration issues in services: `throw new Error('Provider X has no API key configured')`
- No custom error classes observed; using standard Error constructor

**Error Messages:**
- User-facing error messages in HTTP responses: `'Node not found'`, `'Request failed'`
- Console error logging for debugging: `console.error('Error:', error)`
- Fallback error handling in API client: `.catch(() => ({ message: 'Request failed' }))`

## Logging

**Framework:** console (Node.js built-in)

**Patterns:**
- `console.error()` for error conditions: Used in error handlers and catch blocks
- `console.log()` for informational messages: Used for server startup messages
- Hono middleware logger included but configuration not shown: `app.use('*', logger())`
- No structured logging (Winston, Pino, etc.) configured

**When to Log:**
- Database query errors: `console.error('Error fetching...', error)`
- API errors: `console.error('Error:', error.message)`
- Server startup: `console.log('🚀 Server starting on port ...')`
- Component lifecycle issues: ErrorBoundary logs caught errors: `console.error('ErrorBoundary caught an error:', error, errorInfo)`

## Comments

**When to Comment:**
- JSDoc blocks for exported functions and complex APIs
- Inline comments explaining validation constraints (Zod schemas): `// 1-3 sentences`, `// 5-10 words`
- Section dividers for organizing code blocks: `// ============================================================================`
- TODO comments for incomplete features: `// TODO: Replace with proper encryption (e.g., AES-256)`

**JSDoc/TSDoc:**
- Used extensively in services for function documentation:
  ```typescript
  /**
   * Simple base64 encryption/decryption for API keys
   * TODO: Replace with proper encryption (e.g., AES-256)
   */
  function encryptApiKey(apiKey: string): string {
  ```
- Documents purpose, parameters implicitly via types, returns implicitly via types
- Used for module-level documentation:
  ```typescript
  /**
   * Utility for building prompts with database-backed configuration
   * Loads biome tones, style guides, and act tones from database
   */
  ```

## Function Design

**Size:** Functions keep focused responsibilities, averaging 20-40 lines
- Route handlers under 30 lines (simple CRUD operations)
- Service functions 30-50 lines for database interactions
- Type-safe discriminated unions used to eliminate conditional logic duplication

**Parameters:**
- Explicit parameters over config objects for simple functions
- Configuration objects used for optional parameters with multiple variants:
  ```typescript
  interface LLMCompletionOptions {
    systemPrompt: string;
    userPrompt: string;
    temperature?: number;
    maxTokens?: number;
    responseFormat?: 'text' | 'json';
  }
  ```
- Destructuring in function signatures for cleaner code: `({ className, variant, size, asChild = false, ...props }, ref) =>`

**Return Values:**
- Explicit type annotations on all functions: `async function getActiveProvider(): Promise<LLMProvider | null>`
- Promise-returning functions always typed as `Promise<T>` or `Promise<void>`
- Discriminated union returns for conditional logic: `AnyNodeMetadata` union covering all 7 node types
- Data normalization functions return normalized type: `function normalizeNode(): AnyNodeMetadata`

## Module Design

**Exports:**
- Selective exports, not star exports (except for schema index files)
- Explicit re-exports from barrel files: `export { ActSchema, BiomeSchema, NodeTypeSchema, ... }`
- Type exports using `export type`: `export type LLMProviderType = 'openai' | 'openrouter' | 'anthropic'`
- Default exports used for route handlers: `export default generateRouter`

**Barrel Files:**
- Used in shared package for organizing schemas: `packages/shared/src/schemas/index.ts`
- Used in frontend for component exports: `packages/frontend/src/components/forms/index.ts`
- Pattern: re-export all exports from subdirectories for cleaner imports:
  ```typescript
  export { CombatForm, ChoiceForm, ... } from './...'
  ```

**Database Access Pattern:**
- Centralized database instance exported from single module: `packages/backend/src/db/index.ts`
- Database schema imported alongside db instance
- Drizzle ORM used with discriminated union for single-table design (all nodes in one table with type-specific nullable fields)

---

*Convention analysis: 2026-01-25*
