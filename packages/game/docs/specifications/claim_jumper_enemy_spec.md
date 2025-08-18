# Claim Jumper — Enemy Specification

Last verified: 2025-08-18

## Implementation snapshot

- Resource: `data/enemies/claim_jumper.tres`
- Script class: `EnemyState`
- Deck: `data/decks/enemy/claim_jumper_deck.tres`
  - Name: Claim Jumper's Arsenal
  - Theme: mining_opportunist
  - Difficulty: 2
  - Preferred strategy: opportunist
- Base stats:
  - Health: 30/30
  - Energy: 3/3
  - Sanity: 100/100
  - Defense: 0
- AI/config:
  - ai_type: aggressive
  - hand_size_limit: 7
  - cards_per_turn: 5
  - player_pattern_memory_size: 3
- Deck list:
  - attack/pickaxe_strike.tres ×2
  - attack/quick_shot.tres
  - attack/wild_shot.tres
  - skill/take_cover.tres ×2
  - fortune/strike_it_rich.tres
  - attack/ambush.tres

## Design notes

- Role: Opportunistic mid-tier foe that pressures with quick attacks and occasional gambles.
- Pattern: Uses generic EnemyState intent; no bespoke AI script yet.
- Counters: Block windows (take_cover) suggest turns to strike back.

## Deltas vs. original design (if any)

- Intent scripting not implemented beyond EnemyState fields.
- Loot table not yet defined in resource.

## Links

- Card database: `docs/content/CARD_DATABASE.md`
- Enemy patterns summary: `docs/content/ENEMY_PATTERNS.md`
