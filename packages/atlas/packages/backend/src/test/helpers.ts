import type { SQLWrapper } from "drizzle-orm"
import { Hono } from "hono"
import { nodes } from "../db/schema.js"
import type { LLMCompletionResult } from "../services/generation/llm-client.js"

type NodeRow = typeof nodes.$inferSelect

interface MockListQuery {
  where(condition: SQLWrapper): MockListQuery
  limit(value: number): MockListQuery
  offset(value: number): Promise<NodeRow[]>
}

interface MockSelectBuilder {
  from(table: typeof nodes): MockListQuery
}

interface MockDbShape {
  select(): MockSelectBuilder
}

export interface MockDbController {
  db: MockDbShape
  setRows(rows: NodeRow[]): void
}

export function createMockDb(initialRows: NodeRow[] = []): MockDbController {
  let rows = initialRows

  const query: MockListQuery = {
    where() {
      return query
    },
    limit() {
      return query
    },
    async offset() {
      return rows
    },
  }

  return {
    db: {
      select() {
        return {
          from() {
            return query
          },
        }
      },
    },
    setRows(nextRows) {
      rows = nextRows
    },
  }
}

export function createTestApp(router: Hono): Hono {
  const app = new Hono()
  app.route("/api/nodes", router)
  return app
}

export function createMockLlmResponse(
  overrides: Partial<LLMCompletionResult> = {}
): LLMCompletionResult {
  return {
    content: "Generated test response",
    usage: {
      promptTokens: 10,
      completionTokens: 20,
      totalTokens: 30,
    },
    ...overrides,
  }
}
