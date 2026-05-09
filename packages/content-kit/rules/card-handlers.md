# Card Handler Registry

Card mechanics for the deck-builder layer (forge). Each handler produces a runtime effect; cards reference handlers by `handlerId` with parameter values. Card types: Attack, Skill, Power, Hex, Curse, Fortune.

---

## damage
**Deal damage to an enemy target.**
Applicable to: Attack, Hex, Curse

| Param | Type | Required | Example | Description |
|-------|------|:-------:|---------|------------|
| amount          | number  | ✓ | 6     | Base damage amount |
| ignores_defense | boolean |   | false | Whether damage ignores defense |
| multi_hit       | boolean |   | false | Whether to hit multiple times |
| hits            | number  |   | 3     | Number of hits (if multi_hit) |
| random_range    | boolean |   | false | Whether damage is randomized |
| min_amount      | number  |   | 4     | Minimum damage (if random_range) |
| max_amount      | number  |   | 8     | Maximum damage (if random_range) |

---

## health
**Restore health to self.**
Applicable to: Skill, Fortune

| Param | Type | Required | Example | Description |
|-------|------|:-------:|---------|------------|
| amount           | number  | | 8     | Amount of health to restore |
| percentage_based | boolean | | false | Whether amount is % of max health |
| percentage       | number  | | 25    | Percentage of max health (0–100) |
| full_heal        | boolean | | false | Fully restore all health |

---

## defense
**Grant defense (block) to self.**
Applicable to: Skill, Power

| Param | Type | Required | Example | Description |
|-------|------|:-------:|---------|------------|
| amount   | number | ✓ | 5 | Amount of defense to grant |
| duration | number |   | 0 | Duration in turns (0 = until next turn) |

---

## sanity
**Restore sanity to self.**
Applicable to: Skill, Fortune

| Param | Type | Required | Example | Description |
|-------|------|:-------:|---------|------------|
| amount           | number  | | 5     | Amount to restore |
| percentage_based | boolean | | false | Whether amount is a percentage |
| full_restore     | boolean | | false | Fully restore all sanity |

---

## sanity_damage
**Deal sanity damage to target.**
Applicable to: Hex, Curse

| Param | Type | Required | Example | Description |
|-------|------|:-------:|---------|------------|
| amount           | number  | ✓ | 4     | Amount of sanity damage |
| percentage_based | boolean |   | false | Whether amount is a percentage |

---

## resource
**Modify a resource (gold, energy, or class-specific).**
Applicable to: Fortune, Skill, Power

| Param | Type | Required | Example | Description |
|-------|------|:-------:|---------|------------|
| resource_type    | string  | ✓ | "gold" | gold, energy, sanity, faith (Preacher), ammo (Bushranger), fever (Prospector), scent (Tracker), brew (Publican) |
| amount           | number  | ✓ | 2      | Amount to add (negative to subtract) |
| can_go_negative  | boolean |   | false  | Whether resource can go below zero |
| random_range     | boolean |   | false  | Randomized amount |
| min_amount       | number  |   | 1      | Min (if random_range) |
| max_amount       | number  |   | 3      | Max (if random_range) |

---

## stat
**Modify a character stat (permanent or temporary).**
Applicable to: Power, Skill

| Param | Type | Required | Example | Description |
|-------|------|:-------:|---------|------------|
| stat_name      | string | ✓ | "strength" | e.g. strength, dexterity, max_health |
| modifier_value | number | ✓ | 2          | Value of modifier |
| modifier_type  | string | ✓ | "flat"     | "flat" or "percent" |
| duration       | number |   | 3          | Combat turns (0 = permanent) |

---

## card
**Manipulate cards in hand, deck, or discard.**
Applicable to: Skill, Fortune

| Param | Type | Required | Example | Description |
|-------|------|:-------:|---------|------------|
| action      | string | ✓ | "draw"   | draw, discard, shuffle, exhaust |
| amount      | number | ✓ | 2        | Number of cards |
| card_filter | string |   | "attack" | Filter (e.g. attack, skill, random) |

---

## karma
**Modify karma standing with wildlife or people.**
Applicable to: Fortune, Skill

| Param | Type | Required | Example | Description |
|-------|------|:-------:|---------|------------|
| karma_category | string | ✓ | "people"            | "wildlife" or "people" |
| amount         | number | ✓ | 1                   | Karma change |
| reason         | string |   | "helped a stranger" | Narrative reason |

---

## status
**Apply a status effect to self or enemy.**
Applicable to: Attack, Skill, Hex, Curse

| Param | Type | Required | Example | Description |
|-------|------|:-------:|---------|------------|
| status_effect_id | string | ✓ | "weak"  | disarmed, weak, wounded, rattled, grit, guard, surge (legacy: stun, weaken, vulnerable, frail, strength, dexterity, vigor) |
| stacks           | number |   | 1       | Number of stacks |
| apply_to         | string | ✓ | "enemy" | "enemy" or "self" |
