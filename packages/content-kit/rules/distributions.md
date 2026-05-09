# Node Distribution per Biome

Target counts of each node-type within each biome. Used by bulk generation to fill gaps.

| Biome | combat | choice | trade | rest | passage | state_check | transition | total |
|-------|-------:|-------:|------:|-----:|--------:|------------:|-----------:|------:|
| township     | 5  | 6 | 4 | 2 | 2 | 4 | 1 | 24 |
| the_diggings | 8  | 5 | 3 | 1 | 2 | 4 | 1 | 24 |
| the_bush     | 7  | 6 | 2 | 2 | 3 | 5 | 0 | 25 |
| the_mines    | 9  | 5 | 0 | 1 | 2 | 4 | 1 | 22 |
| the_waste    | 8  | 5 | 0 | 1 | 2 | 4 | 0 | 20 |
| the_scar     | 10 | 4 | 0 | 0 | 2 | 3 | 1 | 20 |
| sacred_site  | 5  | 8 | 0 | 2 | 2 | 5 | 1 | 23 |
| the_river    | 6  | 5 | 3 | 2 | 3 | 4 | 0 | 23 |

## Notes
- `trade` = 0 in dangerous/eldritch biomes (mines, waste, scar, sacred_site)
- `rest` = 0 in `the_scar` (no safety possible)
- `transition` = at most 1 per biome
- Combat-heavy biomes (mines, scar) push narrative dread; choice-heavy (sacred_site, township) push moral weight
