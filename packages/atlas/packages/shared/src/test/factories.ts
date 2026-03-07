import {
  ChoiceNodeSchema,
  CombatNodeSchema,
  PassageNodeSchema,
  RestNodeSchema,
  StateCheckNodeSchema,
  TradeNodeSchema,
  TransitionNodeSchema,
} from "../schemas/node.js"
import { Act, Biome } from "../types/biome.js"
import {
  NodeType,
  type ChoiceNodeMetadata,
  type CombatNodeMetadata,
  type NodeContent,
  type PassageNodeMetadata,
  type RestNodeMetadata,
  type StateCheckNodeMetadata,
  type TradeNodeMetadata,
  type TransitionNodeMetadata,
} from "../types/node.js"

type DeepPartial<T> = {
  [K in keyof T]?: T[K] extends readonly unknown[]
    ? T[K]
    : T[K] extends object
      ? DeepPartial<T[K]>
      : T[K]
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value)
}

function mergeDeep<T>(base: T, overrides?: DeepPartial<T>): T {
  if (!overrides) {
    return base
  }

  const result: Record<string, unknown> = { ...(base as Record<string, unknown>) }

  for (const [key, overrideValue] of Object.entries(overrides)) {
    if (overrideValue === undefined) {
      continue
    }

    const baseValue = result[key]

    result[key] =
      isRecord(baseValue) && isRecord(overrideValue)
        ? mergeDeep(baseValue, overrideValue)
        : overrideValue
  }

  return result as T
}

function createBaseContent(): NodeContent {
  return {
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
  }
}

function createBaseNode() {
  return {
    id: "TOWNSHIP_NODE_001",
    biome: Biome.Township,
    name: "Lanterns At Dusk",
    acts: [Act.Arrival],
    actVariant: false,
    isReplaceable: true,
    replacementTags: ["settlement", "intro"],
    themes: ["survival", "greed"],
    entityTypes: ["prospector"],
    content: createBaseContent(),
  }
}

export function createMockCombatNode(
  overrides?: DeepPartial<CombatNodeMetadata>
): CombatNodeMetadata {
  const node = mergeDeep<CombatNodeMetadata>(
    {
      ...createBaseNode(),
      id: "TOWNSHIP_COMBAT_001",
      type: NodeType.Combat,
      enemyTypeHooks: ["desperate claim-jumper"],
      environmentalContext: "A narrow gully lined with broken sluice boxes",
      estimatedCombatDifficulty: 3,
    },
    overrides
  )

  return CombatNodeSchema.parse(node) as CombatNodeMetadata
}

export function createMockChoiceNode(
  overrides?: DeepPartial<ChoiceNodeMetadata>
): ChoiceNodeMetadata {
  const node = mergeDeep<ChoiceNodeMetadata>(
    {
      ...createBaseNode(),
      id: "TOWNSHIP_CHOICE_001",
      type: NodeType.Choice,
      consequenceHooks: ["the camp remembers who was fed"],
      dilemmaType: "moral",
    },
    overrides
  )

  return ChoiceNodeSchema.parse(node) as ChoiceNodeMetadata
}

export function createMockTradeNode(
  overrides?: DeepPartial<TradeNodeMetadata>
): TradeNodeMetadata {
  const node = mergeDeep<TradeNodeMetadata>(
    {
      ...createBaseNode(),
      id: "TOWNSHIP_TRADE_001",
      type: NodeType.Trade,
      traderArchetype: "itinerant outfitter",
      pricingHooks: ["prices rise with every rumor of gold"],
    },
    overrides
  )

  return TradeNodeSchema.parse(node) as TradeNodeMetadata
}

export function createMockRestNode(
  overrides?: DeepPartial<RestNodeMetadata>
): RestNodeMetadata {
  const node = mergeDeep<RestNodeMetadata>(
    {
      ...createBaseNode(),
      id: "TOWNSHIP_REST_001",
      type: NodeType.Rest,
      restType: "safe",
      interruptionChance: "low",
      dreamHooks: ["The river whispers in a dead man's voice"],
    },
    overrides
  )

  return RestNodeSchema.parse(node) as RestNodeMetadata
}

export function createMockPassageNode(
  overrides?: DeepPartial<PassageNodeMetadata>
): PassageNodeMetadata {
  const node = mergeDeep<PassageNodeMetadata>(
    {
      ...createBaseNode(),
      id: "TOWNSHIP_PASSAGE_001",
      type: NodeType.Passage,
      travelEventHooks: ["A wagon axle snaps in the red mud"],
      environmentalStorytelling: "Shallow graves mark the path to the next ridge.",
      resourceCost: {
        type: "supplies",
        amount: 2,
      },
    },
    overrides
  )

  return PassageNodeSchema.parse(node) as PassageNodeMetadata
}

export function createMockStateCheckNode(
  overrides?: DeepPartial<StateCheckNodeMetadata>
): StateCheckNodeMetadata {
  const node = mergeDeep<StateCheckNodeMetadata>(
    {
      ...createBaseNode(),
      id: "TOWNSHIP_STATE_CHECK_001",
      type: NodeType.StateCheck,
      conditionHooks: ["A hidden brand marks the trustworthy"],
      branchTargets: {
        success: "TOWNSHIP_PASSAGE_001",
        failure: "TOWNSHIP_COMBAT_001",
      },
    },
    overrides
  )

  return StateCheckNodeSchema.parse(node) as StateCheckNodeMetadata
}

export function createMockTransitionNode(
  overrides?: DeepPartial<TransitionNodeMetadata>
): TransitionNodeMetadata {
  const node = mergeDeep<TransitionNodeMetadata>(
    {
      ...createBaseNode(),
      id: "TOWNSHIP_TRANSITION_001",
      type: NodeType.Transition,
      actChangeTrigger: Act.Fever,
      narrativeSummary: "The township sheds its civility as fever takes hold.",
      worldStateShifts: ["Prices spike overnight", "Old alliances splinter"],
    },
    overrides
  )

  return TransitionNodeSchema.parse(node) as TransitionNodeMetadata
}
