import { Biome, NodeType } from '../types/index.js';

export interface BiomeDistribution {
  [NodeType.Combat]: number;
  [NodeType.Choice]: number;
  [NodeType.Trade]: number;
  [NodeType.Rest]: number;
  [NodeType.Passage]: number;
  [NodeType.StateCheck]: number;
  [NodeType.Transition]: number;
}

export const BIOME_DISTRIBUTIONS: Record<Biome, BiomeDistribution> = {
  [Biome.Township]: {
    [NodeType.Combat]: 5,
    [NodeType.Choice]: 6,
    [NodeType.Trade]: 4,
    [NodeType.Rest]: 2,
    [NodeType.Passage]: 2,
    [NodeType.StateCheck]: 4,
    [NodeType.Transition]: 1,
  },
  [Biome.TheDiggings]: {
    [NodeType.Combat]: 8,
    [NodeType.Choice]: 5,
    [NodeType.Trade]: 3,
    [NodeType.Rest]: 1,
    [NodeType.Passage]: 2,
    [NodeType.StateCheck]: 4,
    [NodeType.Transition]: 1,
  },
  [Biome.TheBush]: {
    [NodeType.Combat]: 7,
    [NodeType.Choice]: 6,
    [NodeType.Trade]: 2,
    [NodeType.Rest]: 2,
    [NodeType.Passage]: 3,
    [NodeType.StateCheck]: 5,
    [NodeType.Transition]: 0,
  },
  [Biome.TheMines]: {
    [NodeType.Combat]: 9,
    [NodeType.Choice]: 5,
    [NodeType.Trade]: 0,
    [NodeType.Rest]: 1,
    [NodeType.Passage]: 2,
    [NodeType.StateCheck]: 4,
    [NodeType.Transition]: 1,
  },
  [Biome.TheWaste]: {
    [NodeType.Combat]: 8,
    [NodeType.Choice]: 5,
    [NodeType.Trade]: 0,
    [NodeType.Rest]: 1,
    [NodeType.Passage]: 2,
    [NodeType.StateCheck]: 4,
    [NodeType.Transition]: 0,
  },
  [Biome.TheScar]: {
    [NodeType.Combat]: 10,
    [NodeType.Choice]: 4,
    [NodeType.Trade]: 0,
    [NodeType.Rest]: 0,
    [NodeType.Passage]: 2,
    [NodeType.StateCheck]: 3,
    [NodeType.Transition]: 1,
  },
  [Biome.SacredSite]: {
    [NodeType.Combat]: 5,
    [NodeType.Choice]: 8,
    [NodeType.Trade]: 0,
    [NodeType.Rest]: 2,
    [NodeType.Passage]: 2,
    [NodeType.StateCheck]: 5,
    [NodeType.Transition]: 1,
  },
  [Biome.TheRiver]: {
    [NodeType.Combat]: 6,
    [NodeType.Choice]: 5,
    [NodeType.Trade]: 3,
    [NodeType.Rest]: 2,
    [NodeType.Passage]: 3,
    [NodeType.StateCheck]: 4,
    [NodeType.Transition]: 0,
  },
};

export function getBiomeTotal(biome: Biome): number {
  const dist = BIOME_DISTRIBUTIONS[biome];
  return Object.values(dist).reduce((sum, count) => sum + count, 0);
}

export function getTypeTotal(nodeType: NodeType): number {
  return Object.values(BIOME_DISTRIBUTIONS).reduce(
    (sum, dist) => sum + dist[nodeType],
    0
  );
}

export function getGrandTotal(): number {
  return Object.values(Biome).reduce(
    (sum, biome) => sum + getBiomeTotal(biome as Biome),
    0
  );
}
