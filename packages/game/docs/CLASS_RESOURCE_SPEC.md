# Character Class Alternative Resources - Analysis & Spec

## Current State Analysis

### Summary Table

| Class | Resource | Status | Storage | Max | Cards Using It |
|-------|----------|--------|---------|-----|----------------|
| **Bushranger** | Ammo | DEFINED ONLY | custom_resources dict | None | 0 |
| **Prospector** | Fever | DEFINED ONLY | custom_resources dict | None | 0 |
| **Tracker** | Scent | DEFINED ONLY | custom_resources dict | None | 0 |
| **Publican** | Brew | DEFINED ONLY | custom_resources dict | None | 0 |
| **Preacher** | Faith | FULLY IMPLEMENTED | Dedicated properties | 10 | 10 cards |

### Issues Found

1. **Ammo, Fever, Scent, Brew are not used by any cards** - only defined in character `.tres` files (note: Prospector defines "Fortune Streak" → rename to "Fever", Tracker defines "Setup Counter" → rename to "Scent", Publican has empty unique_resources → add "Brew")
2. **No initialization** - custom resources don't get starting values at duel start
3. **No max values** - unlike Faith, custom resources have no cap
4. **UI shows nothing** for custom resources until they're modified (created on-demand)

---

## Character Class Resource Specifications

### 1. Bushranger - Ammo

**Thematic Purpose:** Ammunition for firearms, representing careful resource management in gunfights.

**Proposed Spec:**
- **Starting Value:** 6 Ammo (full chamber)
- **Max Value:** 6 Ammo
- **Gain Mechanics:**
  - `Reload` card: Gain 3 Ammo (redesign from current draw-2)
  - Certain skill cards restore Ammo
- **Spend Mechanics:**
  - Gun attack cards cost 1-2 Ammo to play
  - Powerful shots (Six-Shooter, Fan the Hammer) cost more Ammo
- **Passive Interaction:**
  - "Outlaw's Edge": Deal +1 damage when Ammo is full
  - "Quick Draw": First attack each turn costs 1 less Ammo

**Cards to Use Ammo:**
- Six-Shooter (cost 1 Ammo, deal damage)
- Fan the Hammer (cost 3 Ammo, attack 3 times)
- Quick Shot (cost 1 Ammo, fast attack)
- Bounty Shot (cost 2 Ammo, bonus if target below 50% HP)
- Wild Shot (cost 1 Ammo, random bonus effect)
- Reload (gain 3 Ammo)

**UI Display:** "Ammo: 4/6" (current/max, like bullets in a revolver)

---

### 2. Prospector - Fever

**Thematic Purpose:** Gold Fever - the obsessive madness that gripped 1850s prospectors. A volatile, building resource representing the creeping corruption of greed.

**Historical Context:** "Gold Fever" was the actual term used for the obsessive, almost maddening pursuit of gold that drove men to abandon families, risk death, and descend into paranoid obsession.

**Proposed Spec:**
- **Starting Value:** 0 Fever
- **Max Value:** 10 Fever
- **Gain Mechanics:**
  - +1 Fever when gaining gold
  - +2 Fever when a gamble succeeds
  - +1 Fever from obsession/greed-themed cards
  - Fever builds naturally as you chase fortune
- **Spend Mechanics:**
  - Powerful fortune effects require high Fever to activate
  - Can spend Fever to boost gamble success chance
  - "If Fever is 5 or higher..." conditional effects
- **Risk/Reward:**
  - High Fever (7+) unlocks powerful but dangerous effects
  - At max Fever (10), some cards have corrupted/enhanced versions
  - Certain enemy effects deal bonus damage based on your Fever
- **Passive Interaction:**
  - "Gold Rush": +3% gamble success chance per Fever
  - "Claim Bonus": Gain +1 gold when Fever >= 3
  - "Prospector's Eye": See next card in deck when Fever >= 5

**Cards to Use Fever:**
- Pan for Gold (gain gold, +1 Fever)
- Strike It Rich (requires 5+ Fever, massive gold gain)
- Double or Nothing (+2 Fever on success, -2 on failure)
- Miner's Luck (spend 3 Fever, guarantee next gamble)
- Gold Madness (at 8+ Fever, deal damage equal to Fever)
- Claim Jumping (spend Fever to steal enemy resources)

**UI Display:** "Fever: 6/10" (with visual heat/intensity indicator, glowing hotter as it rises)

---

### 3. Tracker - Scent

**Thematic Purpose:** Primal hunting instinct, tracking prey through scent trails and reading the land.

**Proposed Spec:**
- **Starting Value:** 0 Scent
- **Max Value:** 5 Scent
- **Gain Mechanics:**
  - +1 Scent when enemy takes damage (blood in the water)
  - +1 Scent from tracking/observation cards
  - "Read the Land" type cards grant Scent
- **Spend Mechanics:**
  - Powerful strikes spend Scent for bonus damage (the kill)
  - Traps become more deadly with higher Scent
  - Can spend Scent to reveal enemy intent/hand
- **Decay:** Scent fades - lose 1 at end of turn if no damage was dealt
- **Passive Interaction:**
  - "Pathfinding": Start combat with 1 Scent
  - "Bush Medicine": Gain 1 Scent when healing
  - "Sacred Knowledge": Scent reveals hidden information at 3+

**Cards to Use Scent:**
- Track Prey (+2 Scent, minor damage to mark target)
- Read the Land (+1 Scent, draw a card)
- Snare Trap (spend 2 Scent, enemy takes damage when attacking)
- Camouflage (+1 Scent, gain stealth/evasion)
- Spirit Guide (spend 3 Scent, reveal enemy hand)
- Master Tracker (spend all Scent, deal 4 damage per Scent spent)

**UI Display:** "Scent: 2/5" (with visual indicator like animal tracks or mist)

---

### 4. Publican - Brew

**Thematic Purpose:** Homebrew concoctions - ales, spirits, and mysterious tinctures. Represents the pub owner's craft and the social lubrication of frontier hospitality.

**Historical Context:** Colonial Australian pubs served as community centers, information hubs, and sometimes dens of vice. The publican controlled the flow of alcohol - and with it, influence.

**Proposed Spec:**
- **Starting Value:** 2 Brew (always have something on tap)
- **Max Value:** 8 Brew
- **Gain Mechanics:**
  - +1 Brew at start of each turn (brewing continues)
  - +2 Brew from brewing/preparation cards
  - Some cards generate Brew when held
- **Spend Mechanics:**
  - Grog cards cost Brew to play (serving drinks)
  - Powerful effects require spending multiple Brew
  - Can spend Brew to reduce card costs (liquid courage)
- **Hold Synergy:**
  - Held cards may generate Brew each turn
  - High Brew enables enhanced hold effects
  - "Aged" effects trigger when Brew >= 6
- **Passive Interaction:**
  - "Social Hub": +1 Brew when enemy plays a card
  - "House Advantage": Cards cost 1 less Brew when Brew >= 4
  - "Community Leader": Allies gain defense when you spend Brew

**Cards to Use Brew:**
- Homebrew (+2 Brew, gain defense)
- Aged Whiskey (spend 3 Brew, deal damage + apply debuff)
- Vintage Wine (spend 4 Brew, draw 2, gain energy)
- Nightcap (spend 2 Brew, enemy loses energy next turn)
- Happy Hour (spend 1 Brew per card in hand, reduce all costs)
- Last Call (spend all Brew, massive effect based on amount spent)

**UI Display:** "Brew: 5/8" (with visual like a barrel or mug filling)

**Note:** Publican retains +1 base energy (4 vs 3) as additional class advantage.

---

### 5. Preacher - Faith (ALREADY IMPLEMENTED)

**Current Implementation (for reference):**
- **Starting Value:** 0 Faith
- **Max Value:** 10 Faith
- **Storage:** Dedicated `faith` and `max_faith` properties in PlayerData
- **Cards:** 10 cards use FaithEffect
- **Passives:**
  - "Fervent Faith": +1 defense when gaining Faith
  - "Holy Conviction": +gambling success chance based on Faith
  - "Temptation": Choice trigger when reaching max Faith

**UI Display:** "Faith: 5/10"

---

## Implementation Requirements

### Files to Modify

1. **`scripts/data/player_data.gd`**
   - Add `max_custom_resource` handling
   - Initialize custom resources from character class at duel start

2. **`scripts/data/duel_state.gd`**
   - Initialize custom resources in `start_duel()` based on character class

3. **`scripts/managers/ui_controller.gd`**
   - Show resource as "current/max" format
   - Initialize label based on character's unique_resources

4. **`scripts/characters/character_class.gd`**
   - Add `starting_resource_values: Dictionary` property
   - Add `max_resource_values: Dictionary` property

5. **Card data files** (multiple in `data/cards/`)
   - Add ResourceEffect with appropriate resource_type to Bushranger/Prospector/Tracker cards

### New Effect Types (Future Implementation)

When implementing, create dedicated effect types following the FaithEffect pattern:

```
scripts/effects/types/
├── ammo_effect.gd    # AmmoEffect for Bushranger
├── fever_effect.gd   # FeverEffect for Prospector
├── scent_effect.gd   # ScentEffect for Tracker
├── brew_effect.gd    # BrewEffect for Publican
└── faith_effect.gd   # (existing) FaithEffect for Preacher
```

Each should:
- Extend GameEffect base class
- Handle max value capping
- Emit appropriate EventBus signals for passive ability triggers
- Support both gain and spend operations

---

## Document Status

**Type:** Reference Specification
**Created:** 2025-01-04
**Architecture Decision:** Dedicated effect types (AmmoEffect, etc.) preferred over generic ResourceEffect
