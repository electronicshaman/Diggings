# Status Effects Specification

This document defines the mechanical behavior of all status effects in the game.

## General Rules

- All status effects use stack-based mechanics
- Effects are processed via the HandlerRegistry system
- Status effects can target players or enemies

---

## Debuffs (Negative Effects)

### Poison
**Type:** Damage over time
**Target:** Enemy or Player

**Mechanics:**
- Triggers at **Turn Start** of the afflicted entity
- Deals **1 damage per stack**
- After dealing damage, **stacks reduce by 1**
- Stacks accumulate when reapplied (10 poison + 5 poison = 15 poison)

**Example:** 10 Poison stacks → deals 10 damage → becomes 9 stacks → next turn deals 9 → becomes 8, etc.

**Ignores:** Defense/Block (poison bypasses block)

---

### Burn
**Type:** Delayed burst damage
**Target:** Enemy or Player

**Mechanics:**
- Triggers at **Turn End** of the afflicted entity
- Damage per stack is **defined by the source card** (stored with the effect)
- After dealing damage, **all stacks expire**
- Stacks accumulate when reapplied; damage per stack uses the highest value applied

**Example:** Card applies 5 Burn (2 dmg/stack) → at turn end deals 10 damage → burn removed

**Ignores:** Defense/Block (burn bypasses block)

**Key Difference from Poison:** Burn is immediate burst damage that clears; Poison is sustained damage that lingers

---

### Curse
**Type:** Deck pollution
**Target:** Player (primarily)

**Mechanics:**
- Applies **Curse cards directly to hand** (immediate impact)
- **Permanent until cured** - Curse cards persist in deck until removed
- Each stack = 1 Curse card added
- Individual Curse cards define their own behavior:
  - Some are **unplayable dead cards** (hand clog)
  - Some can be **exhausted for a penalty** (sanity/health cost)
  - Some **auto-trigger** negative effects when drawn

**Design Note:** Different Curse card types provide variety (e.g., "Whispers" deals sanity damage when drawn, "Paralysis" is unplayable, "Blood Price" can be exhausted for 5 health)

**Removal:** Requires specific cards/effects that remove Curse cards from deck

---

### Wounded
**Type:** Damage amplification (incoming)
**Target:** Enemy or Player

**Mechanics:**
- Target takes **50% more damage** from attacks
- **Stacks = duration** (reduce by 1 at turn end)
- Multiple applications extend duration (3 Wounded + 2 Wounded = 5 turns)
- Damage calculation: `final_damage = base_damage * 1.5` (rounded down)

**Example:** 10 damage attack vs Wounded target → 15 damage

**Interaction:** Applied before defense/block calculation

---

### Weak
**Type:** Damage reduction (outgoing)
**Target:** Enemy or Player

**Mechanics:**
- Target deals **25% less damage** with attacks
- **Stacks = duration** (reduce by 1 at turn end)
- Multiple applications extend duration
- Damage calculation: `final_damage = base_damage * 0.75` (rounded down)

**Example:** Enemy with 10 base damage while Weak → deals 7 damage

**Counterpart:** Weak reduces damage dealt; Wounded increases damage taken

---

### Rattled
**Type:** Defense/Block reduction
**Target:** Enemy or Player

**Mechanics:**
- Target gains **25% less block** from cards/effects
- **Stacks = duration** (reduce by 1 at turn end)
- Multiple applications extend duration
- Block calculation: `final_block = base_block * 0.75` (rounded down)

**Example:** Card grants 10 block while Rattled → gain 7 block

**Counterpart:** Rattled is the defensive equivalent of Weak

---

### Dread
**Type:** Sanity damage over time
**Target:** Enemy or Player

**Mechanics:**
- Triggers at **Turn Start** of the afflicted entity
- Deals **1 sanity damage per stack**
- After dealing damage, **stacks reduce by 1**
- Stacks accumulate when reapplied

**Example:** 8 Dread → deals 8 sanity damage → becomes 7 Dread → next turn deals 7 → becomes 6, etc.

**Counterpart:** Dread is to Sanity as Poison is to Health. Resolve is its positive counterpart.

**Thematic:** Represents creeping psychological horror - the longer you're exposed, the deeper it burrows.

---

### Thorns
**Type:** Damage reflection
**Target:** Player or Enemy

**Mechanics:**
- When attacked, **reflect 5% of damage taken per stack** back to attacker
- **Capped at 100%** reflection (20 stacks = max effectiveness)
- **Stacks = duration** (reduce by 1 at turn end)
- Reflection occurs after block is applied (reflects actual damage taken)
- Reflection calculation: `reflected = min(damage_taken * (stacks * 0.05), damage_taken)`

**Example:** Take 20 damage with 10 Thorns → reflect 50% = 10 damage back to attacker

**Design Note:** Thorns encourages blocking builds and punishes multi-hit attacks

---

### Drain
**Type:** Healing on damage dealt
**Target:** Player or Enemy

**Mechanics:**
- When dealing damage, **heal 5% of damage dealt per stack**
- **Capped at 100%** healing (20 stacks = max effectiveness)
- **Stacks = duration** (reduce by 1 at turn end)
- Healing calculation: `healed = min(damage_dealt * (stacks * 0.05), damage_dealt)`

**Example:** Deal 20 damage with 10 Drain → heal 50% = 10 health

**Counterpart:** Drain heals from damage dealt; Thorns reflects damage taken

---

### Recovery
**Type:** Health regeneration over time
**Target:** Player or Enemy

**Mechanics:**
- Triggers at **Turn Start** of the affected entity
- Heals **1 health per stack**
- After healing, **stacks reduce by 1**
- Stacks accumulate when reapplied

**Example:** 6 Recovery → heals 6 health → becomes 5 Recovery → next turn heals 5 → becomes 4, etc.

**Counterpart:** Recovery is to Health as Resolve is to Sanity (but Recovery is sustained, Resolve is burst)

---

### Disarmed
**Type:** Attack prevention
**Target:** Enemy or Player

**Mechanics:**
- **Cannot play Attack cards** while Disarmed
- **1 stack = 1 turn** of being Disarmed
- At turn end, **consume 1 stack**
- Skills, Powers, and Fortune cards can still be played

**Example:** 2 Disarmed → cannot attack this turn → at turn end becomes 1 Disarmed → cannot attack next turn → at turn end Disarmed removed

**Design Note:** Disarmed is powerful but not total lockdown - enemies/players can still defend or use utility cards

---

### Confusion
**Type:** Hand size reduction
**Target:** Enemy or Player

**Mechanics:**
- **Draw 1 fewer card per stack** at turn start
- **Stacks = duration** (reduce by 1 at turn end)
- Minimum 1 card drawn (cannot reduce below 1)
- Stacks accumulate when reapplied

**Example:** 3 Confusion with 5 base draw → draw 2 cards → at turn end becomes 2 Confusion

**Counterpart:** Clarity increases hand size; Confusion decreases it

---

## Buffs (Positive Effects)

### Clarity
**Type:** Hand size increase
**Target:** Player or Enemy

**Mechanics:**
- **Draw 1 extra card per stack** at turn start
- **Stacks = duration** (reduce by 1 at turn end)
- Stacks accumulate when reapplied
- Cards calculation: `cards_drawn = base_draw + clarity_stacks - confusion_stacks`

**Example:** 2 Clarity with 5 base draw → draw 7 cards → at turn end becomes 1 Clarity

**Counterpart:** Clarity increases hand size; Confusion decreases it

---

### Grit
**Type:** Damage increase (flat bonus)
**Target:** Player or Enemy

**Mechanics:**
- **+1 damage per stack** added to all attacks
- **Stacks = duration** (reduce by 1 at turn end)
- Multiple applications stack additively
- Damage calculation: `final_damage = base_damage + grit_stacks`

**Example:** 6 damage attack with 4 Grit → 10 damage

**Design Note:** Temporary Grit creates tactical timing decisions

---

### Guard
**Type:** Block increase (flat bonus)
**Target:** Player or Enemy

**Mechanics:**
- **+1 block per stack** added to all block-gaining effects
- **Stacks = duration** (reduce by 1 at turn end)
- Multiple applications stack additively
- Block calculation: `final_block = base_block + guard_stacks`

**Example:** 5 block card with 3 Guard → 8 block

**Counterpart:** Guard is the defensive mirror of Grit

---

### Surge
**Type:** Energy boost
**Target:** Player or Enemy

**Mechanics:**
- Triggers at **Turn Start**
- Grants **+1 energy per stack**
- **All stacks consumed** when triggered

**Example:** 3 Surge → at turn start gain 3 energy → Surge removed

**Design Note:** Surge enables "setup" plays - build Surge one turn, big combo next turn

---

### Focus
**Type:** Custom resource amplification
**Target:** Player or Enemy

**Mechanics:**
- **+1 custom resource gained per stack** when gaining Ammo, Faith, Fever, Scent, or Brew
- **All stacks consumed** when triggered (first resource gain)
- Stacks accumulate when reapplied
- Resource calculation: `final_gain = base_gain + focus_stacks`

**Example:** 3 Focus + gain 2 Ammo → gain 5 Ammo → Focus removed

**Design Note:** Focus is a setup buff - build stacks, then consume them on your next resource-gaining card

---

### Resolve
**Type:** Sanity regeneration
**Target:** Player or Enemy

**Mechanics:**
- Triggers at **Turn End**
- Heals **+1 sanity per stack**
- **All stacks consumed** when triggered
- Stacks accumulate when reapplied

**Example:** 5 Resolve → at turn end heal 5 sanity → Resolve removed

**Design Note:** Resolve provides delayed sanity recovery, rewarding planning and stack building. Thematically represents moments of mental fortitude.

---

## Quick Reference Table

| Status | Type | Effect | Duration | Trigger |
|--------|------|--------|----------|---------|
| **Poison** | DoT | 1 dmg/stack | -1/turn | Turn Start |
| **Burn** | Burst | Variable dmg/stack | Expires after | Turn End |
| **Curse** | Pollution | Adds curse cards | Permanent | On Apply |
| **Wounded** | Debuff | +50% damage taken | -1/turn | On Damage |
| **Weak** | Debuff | -25% damage dealt | -1/turn | On Attack |
| **Rattled** | Debuff | -25% block gained | -1/turn | On Block |
| **Dread** | Sanity DoT | 1 sanity/stack | -1/turn | Turn Start |
| **Thorns** | Reflect | 5% dmg/stack (cap 100%) | -1/turn | On Damage Taken |
| **Drain** | Heal | 5% dmg/stack (cap 100%) | -1/turn | On Attack |
| **Recovery** | HoT | 1 health/stack | -1/turn | Turn Start |
| **Disarmed** | Disable | Prevents attacks | -1/turn | On Card Play |
| **Confusion** | Debuff | -1 card draw/stack | -1/turn | Turn Start |
| **Clarity** | Buff | +1 card draw/stack | -1/turn | Turn Start |
| **Grit** | Buff | +1 dmg/stack | -1/turn | On Attack |
| **Guard** | Buff | +1 block/stack | -1/turn | On Block |
| **Surge** | Buff | +1 energy/stack | Consumed | Turn Start |
| **Focus** | Buff | +1 resource/stack | Consumed | On Resource Gain |
| **Resolve** | Buff | +1 sanity/stack | Consumed | Turn End |

---

## Implementation Notes

Each status effect will be implemented as a handler resource in `scripts/handlers/types/` and registered with the HandlerRegistry.

### Stack Behavior Categories

1. **Decaying (stacks = duration):** Poison, Dread, Recovery, Disarmed, Confusion, Clarity, Wounded, Weak, Rattled, Thorns, Drain, Grit, Guard
   - Reduce by 1 at turn end
   - Multiple applications extend duration

2. **Consumed:** Surge, Burn, Resolve, Focus
   - All stacks removed when triggered
   - Burn/Resolve trigger at turn end, Surge at turn start, Focus on resource gain

3. **Permanent:** Curse
   - Persists until specifically removed
   - Adds cards to deck that must be dealt with

### Trigger Phases

- `turn_start`: Poison damage, Dread sanity damage, Recovery healing, Surge energy, Clarity/Confusion draw modifier
- `turn_end`: Burn damage, Resolve sanity heal, stack decay for decaying effects
- `on_attack`: Grit bonus, Weak penalty, Drain healing
- `on_defend`: Guard bonus, Rattled penalty
- `on_damage_taken`: Wounded amplification, Thorns reflection
- `on_resource_gain`: Focus bonus
- `on_apply`: Curse card creation
- `on_card_play`: Disarmed attack prevention (blocks Attack-type cards)

### Damage Order of Operations

1. Base damage calculated
2. Grit added (+flat)
3. Weak applied (*0.75)
4. Wounded applied (*1.5 to target)
5. Block subtracted
6. Final damage dealt

### Block Order of Operations

1. Base block calculated
2. Guard added (+flat)
3. Rattled applied (*0.75)
4. Final block gained
