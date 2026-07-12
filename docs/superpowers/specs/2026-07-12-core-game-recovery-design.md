# Core Game Recovery Design

**Status:** Approved design  
**Date:** 2026-07-12

## Goal

Restore development momentum by shipping a deterministic, curated 15–20 minute mini-run built from the game's existing combat content. A run contains three fights, persistent player state, deck growth, two meaningful between-fight decisions, and a clear victory or defeat.

The milestone proves the core game loop. It does not expand content production.

## Current State

The Godot project already contains five character classes, five starting decks, ten enemies, 96 player cards, 34 curios, duel combat, rewards, sanity, corruption, and multi-duel sequencing. The latest content-generation output is not reachable by the runtime: generated narrative JSON sits outside `packages/game/src`, and the narrative manager, UI, and encounter integration exist only as specifications.

The current Quick Duel sequence is a useful sandbox but not a run. It initializes persistent health without updating or restoring it, does not persist sanity, and routes New Game through a developer configuration screen. Character selection also depends on missing procedural-generation files and produces characters named `Unknown`.

## Scope

This milestone may change:

- `packages/game` runtime code, scenes, resources, tests, and documentation
- Root documentation needed to state the active milestone and frozen systems

The following remain frozen and unchanged:

- `packages/atlas`
- `packages/content-kit`
- Generated narrative JSON
- Narrative runtime, maps, shops, save/continue, unlocks, procedural routes, and procedural enemy order

Quick Duel remains available as a configurable single-duel developer sandbox but is no longer part of New Game. Its multi-enemy sequence mode is retired so `RunSession` is the sole multi-fight flow.

## Domain Model

### RunDefinition

A static Godot Resource describing one curated run. It contains:

- Run identifier and display name
- Exactly three ordered enemy resources
- Recovery amounts: 12 health and 4 sanity
- Card offer count: 3

`RunDefinition.is_valid()` requires three non-null enemies, valid enemy decks, nonnegative recovery values, and a positive offer count.

### RunSession

The runtime state and behavior for one active run. It replaces and deepens the current `DuelSequenceState` rather than adding another autoload. It owns:

- The selected definition, character, and seed
- Current fight index and lifecycle state
- Normalized persistent player state
- Sanity tiers that have already injected corruption cards
- Pending reward state
- Preparing the next `DuelConfig`
- Recording victory, defeat, recovery, and card choices

Its lifecycle states are `INACTIVE`, `FIGHT_READY`, `IN_DUEL`, `REWARD_PENDING`, `COMPLETED`, and `DEFEATED`. Every interface operation validates and atomically advances this state machine.

`GameManager` owns the session lifecycle and scene routing. `DuelManager` owns one duel. `DeckManager` owns the evolving deck. `CurioManager` owns run curios.

### RunSession Interface

The interface used by `GameManager` is deliberately small:

```gdscript
begin(definition, character, seed)
prepare_current_duel() -> DuelConfig
record_victory(player_data)
get_pending_card_offers() -> Array[CardData]
apply_card_reward(card)
apply_recovery()
record_defeat(reason)
is_complete() -> bool
```

Scenes do not edit session fields directly.

## Player Flow

```text
New Game
  -> Static Class Selection
  -> Claim Jumper
  -> Card or Recovery Choice
  -> Corrupt Sheriff
  -> Card or Recovery Choice
  -> Whispering Cultist
  -> Run Complete
```

Zero health or zero sanity routes immediately to Game Over. The Game Over view identifies the failure reason.

### Static Class Selection

Class selection displays the five existing `CharacterClass` resources and starting decks:

- Bushranger
- Prospector
- Tracker
- Publican
- Preacher

Procedural names and backstories leave the critical path. `CharacterGenerator` is removed from the autoload list, eliminating its missing-file errors while leaving its implementation dormant for possible later work.

### Curated Enemy Progression

| Fight | Enemy | Initial health | Purpose |
|---|---|---:|---|
| 1 | Claim Jumper | 24 | Straightforward physical pressure |
| 2 | Corrupt Sheriff | 32 | Defense, powers, and escalating control |
| 3 | Whispering Cultist | 40 | Sanity pressure and corruption |

These are initial balance values. They may change only in response to timed playtests while preserving the approved enemy order and intended difficulty curve.

## Between-Fight Choice

After fights one and two, the player chooses exactly one option:

- One of three distinct class-legal cards, permanently added through `DeckManager`
- Recover 12 health and 4 sanity, clamped to the character's maximums

Card offers may include cards already present in the deck, but the same card cannot appear twice on one offer screen. Candidates are filtered through `CharacterClass.can_use_card()` and weighted through `get_card_preference_weight()`.

If fewer than three legal cards can be loaded, the scene displays those available. If none can be loaded, recovery remains available. Fight three grants no reward and routes directly to Run Complete.

## Persistent and Reset State

After each victory, `RunSession` captures a normalized snapshot from `PlayerData`. The following persist:

- Current and maximum health
- Current and maximum sanity
- Gold
- Run-level corruption
- Character class resources and their maximums
- Sanity tiers that have already injected corruption cards
- Deck changes and curse cards through `DeckManager`
- Curios through `CurioManager`

The following reset before every duel:

- Energy to maximum
- Block to zero
- Hand, draw, discard, exhaust, and removed piles
- Turn counters and per-turn statistics
- Temporary cost reductions and gambling state
- Combat-only status effects and powers

Existing `PlayerData` and `Stats` serialization may provide the raw data, but the session normalizes it. The current serializers must be corrected because `Stats.get_save_data()` omits gold and `PlayerData.get_save_data()` includes combat-temporary fields.

## Determinism Contract

For a given game version:

> Same seed + same class + same player decisions produces the same card offers, shuffles, enemy choices, random effects, and outcome opportunities.

All gameplay randomness on the curated-run path uses the appropriate `SeedManager` stream. Reward candidates are sorted by stable resource path before seeded sampling so filesystem enumeration order cannot affect a run. The audit is limited to code reachable by the curated run; unrelated editor and identifier randomness is outside scope.

## Scene Responsibilities

- **Main Menu:** prepares a seed and opens class selection.
- **Class Selection:** displays static classes and begins the curated run.
- **Duel:** consumes a `DuelConfig` and reports victory plus `PlayerData`; it does not choose the next scene.
- **Between-Fight Choice:** displays prepared offers, accepts one choice, and requests the next duel.
- **Run Complete:** displays class, seed, fights won, final health and sanity, and cards added.
- **Game Over:** displays whether health or sanity ended the run.
- **Quick Duel:** configures one sandbox duel, remains independent, and cannot mutate an active curated run.

The existing `victory_reward` scene remains available to Quick Duel. The curated run receives a smaller dedicated between-fight scene so sandbox routing, random gold, and curio logic cannot leak into the core flow.

## Failure Handling

- Invalid definitions never create a partially active session. The game logs the cause, displays an error, and returns to the main menu.
- Run transitions are atomic. Only one reward may be pending, and it may be applied only once.
- A card reward is valid only when it is one of the session's prepared offers.
- Duplicate clicks and stale scene callbacks do nothing after the first valid choice.
- Invalid card resources are omitted from offers and logged.
- A malformed player snapshot safely ends the run instead of silently resetting progress.
- Starting a new curated run clears any previous session, deck, curios, and pending duel configuration.
- Quick Duel refuses to start while a curated session is active and does not offer multi-enemy sequencing.

## Testing Strategy

Tests are written before implementation and exercise module interfaces rather than scene internals.

### Unit tests

- `RunDefinition` accepts the approved definition and rejects every invalid shape.
- `RunSession` covers begin, duel preparation, victory, pending reward, choice, advancement, completion, and defeat.
- Persistent fields survive while every combat-temporary field resets.
- Gold and class resources survive serialization.
- Recovery clamps health and sanity to their maximums.
- A reward can be applied only once.
- Card offers are legal for the selected class and unique within a screen.
- Same seed and decisions produce identical offers and duel inputs.
- A fixed sample of ten distinct seeds produces at least two distinct offer sets.
- All five classes load valid starting decks.
- All three curated enemies load valid decks.

### Integration tests

- A headless run with simulated duel results traverses all three fights, both reward choices, and Run Complete.
- Health defeat and sanity defeat route to Game Over with the correct reason.
- Quick Duel cannot change curated session state.
- Existing card tests remain green.

### Verification

- Godot headless import/parse scan succeeds.
- The full GdUnit suite passes.
- Runtime boot contains no project-originated errors.
- A manual native playthrough covers card choice, recovery, victory, and defeat.
- A timed playthrough lands within 15–20 minutes.
- Repeating a run with the same seed, class, and decisions reproduces its offers and duel inputs.

## Acceptance Criteria

The milestone is complete when:

1. New Game launches the curated run without exposing developer configuration.
2. All five classes can enter fight one with valid starting decks.
3. The run contains exactly three fights in the approved order.
4. Health, sanity, gold, class resources, corruption progress, deck changes, curses, and curios persist correctly.
5. The player makes one card-or-recovery choice after each of the first two fights.
6. Health and sanity defeats end the run cleanly; the third victory reaches a summary.
7. The determinism contract is covered by automated regression tests.
8. The full test suite and headless runtime verification pass.
9. The project status documentation identifies this mini-run as the active milestone and Atlas, content-kit, and narrative generation as frozen.
