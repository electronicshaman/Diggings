import { Biome, NodeType } from '../types/index.js';

export const DEFAULT_OUTPUT_DIR = './nodes';

export const DEFAULT_NODE_THEMES: Record<Biome, string[]> = {
  [Biome.Township]: ['civilization', 'commerce', 'order', 'hope', 'desperation'],
  [Biome.TheDiggings]: ['greed', 'labor', 'competition', 'exhaustion', 'discovery'],
  [Biome.TheBush]: ['isolation', 'survival', 'wilderness', 'danger', 'escape'],
  [Biome.TheMines]: ['darkness', 'claustrophobia', 'horror', 'corruption', 'madness'],
  [Biome.TheWaste]: ['desolation', 'abandonment', 'consequence', 'death', 'secrets'],
  [Biome.TheScar]: ['wrongness', 'transformation', 'eldritch', 'ruin', 'power'],
  [Biome.SacredSite]: ['spirituality', 'taboo', 'ancient', 'revelation', 'sacrifice'],
  [Biome.TheRiver]: ['journey', 'trade', 'danger', 'life', 'transition'],
};

export const DEFAULT_ENTITY_TYPES: Record<Biome, string[]> = {
  [Biome.Township]: ['human', 'merchant', 'official', 'desperate_seeker'],
  [Biome.TheDiggings]: ['human', 'claim_jumper', 'digger', 'wildlife'],
  [Biome.TheBush]: ['wildlife', 'bushranger', 'hermit', 'lost_soul'],
  [Biome.TheMines]: ['human', 'eldritch', 'corrupted', 'thing_below'],
  [Biome.TheWaste]: ['wildlife', 'ghost', 'scavenger', 'eldritch'],
  [Biome.TheScar]: ['eldritch', 'transformed', 'horror', 'aberration'],
  [Biome.SacredSite]: ['spiritual', 'guardian', 'ancient', 'eldritch'],
  [Biome.TheRiver]: ['human', 'wildlife', 'trader', 'river_pirate'],
};

export const COMBAT_DIFFICULTY_BY_BIOME: Record<Biome, (1 | 2 | 3 | 4 | 5)[]> = {
  [Biome.Township]: [1, 2, 2, 3],
  [Biome.TheDiggings]: [2, 2, 3, 3],
  [Biome.TheBush]: [2, 3, 3, 4],
  [Biome.TheMines]: [3, 3, 4, 4, 5],
  [Biome.TheWaste]: [3, 4, 4, 5],
  [Biome.TheScar]: [4, 4, 5, 5],
  [Biome.SacredSite]: [2, 3, 4, 5],
  [Biome.TheRiver]: [2, 2, 3, 3, 4],
};

export const TRADER_ARCHETYPES: Record<Biome, string[]> = {
  [Biome.Township]: ['general_store', 'gunsmith', 'apothecary', 'black_market'],
  [Biome.TheDiggings]: ['equipment_seller', 'water_vendor', 'claim_broker'],
  [Biome.TheBush]: ['traveling_merchant', 'hermit_trader'],
  [Biome.TheMines]: [],
  [Biome.TheWaste]: [],
  [Biome.TheScar]: [],
  [Biome.SacredSite]: [],
  [Biome.TheRiver]: ['river_trader', 'ferryman', 'smuggler'],
};

export const REST_TYPES_BY_BIOME: Record<Biome, ('safe' | 'risky' | 'sacred')[]> = {
  [Biome.Township]: ['safe', 'safe'],
  [Biome.TheDiggings]: ['risky'],
  [Biome.TheBush]: ['risky', 'risky'],
  [Biome.TheMines]: ['risky'],
  [Biome.TheWaste]: ['risky'],
  [Biome.TheScar]: [],
  [Biome.SacredSite]: ['sacred', 'sacred'],
  [Biome.TheRiver]: ['risky', 'safe'],
};

export const NODE_NAME_PREFIXES: Record<NodeType, string[]> = {
  [NodeType.Combat]: ['Encounter', 'Ambush', 'Confrontation', 'Battle', 'Skirmish'],
  [NodeType.Choice]: ['Decision', 'Crossroads', 'Dilemma', 'Opportunity', 'Moment'],
  [NodeType.Trade]: ['Market', 'Trader', 'Exchange', 'Merchant', 'Vendor'],
  [NodeType.Rest]: ['Camp', 'Shelter', 'Haven', 'Rest', 'Refuge'],
  [NodeType.Passage]: ['Path', 'Route', 'Trail', 'Journey', 'Crossing'],
  [NodeType.StateCheck]: ['Check', 'Test', 'Gate', 'Branch', 'Condition'],
  [NodeType.Transition]: ['Shift', 'Change', 'Turn', 'Pivot', 'Threshold'],
};
