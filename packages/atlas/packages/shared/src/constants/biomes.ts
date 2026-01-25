import { Act, Biome } from '../types/biome.js';

export type ActPresence = 0 | 1 | 2 | 3 | 4;

export interface BiomeActPresence {
  [Act.Arrival]: ActPresence;
  [Act.Fever]: ActPresence;
  [Act.Blasphemy]: ActPresence;
  [Act.Unmaking]: ActPresence;
}

export const BIOME_ACT_PRESENCE: Record<Biome, BiomeActPresence> = {
  [Biome.Township]: {
    [Act.Arrival]: 4,
    [Act.Fever]: 2,
    [Act.Blasphemy]: 1,
    [Act.Unmaking]: 2,
  },
  [Biome.TheDiggings]: {
    [Act.Arrival]: 3,
    [Act.Fever]: 4,
    [Act.Blasphemy]: 2,
    [Act.Unmaking]: 1,
  },
  [Biome.TheBush]: {
    [Act.Arrival]: 2,
    [Act.Fever]: 3,
    [Act.Blasphemy]: 3,
    [Act.Unmaking]: 2,
  },
  [Biome.TheMines]: {
    [Act.Arrival]: 1,
    [Act.Fever]: 3,
    [Act.Blasphemy]: 4,
    [Act.Unmaking]: 2,
  },
  [Biome.TheWaste]: {
    [Act.Arrival]: 0,
    [Act.Fever]: 2,
    [Act.Blasphemy]: 4,
    [Act.Unmaking]: 3,
  },
  [Biome.TheScar]: {
    [Act.Arrival]: 0,
    [Act.Fever]: 1,
    [Act.Blasphemy]: 3,
    [Act.Unmaking]: 4,
  },
  [Biome.SacredSite]: {
    [Act.Arrival]: 1,
    [Act.Fever]: 2,
    [Act.Blasphemy]: 3,
    [Act.Unmaking]: 4,
  },
  [Biome.TheRiver]: {
    [Act.Arrival]: 2,
    [Act.Fever]: 3,
    [Act.Blasphemy]: 3,
    [Act.Unmaking]: 2,
  },
};

export function getAvailableActs(biome: Biome): Act[] {
  const presence = BIOME_ACT_PRESENCE[biome];
  return (Object.entries(presence) as [string, ActPresence][])
    .filter(([, value]) => value > 0)
    .map(([act]) => Number(act) as Act);
}

export function getPrimaryActs(biome: Biome): Act[] {
  const presence = BIOME_ACT_PRESENCE[biome];
  return (Object.entries(presence) as [string, ActPresence][])
    .filter(([, value]) => value >= 3)
    .map(([act]) => Number(act) as Act);
}

export function getActWeight(biome: Biome, act: Act): number {
  return BIOME_ACT_PRESENCE[biome][act];
}
