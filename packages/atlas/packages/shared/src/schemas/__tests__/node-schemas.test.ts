import { ChoiceNodeSchema, CombatNodeSchema } from "../node.js"
import {
  createMockChoiceNode,
  createMockCombatNode,
} from "../../test/factories.js"
import { describe, expect, it } from "vitest"

describe("node schemas", () => {
  it("parses a valid combat node", () => {
    // Arrange
    const combatNode = createMockCombatNode()

    // Act
    const result = CombatNodeSchema.safeParse(combatNode)

    // Assert
    expect(result.success).toBe(true)
    expect(result.success && result.data.type).toBe("combat")
  })

  it("rejects an invalid choice node", () => {
    // Arrange
    const invalidChoiceNode = {
      ...createMockChoiceNode(),
      consequenceHooks: [],
    }

    // Act
    const result = ChoiceNodeSchema.safeParse(invalidChoiceNode)

    // Assert
    expect(result.success).toBe(false)
    expect(result.success || result.error.issues[0]?.path).toContain("consequenceHooks")
  })
})
