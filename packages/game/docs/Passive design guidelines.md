# Class Passives Plan (EventBus-driven) — 11 Jan 2026

## Scope
Plan class passive abilities for the following classes, using **existing systems** discovered in this chat:
- Classes: **bushranger, prospector, tracker, publican, preacher**
- Custom resources (from `GameEnums.CustomResourceType`): **AMMO, FAITH, FEVER, SCENT, BREW**
- Confirmed mechanic: **Exhaust** exists
- Communication layer: **EventBus** is the sanctioned integration point (per project instructions)

This document proposes:
1. Findings from `EventBus` (available signals + current payload shapes)
2. Recommended passive architecture (Godot 4.5 + SOLID)
3. A concrete passive set per class, designed to be **not overpowered** and implementable using existing signals/resources
4. A short backlog of EventBus payload upgrades (optional, but strongly recommended)

---

## 1) Findings: EventBus signals available (relevant to passives)

Source: `src/scripts/autoloads/event_bus.gd`

### Combat flow
- `duel_started(enemy_data: Resource)`
- `duel_ended(victory: bool)`
- `turn_started(turn_number: int, is_player_turn: bool)`
- `turn_ended(turn_number: int)`
- `phase_changed(phase: String)`

### Cards / deck lifecycle
- `card_played(card: Node)`
- `card_drawn(card: Node)`
- `card_discarded(card: Node)`
- `card_exhausted(card: Node)`
- `card_upgraded(card: Node)`
- `card_created(card: Node)`
- `card_destroyed(card: Node)`
- `hand_changed(hand: Array)`
- `deck_shuffled()`

### Combat resolution
- `damage_dealt(target: Node, amount: int, source: Node)`
- `damage_taken(target: Object, amount: int)`
- `damage_blocked(target: Node, amount: int)`
- `healing_received(target: Node, amount: int)`
- `status_applied(target: Node, status: String, stacks: int)`
- `status_removed(target: Node, status: String)`

### Player stats/resources
- `energy_changed(current: int, max: int)`
- `gold_changed(amount: int)`
- `corruption_changed(amount: int)`
- `sanity_changed(amount: int)`
- `health_changed(current: int, max: int)`

### Generic custom resource signals (Ammo/Faith/Fever/Scent/Brew/etc.)
- `resource_gained(player: Object, resource_name: String, amount: int)`
- `resource_spent(player: Object, resource_name: String, amount: int)`
- `resource_changed(player: Object, resource_name: String, current: int, max_val: int)`

### Fortune / gambling support
- `gambling_modifier_query(player_data: Object, context: Dictionary)`

### Enemies
- `enemy_intent_revealed(intent: String)`
- `enemy_action_performed(action: String)`
- `enemy_defeated(enemy: Node)`
- `enemy_spawned(enemy: Node)`

---

## 2) Important mismatch found (needs a plan)
Current `ClassPassiveHandler` (shown earlier in chat) uses:
- `resource_gained(player_data, resource_type: GameEnums.CustomResourceType, amount: int)`

But `EventBus` defines:
- `resource_gained(player: Object, resource_name: String, amount: int)`

### Recommendation
Pick **one canonical representation** for custom resources in signals:

**Option A (lowest friction): keep EventBus as-is (String)**
- Passives match `resource_name: String`
- Define constants (e.g., `"FAITH"`, `"AMMO"`) or a mapper utility (Enum ↔ String) to avoid typos.

**Option B (more type-safe): change EventBus to use `CustomResourceType`**
- Requires updating emitters + subscribers
- Better long-term, but touches more files.

**Plan:** start with Option A for minimal churn, then migrate later if desired.

---

## 3) Recommended implementation approach (Godot 4.5 + SOLID)

### Goal
Avoid a single “mega handler” while keeping EventBus usage consistent.

### Pattern
- `ClassPassiveHandler` becomes an orchestrator:
  - Detect class
  - Instantiate passive objects
  - Call `setup()` / `cleanup()` on each
- Each passive is a small `RefCounted` object (SRP) subscribing to exactly the signals it needs.
- Use `EventBus.connect_safe()` and disconnect on cleanup.
- Each passive owns its own throttle state (once/turn, once/combat, etc.).

### Minimal interface (ISP)
- `setup() -> void`
- `cleanup() -> void`

### Dependency injection (DIP)
Passives receive:
- `duel_state: DuelState` (or a minimal interface later)
- rely on EventBus only for notifications

---

## 4) Passive design rules (balance)
- Prefer **once per turn** or **once per combat** triggers.
- Prefer **flat bonuses** or **small %**.
- Tie power to constraints:
  - resource thresholds
  - “first time each turn”
  - exhaust / shuffle / damage taken triggers with caps

---

## 5) Proposed passives by class (built on existing EventBus signals)

### 5.1 Bushranger (AMMO, aggression, “hit-and-run”)
**Passive A — Quick Draw**
- Trigger: `duel_started`
- Effect: draw +1 card, then discard 1 (net 0; improves opening consistency)
- Cap: once per combat
- Uses: `card_drawn`, `card_discarded` indirectly via existing systems; implementation depends on your draw/discard APIs.

**Passive B — Suppressive Fire**
- Trigger: `resource_spent(player, resource_name, amount)` where `resource_name == "AMMO"`
- Effect: first time per player turn you spend Ammo, gain +1 Defense
- Cap: once per turn (track via `turn_started`)

**Passive C — Close Call**
- Trigger: `damage_taken(target, amount)` for the player
- Effect: if this is the **first** time you take damage this turn, gain +1 AMMO (or +1 Defense next turn if AMMO generation is too strong)
- Cap: once per turn

Notes: these are modest tempo tools that don’t multiply damage.

---

### 5.2 Prospector (GOLD, deck churn, “find value”)
**Passive A — Pan for Gold**
- Trigger: `deck_shuffled()`
- Effect: gain +5 gold
- Cap: once per combat (set on `duel_started`; consume on first shuffle)
- Why safe: rewards long fights / deck cycling but capped.

**Passive B — Stake a Claim**
- Trigger: `duel_started`
- Effect: create a “Nugget” card in discard: `0-cost, Exhaust, gain 5 gold`
- Cap: once per combat (card exhaust prevents infinite reuse)

**Passive C — Hard Bargain**
- Trigger: `gold_changed(amount)`
- Effect: when gold increases, gain +1 Defense
- Cap: once per turn (reset on `turn_started`)

Notes: strong identity without snowballing mid-combat.

---

### 5.3 Tracker (SCENT, target focus, consistency)
**Passive A — Read the Trail**
- Trigger: `turn_started(turn_number, is_player_turn)` (player turns only)
- Effect: “Scry 1” equivalent using existing systems (peek top card, optionally discard)
- Cap: every player turn, but low magnitude

**Passive B — Mark Prey**
- Trigger: `damage_dealt(target, amount, source)` where `source` is the player
- Effect: first hit each player turn applies `status_applied(target, "Marked", 1)` (or a lightweight status name you already support)
- Cap: once per turn per combatant (simpler: once per player turn total)

**Passive C — Scent Harvest**
- Trigger: `enemy_defeated(enemy)`
- Effect: gain +1 SCENT (or +1 SCENT only if enemy had "Marked")
- Cap: per kill (already naturally bounded)

Notes: requires “Marked” to exist; otherwise use an existing debuff name.

---

### 5.4 Publican (BREW, sustain, controlled buffs)
**Passive A — Round on the House**
- Trigger: `healing_received(target, amount)` where `target` is the player
- Effect: first time you heal each combat, gain +1 BREW
- Cap: once per combat

**Passive B — Liquid Courage**
- Trigger: `resource_spent(player, resource_name, amount)` where `resource_name == "BREW"`
- Effect: first time per turn you spend BREW, gain +1 Defense (or +5% gambling modifier via query context)
- Cap: once per turn

**Passive C — Responsible Pour (tradeoff)**
- Trigger: `turn_ended(turn_number)`
- Effect: if you spent 0 BREW this turn, gain +1 BREW; if you spent ≥1 BREW, nothing
- Cap: inherently once/turn

Notes: promotes BREW economy without raw healing inflation.

---

### 5.5 Preacher (FAITH, gambling synergy, moral tradeoffs)
You already have (from earlier chat):
- Fervent Faith: gain Defense when gaining Faith
- Temptation: trigger choice at max Faith
- Holy Conviction: improve Fortune success chance at Faith threshold

Adjustments to align with EventBus:
- Use `resource_name == "FAITH"` instead of enum checks (until migration).

**Additional Passive A — Absolution**
- Trigger: `status_applied(target, status, stacks)` on the player
- Effect: once per combat, if status is in a denylist (e.g., "Curse", "Hex", etc.), remove it and spend 2 Faith
- Cap: once per combat; requires Faith cost

**Additional Passive B — Righteous Fury**
- Trigger: `damage_taken(target, amount)` on the player
- Effect: first time per turn you take damage, gain +1 Faith
- Cap: once per turn

Notes: keeps Preacher reactive and resource-gated.

---

## 6) Payload upgrade backlog (optional but recommended)
These are “nice to have” changes to make passives cleaner and reduce coupling to Nodes:

1. **Add player context to card signals**
   - Current: `card_played(card: Node)`
   - Better: `card_played(player: Object, card: Node, tags: Array[StringName])`
   - Allows “first Attack each turn” style passives safely.

2. **Make `deck_shuffled` include which deck**
   - Current: `deck_shuffled()`
   - Better: `deck_shuffled(player: Object)`
   - Enables per-actor throttles.

3. **Standardize resources to enum OR constants**
   - Either migrate to `CustomResourceType` in signals,
   - Or define canonical string constants in one place (avoid `"FAITH"` typos).

---

## 7) Implementation order (safe, incremental)
1. Pick resource naming strategy (ENUM).
2. Create `PassiveBase` helper + refactor `ClassPassiveHandler` to register passive objects.
3. Implement 1–2 passives per class using only existing signals:
   - Prospector: Pan for Gold (deck_shuffled), Hard Bargain (gold_changed)
   - Preacher: update current ones to match `resource_name: String`
4. Add missing payload improvements only if passive designs require them.

---