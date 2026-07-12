# Core Game Recovery Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the developer-oriented multi-duel flow with a deterministic, curated three-fight mini-run that persists player state, offers card-or-recovery choices, and ends with a useful summary.

**Architecture:** Add a validated `RunDefinition`, a normalized `RunPlayerSnapshot`, and a stateful `RunSession` owned by `GameManager`. Keep `DuelManager`, `DeckManager`, and `CurioManager` responsible for one duel, the run deck, and curios respectively; route all multi-fight behavior through `RunSession` and leave Quick Duel as a single-fight sandbox.

**Tech Stack:** Godot 4.6.2, typed GDScript, Godot Resources and scenes, GdUnit4 6.1.1, Git, RTK-prefixed shell commands.

## Global Constraints

- The active milestone is a deterministic 15–20 minute run with exactly three fights.
- Enemy order is Claim Jumper, Corrupt Sheriff, Whispering Cultist.
- Initial enemy health is 24, 32, and 40 respectively.
- Between fights, offer three distinct class-legal cards or recovery of 12 health and 4 sanity.
- Same game version, seed, class, and player decisions must produce the same gameplay opportunities.
- Quick Duel remains a configurable single-duel sandbox and cannot modify an active curated run.
- Do not modify `packages/atlas`, `packages/content-kit`, or generated narrative JSON.
- Do not add maps, shops, save/continue, unlocks, procedural routes, narrative runtime, or new dependencies.
- Write failing tests before production changes in every task.
- Run commands from `/Users/robjones/Projects/Diggings` unless a step says otherwise.
- Before the first GdUnit command in a fresh checkout, run:

```bash
rtk proxy mkdir -p /tmp/diggings-home
rtk proxy env HOME=/tmp/diggings-home /opt/homebrew/bin/godot --headless --log-file /tmp/diggings-import.log --path packages/game/src --editor --quit
```

- The import command is expected to exit 0 and populate `packages/game/src/.godot/`. The macOS certificate warning is environmental; project parse errors are failures.

## File Map

### New run modules

- `packages/game/src/scripts/run/run_definition.gd` — validates static run configuration.
- `packages/game/src/scripts/run/reward_offer_generator.gd` — loads, filters, sorts, and seeded-samples card rewards.
- `packages/game/src/scripts/run/run_player_snapshot.gd` — persists only run-level player state and produces clean duel input.
- `packages/game/src/scripts/run/run_session.gd` — owns the run lifecycle and its small interface.
- `packages/game/src/data/runs/the_diggings_short_run.tres` — the single curated definition.

### New UI and intent files

- `packages/game/src/scripts/ui/between_fight_choice.gd` — renders pending offers and submits one decision.
- `packages/game/src/scenes/ui/between_fight_choice.tscn` — dedicated card-or-recovery screen.
- `packages/game/src/scripts/core/intents/game_over_intent.gd` — carries health or sanity defeat reason.

### New tests

- `packages/game/src/test/unit/run/test_run_definition.gd`
- `packages/game/src/test/unit/run/test_reward_offer_generator.gd`
- `packages/game/src/test/unit/run/test_run_player_snapshot.gd`
- `packages/game/src/test/unit/run/test_run_session.gd`
- `packages/game/src/test/unit/run/test_curated_run_resources.gd`
- `packages/game/src/test/unit/run/test_run_intents.gd`
- `packages/game/src/test/unit/run/test_curated_run_integration.gd`
- `packages/game/src/test/unit/cards/test_seeded_card_pile.gd`

### Existing files changed

- `packages/game/src/project.godot`
- `packages/game/src/scripts/autoloads/game_manager.gd`
- `packages/game/src/scripts/autoloads/scene_manager.gd`
- `packages/game/src/scripts/data/stats.gd`
- `packages/game/src/scripts/data/player_data.gd`
- `packages/game/src/scripts/data/card_pile.gd`
- `packages/game/src/scripts/data/duel_state.gd`
- `packages/game/src/scripts/data/enemy_card_manager.gd`
- `packages/game/src/scripts/combat/sanity_threshold_tracker.gd`
- `packages/game/src/scripts/combat/duel_scene_controller.gd`
- `packages/game/src/scripts/combat/duel_flow_controller.gd`
- `packages/game/src/scripts/combat/enemy_ai_controller.gd`
- `packages/game/src/scripts/managers/duel_manager.gd`
- `packages/game/src/scripts/handlers/core/handler_base.gd`
- `packages/game/src/scripts/handlers/types/damage_handler.gd`
- `packages/game/src/scripts/handlers/types/resource_handler.gd`
- `packages/game/src/scripts/ui/class_selection.gd`
- `packages/game/src/scenes/ui/class_selection.tscn`
- `packages/game/src/scripts/ui/quick_duel_setup.gd`
- `packages/game/src/scripts/ui/run_complete_scene.gd`
- `packages/game/src/scenes/ui/run_complete.tscn`
- `packages/game/src/scripts/ui/game_over.gd`
- `packages/game/src/scenes/ui/game_over.tscn`
- `packages/game/src/scripts/core/intents/run_complete_intent.gd`
- `packages/game/src/data/enemies/claim_jumper.tres`
- `packages/game/src/data/enemies/corrupt_sheriff.tres`
- `packages/game/src/data/enemies/whispering_cultist.tres`
- `README.md`
- `packages/game/README.md`
- `docs/game/summary.md`

### Files removed after callers migrate

- `packages/game/src/scripts/data/duel_sequence_state.gd`
- `packages/game/src/scripts/combat/duel_sequence_handler.gd`

---

### Task 1: Validated Run Definition and Curated Resource

**Files:**
- Create: `packages/game/src/scripts/run/run_definition.gd`
- Create: `packages/game/src/data/runs/the_diggings_short_run.tres`
- Create: `packages/game/src/test/unit/run/test_run_definition.gd`
- Modify: `packages/game/src/data/enemies/claim_jumper.tres:8-14`
- Modify: `packages/game/src/data/enemies/corrupt_sheriff.tres:8-14`
- Modify: `packages/game/src/data/enemies/whispering_cultist.tres:8-14`

**Interfaces:**
- Consumes: `EnemyState.card_manager.deck_data` from existing enemy resources.
- Produces: `RunDefinition.is_valid() -> bool` and `RunDefinition.get_validation_errors() -> Array[String]`.

- [ ] **Step 1: Write the failing definition tests**

Create `test_run_definition.gd`:

```gdscript
extends GdUnitTestSuite

func test_definition_requires_exactly_three_valid_enemies() -> void:
	var definition := RunDefinition.new()
	definition.run_id = &"test_run"
	definition.display_name = "Test Run"
	definition.enemies = [
		load("res://data/enemies/claim_jumper.tres"),
		load("res://data/enemies/corrupt_sheriff.tres")
	]
	assert_bool(definition.is_valid()).is_false()
	assert_array(definition.get_validation_errors()).contains(["Run must contain exactly 3 enemies"])

func test_definition_rejects_enemy_without_deck() -> void:
	var definition := RunDefinition.new()
	definition.run_id = &"test_run"
	definition.display_name = "Test Run"
	definition.enemies = [
		load("res://data/enemies/claim_jumper.tres"),
		EnemyState.new(),
		load("res://data/enemies/whispering_cultist.tres")
	]
	assert_bool(definition.is_valid()).is_false()
	assert_array(definition.get_validation_errors()).contains(["Enemy 2 has no valid deck"])

func test_curated_definition_is_valid() -> void:
	var definition := load("res://data/runs/the_diggings_short_run.tres") as RunDefinition
	assert_object(definition).is_not_null()
	assert_bool(definition.is_valid()).is_true()
	assert_int(definition.recovery_health).is_equal(12)
	assert_int(definition.recovery_sanity).is_equal(4)
	assert_int(definition.card_offer_count).is_equal(3)
```

- [ ] **Step 2: Run the focused test and confirm the red state**

Run:

```bash
rtk test /opt/homebrew/bin/godot --headless --log-file /tmp/diggings-gdunit.log --path packages/game/src -s addons/gdUnit4/bin/GdUnitCmdTool.gd -a test/unit/run/test_run_definition.gd --ignoreHeadlessMode
```

Expected: FAIL with a parse error identifying unknown type `RunDefinition` or a missing curated resource.

- [ ] **Step 3: Add the minimal definition implementation**

Create `run_definition.gd`:

```gdscript
extends Resource
class_name RunDefinition

@export var run_id: StringName
@export var display_name: String
@export var enemies: Array[Resource] = []
@export_range(0, 100) var recovery_health: int = 12
@export_range(0, 100) var recovery_sanity: int = 4
@export_range(1, 5) var card_offer_count: int = 3

func is_valid() -> bool:
	return get_validation_errors().is_empty()

func get_validation_errors() -> Array[String]:
	var errors: Array[String] = []
	if run_id.is_empty():
		errors.append("Run ID is empty")
	if display_name.strip_edges().is_empty():
		errors.append("Display name is empty")
	if enemies.size() != 3:
		errors.append("Run must contain exactly 3 enemies")
	for index in range(enemies.size()):
		var enemy := enemies[index]
		if not is_instance_valid(enemy):
			errors.append("Enemy %d is invalid" % (index + 1))
			continue
		var manager = enemy.get("card_manager")
		if not is_instance_valid(manager) or not is_instance_valid(manager.get("deck_data")):
			errors.append("Enemy %d has no valid deck" % (index + 1))
	if recovery_health < 0:
		errors.append("Recovery health cannot be negative")
	if recovery_sanity < 0:
		errors.append("Recovery sanity cannot be negative")
	if card_offer_count <= 0:
		errors.append("Card offer count must be positive")
	return errors
```

Create `the_diggings_short_run.tres`:

```ini
[gd_resource type="Resource" script_class="RunDefinition" load_steps=5 format=3]

[ext_resource type="Script" path="res://scripts/run/run_definition.gd" id="1_definition"]
[ext_resource type="Resource" path="res://data/enemies/claim_jumper.tres" id="2_claim"]
[ext_resource type="Resource" path="res://data/enemies/corrupt_sheriff.tres" id="3_sheriff"]
[ext_resource type="Resource" path="res://data/enemies/whispering_cultist.tres" id="4_cultist"]

[resource]
script = ExtResource("1_definition")
run_id = &"the_diggings_short_run"
display_name = "Descent into the Diggings"
enemies = Array[Resource]([ExtResource("2_claim"), ExtResource("3_sheriff"), ExtResource("4_cultist")])
recovery_health = 12
recovery_sanity = 4
card_offer_count = 3
```

Set both `current_health` and `max_health` to 24, 32, and 40 in the three enemy resources.

- [ ] **Step 4: Run the focused test and verify green**

Run the Task 1 GdUnit command again.

Expected: 3 test cases, 0 errors, 0 failures.

- [ ] **Step 5: Commit the definition slice**

```bash
rtk git add packages/game/src/scripts/run/run_definition.gd packages/game/src/data/runs/the_diggings_short_run.tres packages/game/src/test/unit/run/test_run_definition.gd packages/game/src/data/enemies/claim_jumper.tres packages/game/src/data/enemies/corrupt_sheriff.tres packages/game/src/data/enemies/whispering_cultist.tres
rtk git commit -m "feat: define the curated three-fight run"
```

---

### Task 2: Deterministic Class-Legal Reward Offers

**Files:**
- Create: `packages/game/src/scripts/run/reward_offer_generator.gd`
- Create: `packages/game/src/test/unit/run/test_reward_offer_generator.gd`

**Interfaces:**
- Consumes: `CharacterClass.can_use_card(CardData) -> bool`, `CharacterClass.get_card_preference_weight(CardData) -> float`, and a seeded `RandomNumberGenerator`.
- Produces: `RewardOfferGenerator.load_candidates(root_path) -> Array[CardData]` and `RewardOfferGenerator.generate(character, candidates, count, rng) -> Array[CardData]`.

- [ ] **Step 1: Write failing deterministic reward tests**

Create tests that load the Bushranger and Prospector resources, call `load_candidates("res://data/cards/player")`, and assert:

```gdscript
extends GdUnitTestSuite

func _paths(cards: Array[CardData]) -> Array[String]:
	var result: Array[String] = []
	for card in cards:
		result.append(card.resource_path)
	return result

func _unique_path_count(cards: Array[CardData]) -> int:
	var unique: Dictionary = {}
	for card in cards:
		unique[card.resource_path] = true
	return unique.size()

func test_same_seed_produces_same_unique_legal_offers() -> void:
	var character := load("res://data/characters/bushranger.tres") as CharacterClass
	var candidates := RewardOfferGenerator.load_candidates("res://data/cards/player")
	var first_rng := RandomNumberGenerator.new()
	var second_rng := RandomNumberGenerator.new()
	first_rng.seed = 424242
	second_rng.seed = 424242
	var first := RewardOfferGenerator.generate(character, candidates, 3, first_rng)
	var second := RewardOfferGenerator.generate(character, candidates, 3, second_rng)
	assert_array(_paths(first)).is_equal(_paths(second))
	assert_int(first.size()).is_equal(3)
	assert_int(_unique_path_count(first)).is_equal(3)
	for card in first:
		assert_bool(character.can_use_card(card)).is_true()

func test_ten_seed_sample_contains_multiple_offer_sets() -> void:
	var character := load("res://data/characters/prospector.tres") as CharacterClass
	var candidates := RewardOfferGenerator.load_candidates("res://data/cards/player")
	var offer_sets: Dictionary = {}
	for seed_value in range(100, 110):
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value
		offer_sets["|".join(_paths(RewardOfferGenerator.generate(character, candidates, 3, rng)))] = true
	assert_bool(offer_sets.size() >= 2).is_true()
```

- [ ] **Step 2: Run the focused test and confirm it fails**

Run:

```bash
rtk test /opt/homebrew/bin/godot --headless --log-file /tmp/diggings-gdunit.log --path packages/game/src -s addons/gdUnit4/bin/GdUnitCmdTool.gd -a test/unit/run/test_reward_offer_generator.gd --ignoreHeadlessMode
```

Expected: FAIL because `RewardOfferGenerator` is undefined.

- [ ] **Step 3: Implement stable loading and weighted sampling without replacement**

Create `reward_offer_generator.gd` with these methods:

```gdscript
extends RefCounted
class_name RewardOfferGenerator

static func load_candidates(root_path: String) -> Array[CardData]:
	var paths: Array[String] = []
	_collect_paths(root_path, paths)
	paths.sort()
	var cards: Array[CardData] = []
	for path in paths:
		var card := load(path) as CardData
		if card:
			cards.append(card)
	return cards

static func _collect_paths(path: String, output: Array[String]) -> void:
	var directory := DirAccess.open(path)
	if not directory:
		return
	directory.list_dir_begin()
	var entry := directory.get_next()
	while not entry.is_empty():
		var child := path.path_join(entry)
		if directory.current_is_dir():
			if not entry.begins_with("."):
				_collect_paths(child, output)
		elif entry.ends_with(".tres"):
			output.append(child)
		entry = directory.get_next()
	directory.list_dir_end()

static func generate(character: CharacterClass, candidates: Array[CardData], count: int, rng: RandomNumberGenerator) -> Array[CardData]:
	var pool: Array[CardData] = []
	for card in candidates:
		if is_instance_valid(card) and character.can_use_card(card):
			pool.append(card)
	pool.sort_custom(func(a: CardData, b: CardData): return a.resource_path < b.resource_path)
	var offers: Array[CardData] = []
	while offers.size() < count and not pool.is_empty():
		var total_weight := 0.0
		for card in pool:
			total_weight += maxf(0.0, character.get_card_preference_weight(card))
		if total_weight <= 0.0:
			break
		var roll := rng.randf() * total_weight
		var selected_index := pool.size() - 1
		for index in range(pool.size()):
			roll -= maxf(0.0, character.get_card_preference_weight(pool[index]))
			if roll <= 0.0:
				selected_index = index
				break
		offers.append(pool[selected_index])
		pool.remove_at(selected_index)
	return offers
```

- [ ] **Step 4: Run the test and verify deterministic green output**

Run the Task 2 command again.

Expected: 2 test cases, 0 errors, 0 failures.

- [ ] **Step 5: Commit the reward module**

```bash
rtk git add packages/game/src/scripts/run/reward_offer_generator.gd packages/game/src/test/unit/run/test_reward_offer_generator.gd
rtk git commit -m "feat: generate deterministic class card offers"
```

---

### Task 3: Normalize Persistent Player State

**Files:**
- Create: `packages/game/src/scripts/run/run_player_snapshot.gd`
- Create: `packages/game/src/test/unit/run/test_run_player_snapshot.gd`
- Modify: `packages/game/src/scripts/data/stats.gd:312-332`
- Modify: `packages/game/src/scripts/data/player_data.gd:35-65,587-680`
- Modify: `packages/game/src/scripts/combat/sanity_threshold_tracker.gd:27-130`

**Interfaces:**
- Consumes: `PlayerData`, `Stats`, and the existing sanity-tier enum.
- Produces: `RunPlayerSnapshot.capture(player_data) -> RunPlayerSnapshot`, `to_player_data() -> PlayerData`, and persistent corruption-tier serialization.

- [ ] **Step 1: Write failing snapshot tests**

Create tests covering health, sanity, energy reset, block reset, gold, class resources, corruption, and temporary modifiers:

```gdscript
extends GdUnitTestSuite

func test_snapshot_persists_run_state_and_resets_combat_state() -> void:
	var player := PlayerData.new()
	player.stats.max_health = 50
	player.stats.current_health = 31
	player.stats.max_sanity = 20
	player.stats.current_sanity = 9
	player.stats.max_energy = 4
	player.stats.current_energy = 1
	player.stats.defense = 17
	player.stats.current_gold = 23
	player.custom_resources = {GameEnums.CustomResourceType.BREW: 3}
	player.custom_resource_max = {GameEnums.CustomResourceType.BREW: 8}
	player.run_corruption = 6
	player.corruption_triggered_tiers = {Stats.SanityTier.SHAKEN: true}
	player.next_card_free = true
	player.attack_cost_reduction = 2

	var restored := RunPlayerSnapshot.capture(player).to_player_data()
	assert_int(restored.stats.current_health).is_equal(31)
	assert_int(restored.stats.current_sanity).is_equal(9)
	assert_int(restored.stats.current_energy).is_equal(4)
	assert_int(restored.stats.defense).is_equal(0)
	assert_int(restored.stats.current_gold).is_equal(23)
	assert_int(restored.custom_resources[GameEnums.CustomResourceType.BREW]).is_equal(3)
	assert_int(restored.run_corruption).is_equal(6)
	assert_bool(restored.corruption_triggered_tiers[Stats.SanityTier.SHAKEN]).is_true()
	assert_bool(restored.next_card_free).is_false()
	assert_int(restored.attack_cost_reduction).is_equal(0)

func test_stats_save_round_trip_includes_gold() -> void:
	var stats := Stats.new()
	stats.current_gold = 41
	var restored := Stats.new()
	restored.load_from_data(stats.get_save_data())
	assert_int(restored.current_gold).is_equal(41)
```

- [ ] **Step 2: Run the snapshot test and verify red**

Run:

```bash
rtk test /opt/homebrew/bin/godot --headless --log-file /tmp/diggings-gdunit.log --path packages/game/src -s addons/gdUnit4/bin/GdUnitCmdTool.gd -a test/unit/run/test_run_player_snapshot.gd --ignoreHeadlessMode
```

Expected: FAIL because `RunPlayerSnapshot`, `run_corruption`, and `corruption_triggered_tiers` do not exist and gold does not round-trip.

- [ ] **Step 3: Add the normalized snapshot and serialization fields**

Add `current_gold` to both `Stats.get_save_data()` and `Stats.load_from_data()`.

Add these fields to `PlayerData` and include them in `get_save_data()` and `load_from_data()`:

```gdscript
@export var run_corruption: int = 0
@export var corruption_triggered_tiers: Dictionary = {}
```

Create `run_player_snapshot.gd`:

```gdscript
extends Resource
class_name RunPlayerSnapshot

@export var character_class: CharacterClass
@export var health: int
@export var max_health: int
@export var sanity: int
@export var max_sanity: int
@export var max_energy: int
@export var gold: int
@export var custom_resources: Dictionary = {}
@export var custom_resource_max: Dictionary = {}
@export var run_corruption: int
@export var corruption_triggered_tiers: Dictionary = {}

static func capture(player: PlayerData) -> RunPlayerSnapshot:
	if not is_instance_valid(player) or not is_instance_valid(player.stats):
		return null
	var snapshot := RunPlayerSnapshot.new()
	snapshot.character_class = player.character_class
	snapshot.health = player.stats.current_health
	snapshot.max_health = player.stats.max_health
	snapshot.sanity = player.stats.current_sanity
	snapshot.max_sanity = player.stats.max_sanity
	snapshot.max_energy = player.stats.max_energy
	snapshot.gold = player.stats.current_gold
	snapshot.custom_resources = player.custom_resources.duplicate(true)
	snapshot.custom_resource_max = player.custom_resource_max.duplicate(true)
	snapshot.run_corruption = player.run_corruption
	snapshot.corruption_triggered_tiers = player.corruption_triggered_tiers.duplicate(true)
	return snapshot

func to_player_data() -> PlayerData:
	var player := PlayerData.new()
	player.set_character_class(character_class)
	player.stats.max_health = max_health
	player.stats.current_health = health
	player.stats.max_sanity = max_sanity
	player.stats.current_sanity = sanity
	player.stats.max_energy = max_energy
	player.stats.current_energy = max_energy
	player.stats.defense = 0
	player.stats.current_gold = gold
	player.custom_resources = custom_resources.duplicate(true)
	player.custom_resource_max = custom_resource_max.duplicate(true)
	player.run_corruption = run_corruption
	player.corruption_triggered_tiers = corruption_triggered_tiers.duplicate(true)
	return player
```

Update `SanityThresholdTracker` with an internal player reference and exact synchronization:

```gdscript
var _tracked_player: PlayerData

func sync_to_player(player_data) -> void:
	_tracked_player = player_data as PlayerData
	if _tracked_player and _tracked_player.stats:
		_last_tier = _tracked_player.stats.get_sanity_tier()
		_corruption_triggered_for_tiers = _tracked_player.corruption_triggered_tiers.duplicate(true)
	else:
		_last_tier = Stats.SanityTier.STABLE
		_corruption_triggered_for_tiers.clear()

func _trigger_corruption_for_tier(tier: Stats.SanityTier) -> void:
	if _corruption_triggered_for_tiers.get(tier, false):
		return
	_corruption_triggered_for_tiers[tier] = true
	if _tracked_player:
		_tracked_player.corruption_triggered_tiers = _corruption_triggered_for_tiers.duplicate(true)
	var card_path: String = CORRUPTION_CARDS.get(tier, "")
	if not card_path.is_empty():
		corruption_triggered.emit(tier, card_path)
```

- [ ] **Step 4: Run snapshot and existing card tests**

Run:

```bash
rtk test /opt/homebrew/bin/godot --headless --log-file /tmp/diggings-gdunit.log --path packages/game/src -s addons/gdUnit4/bin/GdUnitCmdTool.gd -a test/unit/run/test_run_player_snapshot.gd -a test/unit/cards/ --ignoreHeadlessMode
```

Expected: snapshot tests and existing card tests pass with 0 failures.

- [ ] **Step 5: Commit the persistence slice**

```bash
rtk git add packages/game/src/scripts/run/run_player_snapshot.gd packages/game/src/test/unit/run/test_run_player_snapshot.gd packages/game/src/scripts/data/stats.gd packages/game/src/scripts/data/player_data.gd packages/game/src/scripts/combat/sanity_threshold_tracker.gd
rtk git commit -m "feat: persist normalized player state between fights"
```

---

### Task 4: RunSession State Machine

**Files:**
- Create: `packages/game/src/scripts/run/run_session.gd`
- Create: `packages/game/src/test/unit/run/test_run_session.gd`

**Interfaces:**
- Consumes: `RunDefinition`, `RunPlayerSnapshot`, `RewardOfferGenerator`, an object implementing the current `DeckManager` methods, and `SeedManager.loot_rng`.
- Produces: the approved `RunSession` interface, `RunSession.EndReason`, `get_summary() -> Dictionary`, and lifecycle enum values.

- [ ] **Step 1: Write failing state-machine tests with a local fake deck manager**

The test file defines this fake and exercises every transition:

```gdscript
extends GdUnitTestSuite

class FakeDeckManager:
	extends RefCounted
	var cards: Array[CardData] = []
	func is_deck_available() -> bool: return not cards.is_empty()
	func get_current_deck() -> Array[CardData]: return cards.duplicate()
	func add_card(card: CardData) -> bool:
		cards.append(card)
		return true

func _session() -> RunSession:
	var fake := FakeDeckManager.new()
	fake.cards = [load("res://data/cards/player/attack/tent_stake.tres")]
	var seed_manager := SeedManager
	seed_manager.set_master_seed(12345)
	var session := RunSession.new(fake, seed_manager)
	var definition := load("res://data/runs/the_diggings_short_run.tres") as RunDefinition
	var character := load("res://data/characters/bushranger.tres") as CharacterClass
	assert_bool(session.begin(definition, character, 12345)).is_true()
	return session

func test_happy_path_advances_three_fights_and_two_choices() -> void:
	var session := _session()
	assert_int(session.state).is_equal(RunSession.State.FIGHT_READY)
	assert_str(session.prepare_current_duel().enemy_data.enemy_name).is_equal("Claim Jumper")
	var player := session.player_snapshot.to_player_data()
	player.stats.current_health = 40
	assert_bool(session.record_victory(player)).is_true()
	assert_int(session.state).is_equal(RunSession.State.REWARD_PENDING)
	var offers := session.get_pending_card_offers()
	assert_bool(session.apply_card_reward(offers[0])).is_true()
	assert_str(session.prepare_current_duel().enemy_data.enemy_name).is_equal("Corrupt Sheriff")
	assert_bool(session.record_victory(session.player_snapshot.to_player_data())).is_true()
	assert_bool(session.apply_recovery()).is_true()
	assert_str(session.prepare_current_duel().enemy_data.enemy_name).is_equal("Whispering Cultist")
	assert_bool(session.record_victory(session.player_snapshot.to_player_data())).is_true()
	assert_int(session.state).is_equal(RunSession.State.COMPLETED)
	assert_bool(session.is_complete()).is_true()

func test_reward_is_atomic_and_recovery_clamps() -> void:
	var session := _session()
	session.prepare_current_duel()
	var player := session.player_snapshot.to_player_data()
	player.stats.current_health = player.stats.max_health - 2
	player.stats.current_sanity = player.stats.max_sanity - 1
	session.record_victory(player)
	assert_bool(session.apply_recovery()).is_true()
	assert_bool(session.apply_recovery()).is_false()
	assert_int(session.player_snapshot.health).is_equal(session.player_snapshot.max_health)
	assert_int(session.player_snapshot.sanity).is_equal(session.player_snapshot.max_sanity)

func test_invalid_card_and_defeat_do_not_advance() -> void:
	var session := _session()
	session.prepare_current_duel()
	session.record_victory(session.player_snapshot.to_player_data())
	assert_bool(session.apply_card_reward(CardData.new())).is_false()
	session.record_defeat(RunSession.EndReason.SANITY)
	assert_int(session.state).is_equal(RunSession.State.DEFEATED)

func test_malformed_player_snapshot_ends_run_safely() -> void:
	var session := _session()
	session.prepare_current_duel()
	assert_bool(session.record_victory(null)).is_false()
	assert_int(session.state).is_equal(RunSession.State.DEFEATED)
	assert_int(session.end_reason).is_equal(RunSession.EndReason.INVALID_STATE)
```

- [ ] **Step 2: Run the state-machine test and confirm red**

Run:

```bash
rtk test /opt/homebrew/bin/godot --headless --log-file /tmp/diggings-gdunit.log --path packages/game/src -s addons/gdUnit4/bin/GdUnitCmdTool.gd -a test/unit/run/test_run_session.gd --ignoreHeadlessMode
```

Expected: FAIL because `RunSession` is undefined.

- [ ] **Step 3: Implement the state machine and approved interface**

Create `run_session.gd` with these exact public members:

```gdscript
extends RefCounted
class_name RunSession

enum State { INACTIVE, FIGHT_READY, IN_DUEL, REWARD_PENDING, COMPLETED, DEFEATED }
enum EndReason { NONE, HEALTH, SANITY, INVALID_STATE }

var state: State = State.INACTIVE
var definition: RunDefinition
var character: CharacterClass
var seed: int
var fight_index: int = 0
var fights_won: int = 0
var player_snapshot: RunPlayerSnapshot
var pending_card_offers: Array[CardData] = []
var cards_added: Array[String] = []
var end_reason: EndReason = EndReason.NONE

var _deck_manager: Object
var _seed_manager: Node
var _candidates: Array[CardData] = []

func _init(deck_manager: Object, seed_manager: Node) -> void:
	_deck_manager = deck_manager
	_seed_manager = seed_manager

func begin(run_definition: RunDefinition, selected_character: CharacterClass, run_seed: int) -> bool:
	if state != State.INACTIVE or not run_definition or not run_definition.is_valid() or not selected_character:
		return false
	if not _deck_manager.is_deck_available():
		return false
	definition = run_definition
	character = selected_character
	seed = run_seed
	fight_index = 0
	fights_won = 0
	cards_added.clear()
	pending_card_offers.clear()
	var player := PlayerData.new()
	player.set_character_class(character)
	player.stats.max_health = character.base_health
	player.stats.current_health = character.base_health
	player.stats.max_sanity = character.base_sanity
	player.stats.current_sanity = character.base_sanity
	player.stats.max_energy = character.base_energy
	player.stats.current_energy = character.base_energy
	player.stats.current_gold = character.starting_gold
	player_snapshot = RunPlayerSnapshot.capture(player)
	_candidates = RewardOfferGenerator.load_candidates("res://data/cards/player")
	state = State.FIGHT_READY
	return true
```

Implement the full state transition methods as follows:

```gdscript
func prepare_current_duel() -> DuelConfig:
	if state != State.FIGHT_READY or fight_index >= definition.enemies.size():
		return null
	var config := DuelConfig.new(
		_deck_manager.get_current_deck(),
		definition.enemies[fight_index].duplicate(true),
		"curated_run",
		{
			"curated_run": true,
			"player_data": player_snapshot.to_player_data(),
			"character_class": character
		}
	)
	if not config.is_valid():
		return null
	state = State.IN_DUEL
	return config

func record_victory(player: PlayerData) -> bool:
	if state != State.IN_DUEL:
		return false
	var captured := RunPlayerSnapshot.capture(player)
	if captured == null:
		record_defeat(EndReason.INVALID_STATE)
		return false
	player_snapshot = captured
	fights_won += 1
	if fight_index == definition.enemies.size() - 1:
		state = State.COMPLETED
		return true
	pending_card_offers = RewardOfferGenerator.generate(
		character,
		_candidates,
		definition.card_offer_count,
		_seed_manager.loot_rng
	)
	state = State.REWARD_PENDING
	return true

func get_pending_card_offers() -> Array[CardData]:
	return pending_card_offers.duplicate() if state == State.REWARD_PENDING else []

func apply_card_reward(card: CardData) -> bool:
	if state != State.REWARD_PENDING or not is_instance_valid(card):
		return false
	var valid_offer := false
	for offered in pending_card_offers:
		if offered.resource_path == card.resource_path:
			valid_offer = true
			break
	if not valid_offer or not _deck_manager.add_card(card):
		return false
	cards_added.append(card.card_name)
	_advance_after_reward()
	return true

func apply_recovery() -> bool:
	if state != State.REWARD_PENDING:
		return false
	player_snapshot.health = mini(
		player_snapshot.max_health,
		player_snapshot.health + definition.recovery_health
	)
	player_snapshot.sanity = mini(
		player_snapshot.max_sanity,
		player_snapshot.sanity + definition.recovery_sanity
	)
	_advance_after_reward()
	return true

func _advance_after_reward() -> void:
	pending_card_offers.clear()
	fight_index += 1
	state = State.FIGHT_READY

func record_defeat(reason: EndReason) -> void:
	if state in [State.COMPLETED, State.DEFEATED, State.INACTIVE]:
		return
	end_reason = reason
	state = State.DEFEATED

func is_complete() -> bool:
	return state == State.COMPLETED

func get_summary() -> Dictionary:
	return {
		"character_class": character.character_class_name if character else "Unknown",
		"seed": seed,
		"fights_won": fights_won,
		"final_health": player_snapshot.health if player_snapshot else 0,
		"final_sanity": player_snapshot.sanity if player_snapshot else 0,
		"cards_added": cards_added.duplicate(),
		"victory": state == State.COMPLETED,
		"end_reason": end_reason
	}
```

- [ ] **Step 4: Run all run-module tests**

Run:

```bash
rtk test /opt/homebrew/bin/godot --headless --log-file /tmp/diggings-gdunit.log --path packages/game/src -s addons/gdUnit4/bin/GdUnitCmdTool.gd -a test/unit/run/ --ignoreHeadlessMode
```

Expected: all run tests through Task 4 pass with 0 failures.

- [ ] **Step 5: Commit the state machine**

```bash
rtk git add packages/game/src/scripts/run/run_session.gd packages/game/src/test/unit/run/test_run_session.gd
rtk git commit -m "feat: add curated run state machine"
```

---

### Task 5: GameManager Ownership and Static Class Selection

**Files:**
- Create: `packages/game/src/test/unit/run/test_curated_run_resources.gd`
- Modify: `packages/game/src/scripts/autoloads/game_manager.gd:1-320`
- Modify: `packages/game/src/scripts/ui/class_selection.gd`
- Modify: `packages/game/src/scenes/ui/class_selection.tscn`
- Modify: `packages/game/src/project.godot:29-44`

**Interfaces:**
- Consumes: `RunSession`, curated definition, five `CharacterClass` resources, and `DeckManager.start_new_run_deck(String)`.
- Produces: `GameManager.has_active_run()`, `get_pending_run_rewards()`, `choose_run_card(card)`, `choose_run_recovery()`, `complete_curated_duel(player, winner)`, and `get_last_run_summary()`.

- [ ] **Step 1: Write failing resource and orchestration tests**

Create `test_curated_run_resources.gd`:

```gdscript
extends GdUnitTestSuite

const CLASS_PATHS: Array[String] = [
	"res://data/characters/bushranger.tres",
	"res://data/characters/prospector.tres",
	"res://data/characters/tracker.tres",
	"res://data/characters/publican.tres",
	"res://data/characters/preacher.tres"
]

func test_all_classes_have_valid_starting_decks() -> void:
	for path in CLASS_PATHS:
		var character := load(path) as CharacterClass
		assert_object(character).is_not_null()
		assert_bool(not character.starting_deck_resource.is_empty()).is_true()
		assert_bool(ResourceLoader.exists(character.starting_deck_resource)).is_true()
		assert_bool(not character.load_starting_deck().is_empty()).is_true()

func test_game_manager_can_begin_curated_run_for_each_class() -> void:
	for path in CLASS_PATHS:
		GameManager.reset_curated_run()
		var character := load(path) as CharacterClass
		assert_bool(GameManager.begin_curated_run(character, 777)).is_true()
		assert_bool(GameManager.has_active_run()).is_true()
		assert_bool(GameManager.is_duel_prepared()).is_true()
	GameManager.reset_curated_run()
```

- [ ] **Step 2: Run the resource test and confirm red**

Run:

```bash
rtk test /opt/homebrew/bin/godot --headless --log-file /tmp/diggings-gdunit.log --path packages/game/src -s addons/gdUnit4/bin/GdUnitCmdTool.gd -a test/unit/run/test_curated_run_resources.gd --ignoreHeadlessMode
```

Expected: FAIL because `begin_curated_run`, `has_active_run`, and `reset_curated_run` are undefined.

- [ ] **Step 3: Migrate GameManager to static CharacterClass and RunSession ownership**

Make these structural changes:

```gdscript
const CURATED_RUN_PATH := "res://data/runs/the_diggings_short_run.tres"

var selected_character: CharacterClass
var run_session: RunSession
var last_run_summary: Dictionary = {}

func has_active_run() -> bool:
	return run_session != null and run_session.state in [
		RunSession.State.FIGHT_READY,
		RunSession.State.IN_DUEL,
		RunSession.State.REWARD_PENDING
	]

func begin_curated_run(character: CharacterClass, run_seed: int) -> bool:
	reset_curated_run()
	selected_character = character
	current_character_class = character.character_class_name
	current_run_seed = run_seed
	if SeedManager.master_seed != run_seed:
		SeedManager.set_master_seed(run_seed)
	if not DeckManager.start_new_run_deck(current_character_class):
		return false
	run_session = RunSession.new(DeckManager, SeedManager)
	var definition := load(CURATED_RUN_PATH) as RunDefinition
	if not run_session.begin(definition, character, run_seed):
		reset_curated_run()
		return false
	current_run_hash_seed = SeedManager.get_hash_seed_string()
	pending_duel_config = run_session.prepare_current_duel()
	is_run_active = true
	change_state(GameState.PLAYING)
	return pending_duel_config != null and pending_duel_config.is_valid()

func reset_curated_run() -> void:
	pending_duel_config = null
	run_session = null
	selected_character = null
	DeckManager.clear_current_deck()
	CurioManager.reset_run_curios()

func get_pending_run_rewards() -> Array[CardData]:
	return run_session.get_pending_card_offers() if run_session else []

func get_last_run_summary() -> Dictionary:
	return last_run_summary.duplicate(true)

func complete_curated_duel(player: PlayerData, winner: String) -> void:
	if not has_active_run():
		return
	if winner != "player":
		var reason := RunSession.EndReason.SANITY if player.stats.current_sanity <= 0 else RunSession.EndReason.HEALTH
		run_session.record_defeat(reason)
		last_run_summary = run_session.get_summary()
		end_current_run(false)
		SceneManager.load_scene_by_name("game_over")
		return
	if not run_session.record_victory(player):
		last_run_summary = run_session.get_summary()
		end_current_run(false)
		SceneManager.load_scene_by_name("game_over")
		return
	if run_session.is_complete():
		last_run_summary = run_session.get_summary()
		end_current_run(true)
		SceneManager.load_scene_by_name("run_complete")
	else:
		SceneManager.load_scene_by_name("between_fight_choice")
```

Change `start_new_run` to `func start_new_run(character: CharacterClass, custom_seed: Variant = null, mode: GameMode = GameMode.STANDARD) -> bool`. Preserve or establish the seed using the existing `prepare_new_run()` logic, call `begin_curated_run(character, current_run_seed)`, call `SceneManager.load_scene_by_name("duel")` only on success, and return that success value. Remove `duel_sequence_state` and generated-character-specific `apply_character_data()` logic. Update `save_run_statistics()` to use `selected_character.character_class_name`.

Keep run corruption synchronized with the active `PlayerData`:

```gdscript
func add_corruption(amount: int) -> void:
	var updated := maxi(0, int(game_data.get("corruption", 0)) + amount)
	game_data["corruption"] = updated
	var player := get_player_data() as PlayerData
	if player:
		player.run_corruption = updated
	EventBus.corruption_changed.emit(amount)
```

Rewrite `class_selection.gd` around the fixed resources and these methods; retain the existing `update_seed_display()` formatting for the already-prepared hash seed:

```gdscript
extends Control
class_name ClassSelectionController

const CLASS_PATHS: Array[String] = [
	"res://data/characters/bushranger.tres",
	"res://data/characters/prospector.tres",
	"res://data/characters/tracker.tres",
	"res://data/characters/publican.tres",
	"res://data/characters/preacher.tres"
]

@onready var class_container: HBoxContainer = $MainContainer/ClassScroll/ClassContainer
@onready var back_button: Button = $MainContainer/BackButton
@onready var seed_label: Label = $SeedContainer/SeedLabel

func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	SeedManager.hash_seed_changed.connect(_on_hash_seed_changed)
	update_seed_display()
	for path in CLASS_PATHS:
		var character := load(path) as CharacterClass
		if character:
			class_container.add_child(_create_class_card(character))

func _create_class_card(character: CharacterClass) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(280, 400)
	var content := VBoxContainer.new()
	panel.add_child(content)
	var title := Label.new()
	title.text = character.character_class_name.to_upper()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(title)
	var description := Label.new()
	description.text = character.description
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(description)
	var stats := Label.new()
	stats.text = "Health: %d | Sanity: %d | Energy: %d\nStarting Gold: %d\nDifficulty: %d/4" % [
		character.base_health,
		character.base_sanity,
		character.base_energy,
		character.starting_gold,
		character.difficulty_rating
	]
	content.add_child(stats)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(spacer)
	var select_button := Button.new()
	select_button.text = "Select %s" % character.character_class_name
	select_button.pressed.connect(_on_character_selected.bind(character))
	content.add_child(select_button)
	return panel

func update_seed_display() -> void:
	var hash_seed := SeedManager.get_hash_seed_string()
	seed_label.text = "Seed: %s" % (hash_seed if not hash_seed.is_empty() else "Not Set")

func _on_hash_seed_changed(_new_hash_seed: String) -> void:
	update_seed_display()

func _on_character_selected(character: CharacterClass) -> void:
	if not GameManager.start_new_run(character):
		EventBus.emit_ui_notification("Could not start the curated run", "error")

func _on_back_pressed() -> void:
	SceneManager.load_scene_by_name("main_menu")
```

Remove all `GeneratedCharacter`, backstory, nickname, and starting-curio calls.

Change `class_selection.tscn` so `ClassContainer` is inside a horizontal `ScrollContainer` and remove the hard-coded Bushranger child card; the script creates five cards at runtime.

Remove this autoload line from `project.godot`:

```ini
CharacterGenerator="*res://scripts/autoloads/character_generator.gd"
```

- [ ] **Step 4: Run resource tests and boot class selection**

Run:

```bash
rtk test /opt/homebrew/bin/godot --headless --log-file /tmp/diggings-gdunit.log --path packages/game/src -s addons/gdUnit4/bin/GdUnitCmdTool.gd -a test/unit/run/test_curated_run_resources.gd --ignoreHeadlessMode
rtk proxy env HOME=/tmp/diggings-home /opt/homebrew/bin/godot --headless --log-file /tmp/diggings-class-selection.log --path packages/game/src --scene res://scenes/ui/class_selection.tscn --quit-after 20
rtk log /tmp/diggings-class-selection.log
```

Expected: tests pass; the scene reports no `Unknown` character names and no missing `names.json` or `generation_rules.json` errors.

- [ ] **Step 5: Commit GameManager and class selection**

```bash
rtk git add packages/game/src/test/unit/run/test_curated_run_resources.gd packages/game/src/scripts/autoloads/game_manager.gd packages/game/src/scripts/ui/class_selection.gd packages/game/src/scenes/ui/class_selection.tscn packages/game/src/project.godot
rtk git commit -m "feat: launch curated runs from static class selection"
```

---

### Task 6: Bridge Duel Results and Retire Sandbox Sequencing

**Files:**
- Modify: `packages/game/src/scripts/managers/duel_manager.gd:25-225`
- Modify: `packages/game/src/scripts/combat/duel_scene_controller.gd:138-225`
- Modify: `packages/game/src/scripts/ui/quick_duel_setup.gd:1-520`
- Delete: `packages/game/src/scripts/data/duel_sequence_state.gd`
- Delete: `packages/game/src/scripts/combat/duel_sequence_handler.gd`
- Test: `packages/game/src/test/unit/run/test_run_session.gd`

**Interfaces:**
- Consumes: `GameManager.has_active_run()` and `GameManager.complete_curated_duel(player, winner)`.
- Produces: one canonical handoff from `DuelManager` to `RunSession`, `GameManager.can_start_quick_duel() -> bool`, and a Quick Duel that supplies exactly one enemy.

- [ ] **Step 1: Extend the RunSession test to assert duel modifiers restore player state**

Add:

```gdscript
func test_prepared_duel_contains_normalized_player_data() -> void:
	var session := _session()
	session.player_snapshot.health = 19
	session.player_snapshot.sanity = 7
	var config := session.prepare_current_duel()
	assert_bool(config.get_modifier("curated_run", false)).is_true()
	var player := config.get_modifier("player_data") as PlayerData
	assert_int(player.stats.current_health).is_equal(19)
	assert_int(player.stats.current_sanity).is_equal(7)
	assert_int(player.stats.current_energy).is_equal(player.stats.max_energy)
```

Add this case to `test_curated_run_resources.gd`:

```gdscript
func test_quick_duel_is_blocked_only_while_curated_run_is_active() -> void:
	GameManager.reset_curated_run()
	assert_bool(GameManager.can_start_quick_duel()).is_true()
	var character := load("res://data/characters/bushranger.tres") as CharacterClass
	assert_bool(GameManager.begin_curated_run(character, 8080)).is_true()
	assert_bool(GameManager.can_start_quick_duel()).is_false()
	GameManager.reset_curated_run()
```

- [ ] **Step 2: Run the test and confirm any missing modifier fails**

Run the Task 4 focused command.

Expected: FAIL if Task 4 did not attach a normalized `player_data` modifier; otherwise the new test passes and establishes the bridge contract before scene changes.

- [ ] **Step 3: Route curated duel completion before Quick Duel logic**

In `DuelManager.end_duel()`, immediately after passive cleanup, add:

```gdscript
if GameManager.has_active_run():
	GameManager.complete_curated_duel(duel_state.player_data, winner)
	duel_ended.emit(winner)
	return
```

Remove `sequence_handler`, its initialization, and the entire `handle_duel_end()` branch. Keep the existing single Quick Duel victory/reward behavior.

Port the single Quick Duel behavior directly into `DuelManager.end_duel()` after the curated-run branch:

```gdscript
if GameManager.game_data.get("is_quick_duel", false):
	if winner == "player" and GameManager.game_data.get("show_quick_duel_rewards", false):
		var intent := RewardIntent.create_quick_duel_reward(false, "quick_duel_setup")
		SceneManager.load_scene_with_intent("res://scenes/ui/victory_reward.tscn", intent)
	else:
		SceneManager.load_scene_by_name("quick_duel_setup")
	duel_ended.emit(winner)
	return
```

In `duel_scene_controller.gd`, after `duel_state_manager.start_duel()` for a pending config, replace health-only overrides with:

```gdscript
var configured_player := duel_config.get_modifier("player_data", null) as PlayerData
if configured_player and duel_manager.duel_state:
	duel_manager.duel_state.player_data = configured_player
	GameManager.game_data["player"] = configured_player
```

Remove the forced Quick Duel scene changes from `_on_win_duel_pressed()` and `_on_lose_duel_pressed()`; those methods call `duel_manager.end_duel()` and let the owning flow route the result.

In Quick Duel, connect every enemy checkbox with `checkbox.toggled.connect(_on_enemy_toggled.bind(checkbox))` and add:

```gdscript
func _on_enemy_toggled(pressed: bool, selected_checkbox: CheckBox) -> void:
	if not pressed:
		return
	for child in enemy_container.get_children():
		if child is CheckBox and child != selected_checkbox:
			child.set_pressed_no_signal(false)
```

Add `func can_start_quick_duel() -> bool: return not has_active_run()` to GameManager. At the top of `_on_start_pressed()`, use it to reject an active curated run with `EventBus.emit_ui_notification("Finish the active run before using Quick Duel", "warning")`. Require `selected_enemies.size() == 1`, then call `_start_quick_duel(character, deck, selected_enemies[0], selected_curios, health_override, energy_override)` directly. Remove progress-row resume, multi-enemy initialization, and active-sequence cleanup. Delete the two obsolete sequence files after `rtk proxy rg -n "DuelSequenceState|DuelSequenceHandler|duel_sequence_state" packages/game/src` returns no production callers.

- [ ] **Step 4: Run run tests and Quick Duel smoke**

Run:

```bash
rtk test /opt/homebrew/bin/godot --headless --log-file /tmp/diggings-gdunit.log --path packages/game/src -s addons/gdUnit4/bin/GdUnitCmdTool.gd -a test/unit/run/ --ignoreHeadlessMode
rtk proxy env HOME=/tmp/diggings-home /opt/homebrew/bin/godot --headless --log-file /tmp/diggings-quick-duel.log --path packages/game/src --scene res://scenes/game/quick_duel_setup.tscn --quit-after 20
rtk log /tmp/diggings-quick-duel.log
```

Expected: run tests pass; Quick Duel finds five characters, at least five decks, ten enemies, and no sequence-class parse errors.

- [ ] **Step 5: Commit the duel bridge**

```bash
rtk git add packages/game/src/scripts/managers/duel_manager.gd packages/game/src/scripts/combat/duel_scene_controller.gd packages/game/src/scripts/ui/quick_duel_setup.gd packages/game/src/scripts/data/duel_sequence_state.gd packages/game/src/scripts/combat/duel_sequence_handler.gd packages/game/src/test/unit/run/test_run_session.gd
rtk git commit -m "feat: route duel results through curated runs"
```

---

### Task 7: Between-Fight Choice Scene

**Files:**
- Create: `packages/game/src/scripts/ui/between_fight_choice.gd`
- Create: `packages/game/src/scenes/ui/between_fight_choice.tscn`
- Modify: `packages/game/src/scripts/autoloads/scene_manager.gd:16-32`
- Modify: `packages/game/src/scripts/autoloads/game_manager.gd`
- Test: `packages/game/src/test/unit/run/test_curated_run_integration.gd`

**Interfaces:**
- Consumes: `GameManager.get_pending_run_rewards()`, `choose_run_card(card)`, and `choose_run_recovery()`.
- Produces: one guarded UI decision and transition to the next prepared duel, plus `GameManager.has_pending_run_reward()` and `get_run_progress_text()`.

- [ ] **Step 1: Write a failing scene contract test**

Create the integration test with this first case:

```gdscript
extends GdUnitTestSuite

func test_between_fight_scene_has_required_controls() -> void:
	var packed := load("res://scenes/ui/between_fight_choice.tscn") as PackedScene
	assert_object(packed).is_not_null()
	var scene := auto_free(packed.instantiate())
	assert_object(scene.get_node("Margin/VBox/RunStatus")).is_not_null()
	assert_object(scene.get_node("Margin/VBox/CardOffers")).is_not_null()
	assert_object(scene.get_node("Margin/VBox/RecoverButton")).is_not_null()
```

- [ ] **Step 2: Run the test and confirm the missing scene fails**

Run:

```bash
rtk test /opt/homebrew/bin/godot --headless --log-file /tmp/diggings-gdunit.log --path packages/game/src -s addons/gdUnit4/bin/GdUnitCmdTool.gd -a test/unit/run/test_curated_run_integration.gd --ignoreHeadlessMode
```

Expected: FAIL because the scene does not exist.

- [ ] **Step 3: Build the focused scene and guarded controller**

Create `between_fight_choice.tscn`:

```ini
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/ui/between_fight_choice.gd" id="1"]

[node name="BetweenFightChoice" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
script = ExtResource("1")

[node name="Background" type="ColorRect" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
color = Color(0.12, 0.09, 0.04, 1)

[node name="Margin" type="MarginContainer" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
offset_left = 80.0
offset_top = 60.0
offset_right = -80.0
offset_bottom = -60.0

[node name="VBox" type="VBoxContainer" parent="Margin"]
layout_mode = 2
theme_override_constants/separation = 24

[node name="Title" type="Label" parent="Margin/VBox"]
layout_mode = 2
text = "Choose What You Carry Forward"
horizontal_alignment = 1

[node name="RunStatus" type="Label" parent="Margin/VBox"]
layout_mode = 2
horizontal_alignment = 1

[node name="CardOffers" type="HBoxContainer" parent="Margin/VBox"]
layout_mode = 2
size_flags_vertical = 3
alignment = 1
theme_override_constants/separation = 24

[node name="RecoverButton" type="Button" parent="Margin/VBox"]
custom_minimum_size = Vector2(0, 72)
layout_mode = 2
text = "Recover 12 Health and 4 Sanity"
```

Create `between_fight_choice.gd`:

```gdscript
extends Control
class_name BetweenFightChoiceController

@onready var run_status: Label = $Margin/VBox/RunStatus
@onready var card_offers: HBoxContainer = $Margin/VBox/CardOffers
@onready var recover_button: Button = $Margin/VBox/RecoverButton
var choice_submitted := false

func _ready() -> void:
	var offers := GameManager.get_pending_run_rewards()
	if not GameManager.has_pending_run_reward():
		GLog.error("Between-fight choice opened without a pending reward")
		SceneManager.load_scene_by_name("main_menu")
		return
	run_status.text = GameManager.get_run_progress_text()
	for card in offers:
		var button := Button.new()
		button.custom_minimum_size = Vector2(240, 180)
		button.text = "%s\n%s" % [card.card_name, card.description]
		button.pressed.connect(_on_card_selected.bind(card))
		card_offers.add_child(button)
	recover_button.pressed.connect(_on_recover_selected)

func _on_card_selected(card: CardData) -> void:
	if choice_submitted:
		return
	choice_submitted = GameManager.choose_run_card(card)
	_set_controls_disabled(choice_submitted)

func _on_recover_selected() -> void:
	if choice_submitted:
		return
	choice_submitted = GameManager.choose_run_recovery()
	_set_controls_disabled(choice_submitted)

func _set_controls_disabled(disabled: bool) -> void:
	recover_button.disabled = disabled
	for child in card_offers.get_children():
		if child is Button:
			child.disabled = disabled
```

Add these GameManager methods:

```gdscript
func has_pending_run_reward() -> bool:
	return run_session != null and run_session.state == RunSession.State.REWARD_PENDING

func get_run_progress_text() -> String:
	return "Fight %d of 3 complete" % (run_session.fight_index + 1) if run_session else ""

func choose_run_card(card: CardData) -> bool:
	if not has_pending_run_reward() or not run_session.apply_card_reward(card):
		return false
	return _prepare_and_start_next_run_duel()

func choose_run_recovery() -> bool:
	if not has_pending_run_reward() or not run_session.apply_recovery():
		return false
	return _prepare_and_start_next_run_duel()

func _prepare_and_start_next_run_duel() -> bool:
	pending_duel_config = run_session.prepare_current_duel()
	if not pending_duel_config or not pending_duel_config.is_valid():
		run_session.record_defeat(RunSession.EndReason.INVALID_STATE)
		last_run_summary = run_session.get_summary()
		end_current_run(false)
		SceneManager.load_scene_by_name("game_over")
		return false
	return start_prepared_duel()
```

Add `"between_fight_choice": "res://scenes/ui/between_fight_choice.tscn"` to `SceneManager.SCENE_PATHS`.

- [ ] **Step 4: Run the scene contract and headless scene boot**

Run:

```bash
rtk test /opt/homebrew/bin/godot --headless --log-file /tmp/diggings-gdunit.log --path packages/game/src -s addons/gdUnit4/bin/GdUnitCmdTool.gd -a test/unit/run/test_curated_run_integration.gd --ignoreHeadlessMode
rtk proxy env HOME=/tmp/diggings-home /opt/homebrew/bin/godot --headless --log-file /tmp/diggings-between-fight.log --path packages/game/src --scene res://scenes/ui/between_fight_choice.tscn --quit-after 10
```

Expected: the contract passes; direct scene boot exits safely to main menu and logs the missing pending reward once without a parse error.

- [ ] **Step 5: Commit the between-fight UI**

```bash
rtk git add packages/game/src/scripts/ui/between_fight_choice.gd packages/game/src/scenes/ui/between_fight_choice.tscn packages/game/src/scripts/autoloads/scene_manager.gd packages/game/src/scripts/autoloads/game_manager.gd packages/game/src/test/unit/run/test_curated_run_integration.gd
rtk git commit -m "feat: add between-fight card or recovery choice"
```

---

### Task 8: Victory and Defeat Summaries

**Files:**
- Create: `packages/game/src/scripts/core/intents/game_over_intent.gd`
- Create: `packages/game/src/test/unit/run/test_run_intents.gd`
- Modify: `packages/game/src/scripts/core/intents/run_complete_intent.gd`
- Modify: `packages/game/src/scripts/ui/run_complete_scene.gd`
- Modify: `packages/game/src/scenes/ui/run_complete.tscn`
- Modify: `packages/game/src/scripts/ui/game_over.gd`
- Modify: `packages/game/src/scenes/ui/game_over.tscn`
- Modify: `packages/game/src/scripts/autoloads/game_manager.gd`

**Interfaces:**
- Consumes: `RunSession.get_summary()` and `SceneManager.get_pending_intent()`.
- Produces: `RunCompleteIntent.from_summary(summary)` and `GameOverIntent.reason`.

- [ ] **Step 1: Write failing intent tests**

Create:

```gdscript
extends GdUnitTestSuite

func test_run_complete_intent_preserves_summary() -> void:
	var summary := {
		"character_class": "Bushranger",
		"seed": 12345,
		"fights_won": 3,
		"final_health": 22,
		"final_sanity": 8,
		"cards_added": ["Quick Shot"],
		"victory": true
	}
	var intent := RunCompleteIntent.from_summary(summary)
	assert_str(intent.character_class).is_equal("Bushranger")
	assert_int(intent.seed).is_equal(12345)
	assert_array(intent.cards_added).is_equal(["Quick Shot"])

func test_game_over_intent_identifies_sanity_defeat() -> void:
	var intent := GameOverIntent.new(RunSession.EndReason.SANITY)
	assert_int(intent.reason).is_equal(RunSession.EndReason.SANITY)
```

- [ ] **Step 2: Run the intent tests and confirm red**

Run:

```bash
rtk test /opt/homebrew/bin/godot --headless --log-file /tmp/diggings-gdunit.log --path packages/game/src -s addons/gdUnit4/bin/GdUnitCmdTool.gd -a test/unit/run/test_run_intents.gd --ignoreHeadlessMode
```

Expected: FAIL because the factory and `GameOverIntent` do not exist.

- [ ] **Step 3: Implement final intent data and render it**

`RunCompleteIntent` gains these typed summary fields and factory:

```gdscript
var character_class: String = "Unknown"
var seed: int = 0
var final_health: int = 0
var final_sanity: int = 0
var cards_added: Array[String] = []

static func from_summary(summary: Dictionary) -> RunCompleteIntent:
	var intent := RunCompleteIntent.new(true, "main_menu")
	intent.character_class = summary.get("character_class", "Unknown")
	intent.seed = summary.get("seed", 0)
	intent.battles_won = summary.get("fights_won", 0)
	intent.final_health = summary.get("final_health", 0)
	intent.final_sanity = summary.get("final_sanity", 0)
	intent.cards_added = summary.get("cards_added", []).duplicate()
	return intent
```

Create `GameOverIntent`:

```gdscript
class_name GameOverIntent
extends SceneIntent

var reason: RunSession.EndReason = RunSession.EndReason.HEALTH

func _init(p_reason: RunSession.EndReason = RunSession.EndReason.HEALTH) -> void:
	super("main_menu")
	reason = p_reason

func get_intent_type() -> String:
	return "GameOverIntent"
```

Update `GameManager.complete_curated_duel()` to call `SceneManager.load_scene_by_name_with_intent()` with `GameOverIntent.new(reason)` on defeat and `RunCompleteIntent.from_summary(last_run_summary)` on completion, after the existing `end_current_run(false)` or `end_current_run(true)` call has closed the deck and seed lifecycle. Update the invalid-config branch in `_prepare_and_start_next_run_duel()` to load Game Over with `GameOverIntent.new(RunSession.EndReason.INVALID_STATE)` as well.

Fix the `run_complete.tscn` script path from `res://src/scripts/ui/run_complete_scene.gd` to `res://scripts/ui/run_complete_scene.gd`. Under its `VBoxContainer`, replace `MessageLabel` with labels named `ClassLabel`, `SeedLabel`, `FightsLabel`, `VitalsLabel`, and `CardsLabel`. Use this rendering method in `run_complete_scene.gd`:

```gdscript
func _ready() -> void:
	var intent := SceneManager.get_pending_intent() as RunCompleteIntent
	if not intent:
		GLog.error("Run Complete opened without RunCompleteIntent")
		SceneManager.load_scene_by_name("main_menu")
		return
	$CanvasLayer/CenterContainer/VBoxContainer/ClassLabel.text = "Class: %s" % intent.character_class
	$CanvasLayer/CenterContainer/VBoxContainer/SeedLabel.text = "Seed: %d" % intent.seed
	$CanvasLayer/CenterContainer/VBoxContainer/FightsLabel.text = "Fights won: %d/3" % intent.battles_won
	$CanvasLayer/CenterContainer/VBoxContainer/VitalsLabel.text = "Health: %d | Sanity: %d" % [intent.final_health, intent.final_sanity]
	$CanvasLayer/CenterContainer/VBoxContainer/CardsLabel.text = "Cards added: %s" % (", ".join(intent.cards_added) if not intent.cards_added.is_empty() else "None")
	$CanvasLayer/CenterContainer/VBoxContainer/ReturnButton.pressed.connect(_return_to_main_menu)

func _return_to_main_menu() -> void:
	GameManager.reset_curated_run()
	SceneManager.load_scene_by_name("main_menu")
```

Add `ReasonLabel` under `GameOver/MainContainer` and render the intent in `game_over.gd`:

```gdscript
func _ready() -> void:
	var intent := SceneManager.get_pending_intent() as GameOverIntent
	if not intent:
		GLog.error("Game Over opened without GameOverIntent")
		SceneManager.load_scene_by_name("main_menu")
		return
	match intent.reason:
		RunSession.EndReason.HEALTH:
			$MainContainer/ReasonLabel.text = "Your body gave out."
		RunSession.EndReason.SANITY:
			$MainContainer/ReasonLabel.text = "Your mind broke."
		_:
			$MainContainer/ReasonLabel.text = "The run state became invalid."
	$MainContainer/MainMenuButton.pressed.connect(_return_to_main_menu)

func _return_to_main_menu() -> void:
	GameManager.reset_curated_run()
	SceneManager.load_scene_by_name("main_menu")
```

- [ ] **Step 4: Run intent tests and boot both scenes**

Run:

```bash
rtk test /opt/homebrew/bin/godot --headless --log-file /tmp/diggings-gdunit.log --path packages/game/src -s addons/gdUnit4/bin/GdUnitCmdTool.gd -a test/unit/run/test_run_intents.gd --ignoreHeadlessMode
rtk proxy env HOME=/tmp/diggings-home /opt/homebrew/bin/godot --headless --log-file /tmp/diggings-run-complete.log --path packages/game/src --scene res://scenes/ui/run_complete.tscn --quit-after 10
rtk proxy env HOME=/tmp/diggings-home /opt/homebrew/bin/godot --headless --log-file /tmp/diggings-game-over.log --path packages/game/src --scene res://scenes/ui/game_over.tscn --quit-after 10
```

Expected: tests pass; both scenes parse and boot without invalid script paths.

- [ ] **Step 5: Commit summary screens**

```bash
rtk git add packages/game/src/scripts/core/intents/game_over_intent.gd packages/game/src/test/unit/run/test_run_intents.gd packages/game/src/scripts/core/intents/run_complete_intent.gd packages/game/src/scripts/ui/run_complete_scene.gd packages/game/src/scenes/ui/run_complete.tscn packages/game/src/scripts/ui/game_over.gd packages/game/src/scenes/ui/game_over.tscn packages/game/src/scripts/autoloads/game_manager.gd
rtk git commit -m "feat: show curated run victory and defeat summaries"
```

---

### Task 9: Deterministic Combat Randomness on the Curated Path

**Files:**
- Create: `packages/game/src/test/unit/cards/test_seeded_card_pile.gd`
- Modify: `packages/game/src/scripts/data/card_pile.gd:13-25,168-205`
- Modify: `packages/game/src/scripts/data/duel_state.gd:35-75`
- Modify: `packages/game/src/scripts/data/enemy_card_manager.gd:10-40`
- Modify: `packages/game/src/scripts/combat/duel_flow_controller.gd`
- Modify: `packages/game/src/scripts/combat/enemy_ai_controller.gd:12-25,175-190`
- Modify: `packages/game/src/scripts/managers/duel_manager.gd:35-60`
- Modify: `packages/game/src/scripts/handlers/core/handler_base.gd:70-82`
- Modify: `packages/game/src/scripts/handlers/types/damage_handler.gd:25-70`
- Modify: `packages/game/src/scripts/handlers/types/resource_handler.gd:20-35`

**Interfaces:**
- Consumes: `SeedManager.combat_rng`, `get_combat_random_int`, and `get_combat_random_float`.
- Produces: `CardPile.set_rng(rng)`, `DuelState.set_combat_rng(rng)`, and deterministic AI/handler choices.

- [ ] **Step 1: Write failing seeded pile tests**

Create:

```gdscript
extends GdUnitTestSuite

func _pile(seed_value: int) -> CardPile:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var pile := CardPile.new("deck")
	pile.set_rng(rng)
	for name in ["A", "B", "C", "D", "E"]:
		var data := CardData.new()
		data.card_name = name
		pile.add_card(CardInstance.new(data))
	return pile

func _names(pile: CardPile) -> Array[String]:
	var result: Array[String] = []
	for card in pile.cards:
		result.append(card.card_data.card_name)
	return result

func test_same_seed_shuffles_and_draws_identically() -> void:
	var first := _pile(9090)
	var second := _pile(9090)
	first.shuffle()
	second.shuffle()
	assert_array(_names(first)).is_equal(_names(second))
	assert_str(first.draw_random().card_data.card_name).is_equal(second.draw_random().card_data.card_name)
```

- [ ] **Step 2: Run the focused test and confirm red**

Run:

```bash
rtk test /opt/homebrew/bin/godot --headless --log-file /tmp/diggings-gdunit.log --path packages/game/src -s addons/gdUnit4/bin/GdUnitCmdTool.gd -a test/unit/cards/test_seeded_card_pile.gd --ignoreHeadlessMode
```

Expected: FAIL because `CardPile.set_rng()` is undefined.

- [ ] **Step 3: Thread the combat RNG through piles and AI, then replace reachable global randomness**

Add to `CardPile`:

```gdscript
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

func set_rng(rng: RandomNumberGenerator) -> void:
	_rng = rng
```

Use `_rng.randi_range(0, cards.size() - 1)` in `draw_random()` and `_rng.randi_range(0, i)` in `shuffle()`.

Add `DuelState.set_combat_rng(rng)` to apply the same RNG to hand, deck, discard, removed, battlefield, and `enemy_data.card_manager`. Add `EnemyCardManager.set_rng(rng)` for its three piles. Call `duel_state.set_combat_rng(SeedManager.combat_rng)` before the first shuffle in `DuelFlowController`.

Change `EnemyAIController._init(state, rng)` to retain the RNG and use it for the Cunning fallback. Construct it in `DuelManager` with `SeedManager.combat_rng`.

On the curated combat path, replace:

```gdscript
randf()
randi()
randi_range(from_value, to_value)
```

with the corresponding `SeedManager.get_combat_random_float()` or `SeedManager.get_combat_random_int(from_value, to_value)` in `handler_base.gd`, `damage_handler.gd`, and `resource_handler.gd`. Random target selection uses `get_combat_random_int(0, secondary_targets.size() - 1)`.

Run this audit and inspect every remaining match:

```bash
rtk proxy rg -n "randi\(|randi_range\(|randf\(|\.shuffle\(" packages/game/src/scripts --glob '*.gd'
```

Remaining matches are allowed only for seed creation, non-gameplay identifiers, Quick Duel-only reward presentation, or modules unreachable from the curated run. Add a one-line reason beside each allowed remaining match.

- [ ] **Step 4: Run seeded pile, run, and card tests**

Run:

```bash
rtk test /opt/homebrew/bin/godot --headless --log-file /tmp/diggings-gdunit.log --path packages/game/src -s addons/gdUnit4/bin/GdUnitCmdTool.gd -a test/unit/cards/test_seeded_card_pile.gd -a test/unit/run/ -a test/unit/cards/ --ignoreHeadlessMode
```

Expected: all selected tests pass with 0 failures.

- [ ] **Step 5: Commit deterministic combat changes**

```bash
rtk git add packages/game/src/test/unit/cards/test_seeded_card_pile.gd packages/game/src/scripts/data/card_pile.gd packages/game/src/scripts/data/duel_state.gd packages/game/src/scripts/data/enemy_card_manager.gd packages/game/src/scripts/combat/duel_flow_controller.gd packages/game/src/scripts/combat/enemy_ai_controller.gd packages/game/src/scripts/managers/duel_manager.gd packages/game/src/scripts/handlers/core/handler_base.gd packages/game/src/scripts/handlers/types/damage_handler.gd packages/game/src/scripts/handlers/types/resource_handler.gd
rtk git commit -m "feat: make curated combat randomness reproducible"
```

---

### Task 10: End-to-End Run Test, Documentation, and Final Verification

**Files:**
- Modify: `packages/game/src/test/unit/run/test_curated_run_integration.gd`
- Modify: `README.md`
- Modify: `packages/game/README.md`
- Modify: `docs/game/summary.md`

**Interfaces:**
- Consumes: the complete curated run interface and scene routing.
- Produces: regression proof, current project status, and a reproducible manual verification script.

- [ ] **Step 1: Add a failing complete-run regression test**

Extend the integration test with a state-driven run that does not require clicking combat UI:

```gdscript
func test_complete_run_persists_choices_and_builds_summary() -> void:
	GameManager.reset_curated_run()
	SeedManager.set_master_seed(515151)
	var character := load("res://data/characters/bushranger.tres") as CharacterClass
	assert_bool(GameManager.begin_curated_run(character, 515151)).is_true()
	var first_player := GameManager.run_session.player_snapshot.to_player_data()
	first_player.stats.current_health = 38
	first_player.stats.current_sanity = 14
	first_player.stats.current_gold = 19
	first_player.custom_resources[GameEnums.CustomResourceType.AMMO] = 2
	first_player.run_corruption = 4
	first_player.corruption_triggered_tiers = {Stats.SanityTier.SHAKEN: true}
	var curio := load("res://data/curios/common/lucky_nugget.tres")
	assert_bool(CurioManager.add_curio(curio)).is_true()
	GameManager.run_session.record_victory(first_player)
	var offered := GameManager.get_pending_run_rewards()
	assert_bool(GameManager.run_session.apply_card_reward(offered[0])).is_true()
	var second_config := GameManager.run_session.prepare_current_duel()
	var persisted := second_config.get_modifier("player_data") as PlayerData
	assert_int(persisted.stats.current_health).is_equal(38)
	assert_int(persisted.stats.current_sanity).is_equal(14)
	assert_int(persisted.stats.current_gold).is_equal(19)
	assert_int(persisted.custom_resources[GameEnums.CustomResourceType.AMMO]).is_equal(2)
	assert_int(persisted.run_corruption).is_equal(4)
	assert_bool(persisted.corruption_triggered_tiers[Stats.SanityTier.SHAKEN]).is_true()
	assert_bool(CurioManager.has_curio(curio.curio_name)).is_true()
	var second_player := GameManager.run_session.player_snapshot.to_player_data()
	second_player.stats.current_health = 30
	second_player.stats.current_sanity = 10
	GameManager.run_session.record_victory(second_player)
	assert_bool(GameManager.run_session.apply_recovery()).is_true()
	GameManager.run_session.prepare_current_duel()
	GameManager.run_session.record_victory(GameManager.run_session.player_snapshot.to_player_data())
	var summary := GameManager.run_session.get_summary()
	assert_bool(summary.victory).is_true()
	assert_int(summary.fights_won).is_equal(3)
	assert_int(summary.cards_added.size()).is_equal(1)
	GameManager.reset_curated_run()
```

Also add a second test that runs the same seed/class/decisions twice and compares the two offer-path arrays and three enemy names exactly.

- [ ] **Step 2: Run the integration test before final fixes**

Run:

```bash
rtk test /opt/homebrew/bin/godot --headless --log-file /tmp/diggings-gdunit.log --path packages/game/src -s addons/gdUnit4/bin/GdUnitCmdTool.gd -a test/unit/run/test_curated_run_integration.gd --ignoreHeadlessMode
```

Expected: FAIL if any lifecycle, persistence, summary, or determinism seam remains incomplete. Fix only the failing seam in its owning module, then rerun until green.

- [ ] **Step 3: Update project status documentation**

Update all three docs with these facts:

- Active milestone: deterministic curated three-fight mini-run.
- New Game flow: static class selection, three fights, two card-or-recovery choices, summary.
- Quick Duel: single-fight developer sandbox.
- Frozen: Atlas, content-kit, generated narrative, narrative runtime, maps, shops, and saving.
- Canonical design: `docs/superpowers/specs/2026-07-12-core-game-recovery-design.md`.

Remove the root README instruction that presents Atlas as a normal Quick Start path; move it under a clearly labeled `Frozen tooling` note. Update `docs/game/summary.md` so the current loop no longer claims generic encounter progression or completed systems that are not in the curated run.

- [ ] **Step 4: Run the complete automated verification floor**

Run:

```bash
rtk proxy env HOME=/tmp/diggings-home /opt/homebrew/bin/godot --headless --log-file /tmp/diggings-import-final.log --path packages/game/src --editor --quit
rtk test /opt/homebrew/bin/godot --headless --log-file /tmp/diggings-gdunit-final.log --path packages/game/src -s addons/gdUnit4/bin/GdUnitCmdTool.gd -a test/unit/ --ignoreHeadlessMode
rtk log /tmp/diggings-gdunit-final.log
rtk proxy env HOME=/tmp/diggings-home /opt/homebrew/bin/godot --headless --log-file /tmp/diggings-main-final.log --path packages/game/src --quit-after 20
rtk log /tmp/diggings-main-final.log
rtk proxy rg -n "DuelSequenceState|DuelSequenceHandler|duel_sequence_state|CharacterGenerator" packages/game/src --glob '*.gd' --glob '*.tscn' --glob 'project.godot'
rtk git diff --check
```

Expected:

- Godot import exits 0 with no project parse errors.
- GdUnit reports all tests passing, including the original 33.
- Main scene boots without missing character-generation files or invalid run-complete script paths.
- The stale-symbol audit returns no production references; test or archived documentation references are outside this command's scope.
- `git diff --check` prints nothing.

- [ ] **Step 5: Perform native visual and gameplay verification**

Run the game from `packages/game/src/project.godot` and record evidence for:

1. All five static class cards fit and are readable at 1920×1080.
2. New Game enters Claim Jumper without showing Quick Duel configuration.
3. Fight-one victory shows three distinct legal cards plus recovery.
4. Selecting a card disables all choices immediately and adds exactly one deck card.
5. Fight-two victory followed by recovery restores 12 health and 4 sanity without exceeding maxima.
6. Fight three is Whispering Cultist and ends at the summary.
7. Health defeat and sanity defeat show different messages.
8. A repeated seed with the same class and decisions shows identical offers.
9. A full playthrough lasts 15–20 minutes; if it does not, change only the three approved enemy health values and rerun the timed playtest.

- [ ] **Step 6: Self-review the complete diff**

Run:

```bash
rtk git status --short
rtk git diff --stat
rtk git diff
```

Review the entire diff for stale generated-character types, direct scene access to `RunSession` fields outside the read-only UI display, global random calls on the curated path, wrong `res://src/` paths, hardcoded Bushranger reward pools, duplicated reward application, and unrelated changes.

- [ ] **Step 7: Commit docs and final integration coverage**

```bash
rtk git add packages/game/src/test/unit/run/test_curated_run_integration.gd README.md packages/game/README.md docs/game/summary.md
rtk git commit -m "docs: make the curated mini-run the active milestone"
```

- [ ] **Step 8: Record the final repository state**

Run:

```bash
rtk git status --short --branch
rtk git log --oneline -10
```

Expected: only the user's pre-existing untracked `packages/game/resources/narrative/township/` remains; the implementation is split across the task commits above.
