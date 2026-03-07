import type { Node } from "../../db/schema.js"
import { nodes } from "../../db/schema.js"
import { afterEach, describe, expect, it, vi } from "vitest"
import { createMockDb, createTestApp } from "../../test/helpers.js"

function createNodeRow(): Node {
  return {
    id: 1,
    nodeId: "TOWNSHIP_COMBAT_001",
    type: "combat",
    biome: "township",
    name: "Lanterns At Dusk",
    acts: [1],
    actVariant: false,
    isReplaceable: true,
    replacementTags: ["settlement", "intro"],
    themes: ["survival", "greed"],
    entityTypes: ["prospector"],
    estimatedCombatDifficulty: 3,
    eligibility: null,
    resourceCost: null,
    potentialRewards: null,
    content: {
      narrative_hook: "A hush falls over the claim as the earth seems to listen back.",
      beats: [
        {
          id: "beat-1",
          role: "setup",
          text: "The miners pause when a strange echo rolls out from the shaft mouth.",
          outcomeTags: ["unease"],
        },
      ],
      mood: {
        tension: 3,
        atmosphere: "Dusty dread with a hint of reverence",
        sensoryDetails: ["coal smoke in the throat", "wet clay on the boots"],
      },
    },
    actVariants: null,
    enemyTypeHooks: ["desperate claim-jumper"],
    environmentalContext: "A narrow gully lined with broken sluice boxes",
    consequenceHooks: null,
    dilemmaType: null,
    traderArchetype: null,
    pricingHooks: null,
    restType: null,
    interruptionChance: null,
    dreamHooks: null,
    travelEventHooks: null,
    environmentalStorytelling: null,
    conditionHooks: null,
    branchTargets: null,
    actChangeTrigger: null,
    narrativeSummary: null,
    worldStateShifts: null,
    criticScore: null,
    generatedBy: null,
    createdAt: new Date("2026-03-07T00:00:00.000Z"),
    updatedAt: new Date("2026-03-07T00:00:00.000Z"),
  }
}

describe("GET /api/nodes", () => {
  afterEach(() => {
    vi.unmock("../../db/index.js")
    vi.resetModules()
  })

  it("returns a structured node list response", async () => {
    // Arrange
    const mockDb = createMockDb([createNodeRow()])

    vi.doMock("../../db/index.js", () => ({
      db: mockDb.db,
      nodes,
    }))

    const { nodesRouter } = await import("../nodes.js")
    const app = createTestApp(nodesRouter)

    // Act
    const response = await app.request("/api/nodes")
    const body = (await response.json()) as {
      data: Node[]
      pagination: {
        limit: number
        offset: number
        total: number
      }
    }

    // Assert
    expect(response.status).toBe(200)
    expect(body.data).toHaveLength(1)
    expect(body.data[0]?.nodeId).toBe("TOWNSHIP_COMBAT_001")
    expect(body.pagination).toEqual({
      limit: 50,
      offset: 0,
      total: 1,
    })
  })
})
