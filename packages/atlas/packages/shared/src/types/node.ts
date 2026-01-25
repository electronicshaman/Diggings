import type { Act, Biome } from './biome.js';
import type { Eligibility } from './eligibility.js';

export enum NodeType {
  Combat = 'combat',
  Choice = 'choice',
  StateCheck = 'state_check',
  Trade = 'trade',
  Passage = 'passage',
  Rest = 'rest',
  Transition = 'transition',
}

export const NodeTypeDisplayNames: Record<NodeType, string> = {
  [NodeType.Combat]: 'Combat',
  [NodeType.Choice]: 'Choice',
  [NodeType.StateCheck]: 'State Check',
  [NodeType.Trade]: 'Trade',
  [NodeType.Passage]: 'Passage',
  [NodeType.Rest]: 'Rest',
  [NodeType.Transition]: 'Transition',
};

export const ALL_NODE_TYPES: NodeType[] = [
  NodeType.Combat,
  NodeType.Choice,
  NodeType.StateCheck,
  NodeType.Trade,
  NodeType.Passage,
  NodeType.Rest,
  NodeType.Transition,
];

// Content types
export type BeatRole =
  | 'setup'
  | 'escalation'
  | 'reveal'
  | 'choice'
  | 'consequence'
  | 'button'
  | 'tension'
  | 'relief'
  | 'foreshadow'
  | 'reflection';

export interface StoryBeat {
  id: string;
  role: BeatRole;
  text: string;
  playerPrompt?: string;
  outcomeTags?: string[];
}

export interface ChoiceOption {
  id: string;
  label: string;
  description: string;
  consequenceTags: string[];
}

export interface OutcomeText {
  text: string;
  buttonText: string;
}

export interface NodeOutcomes {
  victory?: OutcomeText;
  defeat?: OutcomeText;
  neutral?: OutcomeText;
}

export interface MoodDescriptor {
  tension: 1 | 2 | 3 | 4 | 5;
  atmosphere: string;
  sensoryDetails: string[];
}

export interface NodeContent {
  narrative_hook: string;
  beats: StoryBeat[];
  options?: ChoiceOption[];
  outcomes?: NodeOutcomes;
  mood: MoodDescriptor;
}

export type ActVariantContent = Record<number, NodeContent>;

export interface ResourceCheck {
  type: string;
  amount: number;
  optional?: boolean;
}

// Base node metadata
export interface NodeMetadata {
  id: string;
  type: NodeType;
  biome: Biome;
  name: string;
  acts: Act[];
  actVariant?: boolean;
  isReplaceable: boolean;
  replacementTags: string[];
  themes: string[];
  entityTypes: string[];
  eligibility?: Eligibility;
  estimatedCombatDifficulty?: 1 | 2 | 3 | 4 | 5;
  resourceCost?: ResourceCheck;
  potentialRewards?: string[];
  // Content fields (populated by content generation)
  content?: NodeContent; // Single content (non-variant nodes)
  actVariants?: ActVariantContent; // Per-act content (actVariant: true nodes)
}

// Node type-specific metadata
export interface CombatNodeMetadata extends NodeMetadata {
  type: NodeType.Combat;
  enemyTypeHooks: string[];
  environmentalContext: string;
  estimatedCombatDifficulty: 1 | 2 | 3 | 4 | 5;
}

export interface ChoiceNodeMetadata extends NodeMetadata {
  type: NodeType.Choice;
  consequenceHooks: string[];
  dilemmaType: 'moral' | 'practical' | 'survival';
}

export interface TradeNodeMetadata extends NodeMetadata {
  type: NodeType.Trade;
  traderArchetype: string;
  pricingHooks: string[];
}

export interface RestNodeMetadata extends NodeMetadata {
  type: NodeType.Rest;
  restType: 'safe' | 'risky' | 'sacred';
  interruptionChance: 'none' | 'low' | 'medium' | 'high';
  dreamHooks?: string[];
}

export interface PassageNodeMetadata extends NodeMetadata {
  type: NodeType.Passage;
  travelEventHooks: string[];
  environmentalStorytelling: string;
  resourceCost: ResourceCheck;
}

export interface StateCheckNodeMetadata extends NodeMetadata {
  type: NodeType.StateCheck;
  conditionHooks: string[];
  branchTargets: {
    success: string;
    failure: string;
  };
}

export interface TransitionNodeMetadata extends NodeMetadata {
  type: NodeType.Transition;
  actChangeTrigger?: Act;
  narrativeSummary: string;
  worldStateShifts: string[];
}

export type AnyNodeMetadata =
  | CombatNodeMetadata
  | ChoiceNodeMetadata
  | TradeNodeMetadata
  | RestNodeMetadata
  | PassageNodeMetadata
  | StateCheckNodeMetadata
  | TransitionNodeMetadata;
