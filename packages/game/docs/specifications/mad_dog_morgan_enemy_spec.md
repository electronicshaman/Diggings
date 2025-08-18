# Mad Dog Morgan — Enemy Specification

Last verified: 2025-08-18

## Implementation snapshot

- Resource: `data/enemies/mad_dog_morgan.tres`
- Script class: `EnemyState`
- Deck: `data/decks/enemy/mad_dog_deck.tres`
  - Name: Mad Dog's Arsenal
  - Theme: gunfighter_legend
  - Difficulty: 4
  - Preferred strategy: aggressive_control
- Base stats:
  - Health: 50/50
  - Energy: 4/4
  - Sanity: 100/100
  - Defense: 0
- AI/config:
  - ai_type: cunning
  - hand_size_limit: 8
  - cards_per_turn: 6
  - player_pattern_memory_size: 5
- Deck list:
  - attack/six_shooter.tres
  - attack/fan_the_hammer.tres
  - attack/desperados_gambit.tres
  - attack/wild_shot.tres
  - attack/bounty_shot.tres
  - skill/outlaws_intuition.tres
  - skill/bush_survival.tres
  - skill/last_stand.tres
  - power/pub_brawl.tres
  - attack/dynamite.tres

## Design notes

- Role: Boss-tier duelist mixing burst damage with survival tools and a power.
- Pattern: Generic EnemyState intent; future bespoke phases could be added.
- Counters: Punish reload/setup turns; avoid telegraphed burst.

## Deltas vs. original design (if any)

- No bespoke intent script; enemy relies on deck configuration.
- Loot table not present yet.

## Links

- Card database: `docs/content/CARD_DATABASE.md`
- Enemy patterns summary: `docs/content/ENEMY_PATTERNS.md`
