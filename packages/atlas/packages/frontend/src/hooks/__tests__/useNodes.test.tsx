import { waitFor } from "@testing-library/react"
import { describe, expect, it, vi } from "vitest"
import { useNodes } from "../useNodes"
import { renderHookWithProviders } from "../../test/helpers"

describe("useNodes", () => {
  it("maps the backend nodes response into hook data", async () => {
    // Arrange
    vi.spyOn(globalThis, "fetch").mockResolvedValue(
      new Response(
        JSON.stringify({
          data: [
            {
              nodeId: "TOWNSHIP_COMBAT_001",
              type: "combat",
              biome: "township",
              name: "Lanterns At Dusk",
              acts: [1],
              actVariant: false,
              isReplaceable: true,
              replacementTags: ["settlement"],
              themes: ["survival"],
              entityTypes: ["prospector"],
              estimatedCombatDifficulty: 3,
              enemyTypeHooks: ["desperate claim-jumper"],
              environmentalContext: "A narrow gully lined with broken sluice boxes",
            },
          ],
          pagination: {
            total: 1,
            limit: 25,
            offset: 0,
          },
        }),
        {
          status: 200,
          headers: {
            "Content-Type": "application/json",
          },
        }
      )
    )

    const { result } = renderHookWithProviders(() => useNodes({ limit: 25 }))

    // Act
    await waitFor(() => {
      expect(result.current.isSuccess).toBe(true)
    })

    // Assert
    expect(globalThis.fetch).toHaveBeenCalledWith("/api/nodes?limit=25", {
      headers: {
        "Content-Type": "application/json",
      },
    })
    expect(result.current.data).toEqual({
      nodes: [
        expect.objectContaining({
          id: "TOWNSHIP_COMBAT_001",
          type: "combat",
        }),
      ],
      total: 1,
      limit: 25,
      offset: 0,
    })
  })
})
