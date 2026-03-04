# Testing Patterns

**Analysis Date:** 2026-01-25

## Test Framework

**Runner:**
- Not detected - No test runner configured (no Jest, Vitest, Mocha packages in dependencies)

**Assertion Library:**
- Not detected - No test assertion library in dependencies

**Run Commands:**
- Not available - No test scripts defined in any package.json files
- Type checking only: `pnpm typecheck`, `tsc --noEmit`

## Test File Organization

**Current Status:**
- No test files present in codebase (no `.test.ts`, `.spec.ts`, or `__tests__` directories found)
- Testing infrastructure not yet implemented

**Recommended Location Pattern:**
- Co-locate test files with source: Place `*.test.ts` adjacent to source files
  - Example: `packages/backend/src/routes/nodes.test.ts` next to `packages/backend/src/routes/nodes.ts`
  - Example: `packages/frontend/src/hooks/useNodes.test.ts` next to `packages/frontend/src/hooks/useNodes.ts`

**Recommended Naming:**
- Use `.test.ts` suffix for clarity: `llm-client.test.ts`, `form-store.test.ts`
- Avoid `.spec.ts` to match single convention across codebase

## Test Structure

**Recommended Suite Organization (not yet implemented):**
```typescript
describe('NodeListPage', () => {
  describe('filtering', () => {
    it('should filter nodes by type', () => {
      // Arrange
      // Act
      // Assert
    });
  });

  describe('rendering', () => {
    it('should display loading skeleton while fetching', () => {
      // Test implementation
    });
  });
});
```

**Patterns to Establish:**
- Group related tests in nested describe blocks
- Use "should" language in test names: `it('should filter nodes by type')`
- Follow Arrange-Act-Assert pattern within each test
- Separate concerns: unit tests for logic, integration tests for API interaction

## Mocking

**Framework:**
- Not yet configured - Recommend Vitest built-in mocking or Jest for mocking needs

**Recommended Mocking Patterns:**

**React Query (TanStack Query) Mocking:**
```typescript
// Mock successful query response
vi.mock('@tanstack/react-query', () => ({
  useQuery: () => ({
    data: mockNodes,
    isLoading: false,
    error: null,
  }),
  useMutation: () => ({
    mutate: vi.fn(),
    isLoading: false,
  }),
}));
```

**API Client Mocking:**
```typescript
// Mock fetch in frontend
vi.mock('../lib/api', () => ({
  getNodes: vi.fn(() => Promise.resolve({
    nodes: mockData,
    total: 1,
    limit: 50,
    offset: 0,
  })),
}));
```

**Database Mocking (Backend):**
```typescript
// Mock Drizzle ORM queries
vi.mock('../db/index', () => ({
  db: {
    select: vi.fn(() => ({
      from: vi.fn(() => ({
        where: vi.fn(() => Promise.resolve(mockRows)),
      })),
    })),
  },
}));
```

**What to Mock:**
- External API calls (OpenAI, Anthropic, database)
- TanStack Query hooks (useQuery, useMutation)
- React Router navigation (useNavigate)
- Zustand stores (for state isolation)

**What NOT to Mock:**
- Utility functions (pure helpers, transformations)
- Zod schema validation (test actual validation logic)
- React components (except in specific component unit tests)
- Component hooks when testing component integration

## Fixtures and Factories

**Recommended Test Data Pattern (not yet implemented):**

**Location:**
- Create `packages/shared/src/test-fixtures/` directory for shared test data
- Create `packages/backend/src/test-fixtures/` for backend-specific data
- Create `packages/frontend/src/test-fixtures/` for frontend-specific data

**Factory Pattern Example:**
```typescript
// packages/shared/src/test-fixtures/node-factory.ts
export function createMockCombatNode(overrides?: Partial<CombatNodeMetadata>): CombatNodeMetadata {
  return {
    id: 'TOWNSHIP_COMBAT_001',
    type: 'combat',
    biome: 'township',
    name: 'Bandit Ambush',
    acts: [1, 2],
    isReplaceable: true,
    replacementTags: ['combat', 'outdoor'],
    themes: ['danger', 'combat'],
    entityTypes: ['bandit'],
    enemyTypeHooks: ['bandit-leader'],
    environmentalContext: 'forest road',
    estimatedCombatDifficulty: 3,
    content: {
      narrative_hook: 'Bandits emerge from the shadows.',
      beats: [...],
      mood: { tension: 4, atmosphere: 'tense', sensoryDetails: [] },
    },
    ...overrides,
  };
}

export function createMockChoiceNode(overrides?: Partial<ChoiceNodeMetadata>): ChoiceNodeMetadata {
  // Similar pattern for other node types
}
```

## Coverage

**Requirements:** Not enforced - No coverage configuration detected

**Recommended Setup:**
- Target 80% coverage for critical paths (API routes, services, custom hooks)
- Target 50% coverage for UI components (focus on logic, not rendering details)
- Exclude auto-generated files (migrations, schema reflections)

**View Coverage (to be implemented):**
```bash
vitest --coverage              # Generate coverage report
vitest --coverage --reporter=html  # HTML coverage report in coverage/
```

## Test Types

**Unit Tests:**
- Backend services: Test generation logic, LLM client methods, utility functions in isolation
  - Example: `packages/backend/src/services/generation/llm-client.test.ts`
  - Test `encryptApiKey()`, `decryptApiKey()`, provider client creation
  - Scope: Single function or small module, mocked dependencies

- Frontend hooks: Test custom hooks (useNodes, useFormStore, useCreateNode)
  - Example: `packages/frontend/src/hooks/useNodes.test.ts`
  - Test query key generation, filter parameters
  - Scope: Single hook function, mocked React Query

- Utilities: Test type guards, validators, transformations
  - Example: `packages/shared/src/test/normalize-node.test.ts`
  - Test discriminated union handling
  - Scope: Pure function tests

**Integration Tests:**
- API routes: Test full request-response cycle with mocked database
  - Example: `packages/backend/src/routes/nodes.test.ts`
  - Test POST /api/nodes creates with proper ID generation and validation
  - Test GET /api/nodes/:id returns 404 for missing nodes
  - Scope: Route handler + schema validation + database interactions

- React Query integration: Test hooks with real query client
  - Example: `packages/frontend/src/hooks/useNodes.test.ts` (integration variant)
  - Test cache invalidation on mutations
  - Test error states and retries
  - Scope: Hook + TanStack Query + mocked API

- Form submission: Test form store + mutations + API in browser
  - Example: `packages/frontend/src/routes/nodes/create.test.tsx`
  - Test wizard step progression
  - Test validation and error handling
  - Scope: Multi-step component interaction

**E2E Tests:**
- Not yet configured - Would test full user workflows
  - Recommend Playwright or Cypress for browser-based testing
  - Example flows: Create node → Edit node → Delete node
  - Setup would be in separate test directory: `e2e/` at project root

## Common Patterns

**Async Testing:**
```typescript
// Vitest pattern for async operations
it('should fetch nodes successfully', async () => {
  const { result } = renderHook(() => useNodes());

  await waitFor(() => {
    expect(result.current.isLoading).toBe(false);
  });

  expect(result.current.data).toBeDefined();
});

// Backend async pattern
it('should create node with generated ID', async () => {
  const response = await request(app).post('/api/nodes').send({
    type: 'combat',
    biome: 'township',
    // ... rest of node data
  });

  expect(response.status).toBe(201);
  expect(response.body.nodeId).toMatch(/^TOWNSHIP_COMBAT_\d+$/);
});
```

**Error Testing:**
```typescript
// Testing error states in hooks
it('should handle API errors gracefully', async () => {
  vi.mocked(getNodes).mockRejectedValueOnce(new Error('API Error'));

  const { result } = renderHook(() => useNodes());

  await waitFor(() => {
    expect(result.current.error).toBeDefined();
    expect(result.current.error?.message).toBe('API Error');
  });
});

// Testing validation errors
it('should reject invalid node type', async () => {
  const invalidNode = { ...validNode, type: 'invalid' };

  expect(() => {
    AnyNodeMetadataSchema.parse(invalidNode);
  }).toThrow();
});

// Testing route error handling
it('should return 404 for missing node', async () => {
  const response = await request(app).get('/api/nodes/NONEXISTENT');

  expect(response.status).toBe(404);
  expect(response.body.error).toBe('Node not found');
});
```

**Zustand Store Testing:**
```typescript
// Testing form store state management
it('should progress through wizard steps', () => {
  const { useFormStore } = require('../store/form-store');

  // Get fresh store instance per test
  const store = useFormStore.getState();

  expect(store.step).toBe(0);

  store.nextStep();
  expect(store.step).toBe(1);

  store.setFormData({ type: 'combat' });
  expect(store.formData.type).toBe('combat');

  store.resetForm();
  expect(store.step).toBe(0);
  expect(store.formData).toEqual({});
});
```

## Recommended Test Setup

**To Implement:**

1. **Install testing dependencies:**
   ```bash
   pnpm add -D vitest @testing-library/react @testing-library/dom @vitest/ui happy-dom
   pnpm add -D @vitest/coverage-v8  # For coverage
   ```

2. **Create vitest config at project root:**
   ```typescript
   // vitest.config.ts
   import { defineConfig } from 'vitest/config';

   export default defineConfig({
     test: {
       globals: true,
       environment: 'happy-dom',
       setupFiles: ['./vitest.setup.ts'],
       coverage: {
         provider: 'v8',
         exclude: [
           'node_modules/',
           'dist/',
           '**/*.test.*',
           '**/test-fixtures/**',
         ],
       },
     },
   });
   ```

3. **Add test scripts to package.json:**
   ```json
   {
     "scripts": {
       "test": "vitest",
       "test:ui": "vitest --ui",
       "test:coverage": "vitest --coverage"
     }
   }
   ```

4. **Create test fixtures directory** with factory functions for all node types

---

*Testing analysis: 2026-01-25*
