export enum Biome {
  Township = 'township',
  TheDiggings = 'the_diggings',
  TheBush = 'the_bush',
  TheMines = 'the_mines',
  TheWaste = 'the_waste',
  TheScar = 'the_scar',
  SacredSite = 'sacred_site',
  TheRiver = 'the_river',
}

export const BiomeDisplayNames: Record<Biome, string> = {
  [Biome.Township]: 'Township',
  [Biome.TheDiggings]: 'The Diggings',
  [Biome.TheBush]: 'The Bush',
  [Biome.TheMines]: 'The Mines',
  [Biome.TheWaste]: 'The Waste',
  [Biome.TheScar]: 'The Scar',
  [Biome.SacredSite]: 'Sacred Site',
  [Biome.TheRiver]: 'The River',
};

export const ALL_BIOMES: Biome[] = [
  Biome.Township,
  Biome.TheDiggings,
  Biome.TheBush,
  Biome.TheMines,
  Biome.TheWaste,
  Biome.TheScar,
  Biome.SacredSite,
  Biome.TheRiver,
];

export enum Act {
  Arrival = 1,
  Fever = 2,
  Blasphemy = 3,
  Unmaking = 4,
}

export const ActNames: Record<Act, string> = {
  [Act.Arrival]: 'Arrival',
  [Act.Fever]: 'Fever',
  [Act.Blasphemy]: 'Blasphemy',
  [Act.Unmaking]: 'Unmaking',
};

export const ActThemes: Record<Act, string[]> = {
  [Act.Arrival]: ['hope', 'hunger', 'opportunity'],
  [Act.Fever]: ['gold-mad competition', 'privation', 'first wrongness'],
  [Act.Blasphemy]: ['forbidden truths', 'blasphemy', 'isolation', 'corruption'],
  [Act.Unmaking]: ['transformation', 'futility', 'escape', 'obliteration'],
};

export const ALL_ACTS: Act[] = [Act.Arrival, Act.Fever, Act.Blasphemy, Act.Unmaking];
