# Biomes

Eight biomes × four acts. Per-act presence weight (0–4). 0 = absent, 4 = dominant.

| Biome | Arrival (1) | Fever (2) | Blasphemy (3) | Unmaking (4) |
|-------|------------:|----------:|--------------:|-------------:|
| `township`     | 4 | 2 | 1 | 2 |
| `the_diggings` | 3 | 4 | 2 | 1 |
| `the_bush`     | 2 | 3 | 3 | 2 |
| `the_mines`    | 1 | 3 | 4 | 2 |
| `the_waste`    | 0 | 2 | 4 | 3 |
| `the_scar`     | 0 | 1 | 3 | 4 |
| `sacred_site`  | 1 | 2 | 3 | 4 |
| `the_river`    | 2 | 3 | 3 | 2 |

## Derived rules
- **available acts**: any act with weight > 0
- **primary acts**: any act with weight ≥ 3
- **act weight**: literal value from table

## Themes (defaults per biome)

| Biome | Themes |
|-------|--------|
| township     | civilization, commerce, order, hope, desperation |
| the_diggings | greed, labor, competition, exhaustion, discovery |
| the_bush     | isolation, survival, wilderness, danger, escape |
| the_mines    | darkness, claustrophobia, horror, corruption, madness |
| the_waste    | desolation, abandonment, consequence, death, secrets |
| the_scar     | wrongness, transformation, eldritch, ruin, power |
| sacred_site  | spirituality, taboo, ancient, revelation, sacrifice |
| the_river    | journey, trade, danger, life, transition |

## Entity types (defaults per biome)

| Biome | Entity types |
|-------|-------------|
| township     | human, merchant, official, desperate_seeker |
| the_diggings | human, claim_jumper, digger, wildlife |
| the_bush     | wildlife, bushranger, hermit, lost_soul |
| the_mines    | human, eldritch, corrupted, thing_below |
| the_waste    | wildlife, ghost, scavenger, eldritch |
| the_scar     | eldritch, transformed, horror, aberration |
| sacred_site  | spiritual, guardian, ancient, eldritch |
| the_river    | human, wildlife, trader, river_pirate |
