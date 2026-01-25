export type Comparator =
  | '=='
  | '!='
  | '>'
  | '>='
  | '<'
  | '<='
  | 'in'
  | 'not_in'
  | 'contains'
  | 'not_contains';

export type BoolExpr =
  | { allOf: BoolExpr[] }
  | { anyOf: BoolExpr[] }
  | { noneOf: BoolExpr[] }
  | Condition;

export type Condition =
  | FlagCondition
  | ResourceCondition
  | TagCondition
  | BiomeCondition
  | ActCondition
  | DifficultyCondition
  | CooldownCondition
  | SeenCondition
  | BindingCondition;

export interface Eligibility {
  /** Hard gates: if false, beat is not eligible */
  when: BoolExpr;

  /** Optional: additional "specificity" signals for saliency/selection */
  saliency?: Saliency;

  /** Repeat rules (storylet dimension: repeatability) */
  repeat?: RepeatPolicy;

  /** Optional: how this beat binds entities/locations at runtime */
  bindings?: BindingSpec[];
}

export interface Saliency {
  /** Adds to score if conditions are met; supports "more conditions = more specific" strategies [web:139]. */
  qualityRules?: QualityRule[];

  /** Discourage repetition / enforce texture */
  cooldownBias?: {
    key: string; // e.g. "combat", "trade", "void_reveal"
    minSteps?: number; // soft cooldown
    weight: number; // penalty if too recent
  }[];
}

export interface QualityRule {
  if: BoolExpr;
  add: number; // saliency score increment
  reason?: string;
}

export type RepeatPolicy =
  | { mode: 'once' }
  | { mode: 'repeatable'; minStepsBetween?: number; maxTimesPerRun?: number };

export interface FlagCondition {
  kind: 'flag';
  key: string; // e.g. "met_publican"
  op: '==' | '!=';
  value: boolean;
}

export interface ResourceCondition {
  kind: 'resource';
  key: 'health' | 'sanity' | 'gold' | 'food' | 'ammo' | string;
  op: Comparator; // typically >=, <=, in
  value: number | [number, number];
}

export interface TagCondition {
  kind: 'tag';
  scope: 'player' | 'run' | 'biome' | 'world' | 'deck' | 'node_context';
  op: 'contains' | 'not_contains';
  value: string; // e.g. "tainted", "greed", "human_threat"
}

export interface BiomeCondition {
  kind: 'biome';
  op: 'in' | 'not_in' | '==';
  value: string | string[]; // biome(s)
}

export interface ActCondition {
  kind: 'act';
  op: 'in' | 'not_in' | '==' | '>=' | '<=';
  value: number | number[]; // 1..4
}

export interface DifficultyCondition {
  kind: 'difficulty';
  op: '<=' | '>=';
  value: number; // compare to current difficulty budget
}

export interface CooldownCondition {
  kind: 'cooldown';
  key: string; // e.g. "combat", "rest", "void_whisper"
  op: '>=' | '<=';
  value: number; // steps since last occurrence
}

export interface SeenCondition {
  kind: 'seen';
  key: string; // usually node id, beat id, or group id
  op: '==' | '!=' | '>=' | '<=';
  value: number; // times seen
}

/**
 * Binding conditions support "parametrized storylets" that query/bind entities if available [web:137].
 */
export interface BindingCondition {
  kind: 'bind_exists';
  role: string; // e.g. "npc", "enemy", "landmark"
  requiredTags?: string[];
  count?: { op: '>=' | '==' | '<='; value: number };
}

export interface BindingSpec {
  role: string; // "npc.rival", "enemy.pack", "landmark.site"
  requiredTags?: string[]; // match against entity tags
  optionalTags?: string[];
  maxCandidates?: number; // cap to keep things predictable
  prefer?: { tag: string; weight: number }[];
}
