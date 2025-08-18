# Enemy Patterns

Last verified: 2025-08-18

## Implemented Enemies (snapshot)

Detected enemy resources in `data/enemies/`:

- `claim_jumper.tres`
- `mad_dog_morgan.tres`

If more exist, expand this list after adding assets.

## Implementation snapshots

### Claim Jumper

- Resource: `data/enemies/claim_jumper.tres`
- Deck: `data/decks/enemy/claim_jumper_deck.tres`
	- Name: Claim Jumper's Arsenal
	- Theme: mining_opportunist
	- Difficulty: 2
	- Preferred strategy: opportunist
- Stats:
	- Health: 30/30
	- Energy: 3/3
	- Sanity: 100/100
	- Defense: 0
- AI/config:
	- ai_type: aggressive
	- hand_size_limit: 7
	- cards_per_turn: 5
	- player_pattern_memory_size: 3
- Deck list (from DeckData.card_paths):
	- attack/pickaxe_strike.tres ×2
	- attack/quick_shot.tres
	- attack/wild_shot.tres
	- skill/take_cover.tres ×2
	- fortune/strike_it_rich.tres
	- attack/ambush.tres
- Intent model: uses generic EnemyState intent fields; no bespoke intent script defined yet.

### Mad Dog Morgan

- Resource: `data/enemies/mad_dog_morgan.tres`
- Deck: `data/decks/enemy/mad_dog_deck.tres`
	- Name: Mad Dog's Arsenal
	- Theme: gunfighter_legend
	- Difficulty: 4
	- Preferred strategy: aggressive_control
- Stats:
	- Health: 50/50
	- Energy: 4/4
	- Sanity: 100/100
	- Defense: 0
- AI/config:
	- ai_type: cunning
	- hand_size_limit: 8
	- cards_per_turn: 6
	- player_pattern_memory_size: 5
- Deck list (from DeckData.card_paths):
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
- Intent model: uses generic EnemyState intent fields; no bespoke intent script defined yet.

## Pattern Structure

Each enemy should define:

- Name and description
- Stats: health, damage profile, initiative
- Intent pattern: telegraphed actions per turn
- Special mechanics: corruption, on-hit effects, phases
- Loot table

## Next Steps

- Document intents for existing enemies by inspecting their `.tres` and scripts under `scripts/enemies/` (if present).
- Add a table per enemy with at least two example turns of intents.
- Link to encounter definitions in `data/encounters/` where relevant.
