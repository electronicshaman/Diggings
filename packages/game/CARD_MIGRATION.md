# Card Migration Plan: CardEffect → GameEffect

## Overview

**Migration Goal**: Replace all CardEffect-based card effects with the new GameEffect system.

- **Total Cards**: 42
- **Unique Effect Types**: 35  
- **Strategy**: Breaking change approach - update CardData to only accept GameEffect, forcing systematic migration

## Why This Migration?

1. **Conditional Effects**: New system supports positional conditions (first card played, last card in hand, etc.)
2. **Cleaner Architecture**: One unified effect system instead of two
3. **Better Composition**: Effects can be combined and configured more flexibly
4. **Future-Proof**: Extensible for new mechanics

## Effect Type Mapping

### Priority 1: Core Combat (Ready to Migrate)
Already have corresponding GameEffect types:

| CardEffect | GameEffect | Status | Notes |
|------------|-----------|--------|-------|
| `damage` | `DamageEffect` | ✅ Ready | Basic damage dealing |
| `defense` | `DefenseEffect` | ✅ Ready | Defense/armor gain |
| `heal` | `HealthEffect` | ✅ Ready | Health restoration |
| `draw` | `CardManipulationEffect` | ✅ Ready | Card drawing |
| `sanity_restore` | `SanityEffect` | ✅ Ready | Sanity restoration |

### Priority 2: Conditional Effects (Use New Conditional System)
These leverage the new EffectCondition and ConditionalValue system:

| CardEffect | GameEffect | Migration | Notes |
|------------|-----------|-----------|-------|
| `ambush_damage` | `DamageEffect` + `ConditionalValue` | 🎯 **Start Here** | First card = 15 dmg, else 6 dmg |
| `conditional_damage` | `DamageEffect` + `ConditionalValue` | 🔄 Ready | Variable damage based on conditions |
| `conditional_defense` | `DefenseEffect` + `ConditionalValue` | 🔄 Ready | Variable defense based on conditions |
| `conditional_draw` | `CardManipulationEffect` + `ConditionalValue` | 🔄 Ready | Variable card draw |
| `conditional_heal` | `HealthEffect` + `ConditionalValue` | 🔄 Ready | Variable healing |
| `first_card_draw` | `CardManipulationEffect` + `EffectCondition` | 🔄 Ready | Draw only if first card |
| `quick_draw_damage` | `DamageEffect` + `EffectCondition` | 🔄 Ready | Damage based on card position |

### Priority 3: Resource Management (Need New GameEffect Types)
Require new or extended GameEffect implementations:

| CardEffect | GameEffect | Status | Implementation Needed |
|------------|-----------|--------|----------------------|
| `gold_gain` | `ResourceEffect` | 🚧 Create | Gold/currency management |
| `gold_risk` | `ResourceEffect` + gambling | 🚧 Create | Risk/reward gold mechanics |
| `gold_scaling` | `ResourceEffect` + scaling | 🚧 Create | Gold effects that scale |
| `cost_reduction` | `StatEffect` | 🚧 Extend | Card cost modification |
| `temporary_energy` | `ResourceEffect` | 🚧 Create | Temporary energy boost |
| `next_card_discount` | `StatEffect` | 🚧 Extend | Cost reduction for next card |

### Priority 4: Complex Mechanics (Need Custom GameEffect Types)
Require new specialized GameEffect types:

| CardEffect | GameEffect | Status | Implementation Needed |
|------------|-----------|--------|----------------------|
| `coin_flip` | `RandomChoiceEffect` | 🆕 Create | Binary random outcomes |
| `fortune_choice` | `ChoiceEffect` | 🆕 Create | Player choice mechanics |
| `fortune_bonus` | `FortuneEffect` | 🆕 Create | Luck-based scaling |
| `fortune_scaling` | `FortuneEffect` | 🆕 Create | Fortune scaling mechanics |
| `enemy_debuff` | `StatusEffect` | 🆕 Create | Enemy status effects |
| `enemy_intent_reveal` | `InformationEffect` | 🆕 Create | Information gathering |
| `delayed_damage` | `DamageEffect` + timing | 🔧 Extend | Use timing="delayed" |
| `delayed_defense` | `DefenseEffect` + timing | 🔧 Extend | Use timing="delayed" |
| `turn_end` | `TriggerEffect` | 🆕 Create | End-of-turn effects |
| `hold_bonus` | `ConditionalEffect` | 🔧 Create | Effects while holding card |
| `fatal_damage_prevention` | `PreventionEffect` | 🆕 Create | Damage prevention |
| `defense_to_healing` | `ConversionEffect` | 🆕 Create | Stat conversion |

### Priority 5: Specialized/Rare (Low Priority)
Less common effects that can be migrated later:

| CardEffect | Notes |
|------------|-------|
| `card_peek` | Information gathering - low priority |
| `multiple_damage` | Likely DamageEffect with multi_hit |
| `multi_ hit_damage` | Already supported by DamageEffect |
| `power` | Generic power effect - needs clarification |
| `random_damage` | DamageEffect with randomization |

## Card Inventory by Category

### Attack Cards (10 cards)
- `aged_whiskey.tres` - damage
- `ambush.tres` - **ambush_damage** 🎯 **Start here**
- `bounty_shot.tres` - damage 
- `desperados_gambit.tres` - damage
- `dynamite.tres` - delayed_damage
- `fan_the_hammer.tres` - multi_hit_damage
- `pickaxe_strike.tres` - damage
- `quick_shot.tres` - damage + first_card_draw
- `six_shooter.tres` - quick_draw_damage
- `wild_shot.tres` - random_damage

### Skill Cards (17 cards)
- `bandits_code.tres` - defense
- `bar_fortification.tres` - defense
- `bush_cover.tres` - defense
- `bush_survival.tres` - heal
- `bush_telegraph.tres` - card_peek
- `campfire_rest.tres` - heal + sanity_restore
- `claim_stake.tres` - defense
- `free_drinks.tres` - heal
- `happy_hour.tres` - heal + temporary_energy
- `homebrew.tres` - conditional_heal
- `last_call.tres` - defense + draw
- `last_stand.tres` - fatal_damage_prevention
- `nightcap.tres` - sanity_restore
- `outlaws_intuition.tres` - defense + enemy_intent_reveal
- `reload.tres` - draw
- `smooth_talk.tres` - enemy_debuff
- `steady_hands.tres` - next_card_discount
- `swagmans_wisdom.tres` - conditional_draw
- `take_cover.tres` - defense
- `tool_maintenance.tres` - cost_reduction
- `vintage_wine.tres` - heal + defense
- `wanted_poster.tres` - gold_gain

### Power Cards (3 cards)
- `bouncers_presence.tres` - power
- `house_rules.tres` - turn_end
- `pub_brawl.tres` - damage + defense

### Fortune Cards (12 cards)
- `claim_jumping.tres` - gold_gain
- `double_or_nothing.tres` - gold_risk
- `lucky_nugget.tres` - gold_gain
- `miners_luck.tres` - fortune_choice
- `pan_for_gold.tres` - gold_scaling
- `prospectors_instinct.tres` - fortune_bonus
- `strike_it_rich.tres` - coin_flip

## Migration Steps

### Phase 1: Breaking Change Implementation
1. **Update CardData.gd**:
   ```gdscript
   # Change this line:
   @export var effects: Array[CardEffect] = []
   # To this:
   @export var effects: Array[GameEffect] = []
   ```

2. **Update CardEffects processor**:
   - Remove all legacy CardEffect handling
   - Keep only GameEffect processing path
   - Ensure context passing works correctly

3. **Result**: All cards will error until migrated (intentional!)

### Phase 2: Start with Ambush Card
**Target**: Fix the "first card played" timing issue that started this whole migration.

1. Create DamageEffect with ConditionalValue for ambush
2. Update `ambush.tres` to use new effect
3. Test that conditional system works properly
4. Verify timing context is passed correctly

### Phase 3: Batch Migration by Priority
1. **Priority 1**: Migrate basic combat effects (damage, defense, heal, draw)
2. **Priority 2**: Migrate conditional effects using new system
3. **Priority 3**: Create new GameEffect types for resource management
4. **Priority 4**: Create specialized GameEffect types for complex mechanics

### Phase 4: Testing and Validation
- Test each migrated card
- Verify effect descriptions are correct
- Ensure conditional effects work as expected
- Performance testing

## Implementation Notes

### New GameEffect Types Needed

1. **ResourceEffect** - Handle gold, energy, costs
2. **RandomChoiceEffect** - Handle coin flips and random choices  
3. **ChoiceEffect** - Handle player choices
4. **StatusEffect** - Handle enemy debuffs and buffs
5. **InformationEffect** - Handle card peeks and intent reveals
6. **PreventionEffect** - Handle damage/effect prevention
7. **ConversionEffect** - Handle stat conversions
8. **TriggerEffect** - Handle turn-end and triggered effects

### Conditional System Usage

The new conditional system supports:
- **EffectCondition**: When effects activate (first card, last card, etc.)
- **ConditionalValue**: Different values based on conditions (15 damage vs 6 damage)

Example for Ambush:
```gdscript
# DamageEffect with ConditionalValue
amount = 6  # base damage
conditional_values = [
  ConditionalValue {
    property_name: "amount"
    condition: EffectCondition { condition_type: FIRST_CARD_PLAYED }
    value_if_true: 15
    value_if_false: 6
  }
]
```

## Success Criteria

- [ ] All 42 cards migrated to GameEffect system
- [ ] "First card played" timing issue resolved
- [ ] No CardEffect references remain in codebase
- [ ] All cards function as expected in gameplay
- [ ] Effect descriptions display correctly
- [ ] New conditional effects work properly
- [ ] Performance is maintained or improved

## Migration Tracking

Track progress in this file by updating checkboxes as cards are migrated:

### Attack Cards
- [ ] aged_whiskey.tres
- [ ] ambush.tres 🎯 **Next**
- [ ] bounty_shot.tres  
- [ ] desperados_gambit.tres
- [ ] dynamite.tres
- [ ] fan_the_hammer.tres
- [ ] pickaxe_strike.tres
- [ ] quick_shot.tres
- [ ] six_shooter.tres
- [ ] wild_shot.tres

### Skill Cards  
- [ ] bandits_code.tres
- [ ] bar_fortification.tres
- [ ] bush_cover.tres
- [ ] bush_survival.tres
- [ ] bush_telegraph.tres
- [ ] campfire_rest.tres
- [ ] claim_stake.tres
- [ ] free_drinks.tres
- [ ] happy_hour.tres
- [ ] homebrew.tres
- [ ] last_call.tres
- [ ] last_stand.tres
- [ ] nightcap.tres
- [ ] outlaws_intuition.tres
- [ ] reload.tres
- [ ] smooth_talk.tres
- [ ] steady_hands.tres
- [ ] swagmans_wisdom.tres
- [ ] take_cover.tres
- [ ] tool_maintenance.tres
- [ ] vintage_wine.tres
- [ ] wanted_poster.tres

### Power Cards
- [ ] bouncers_presence.tres
- [ ] house_rules.tres  
- [ ] pub_brawl.tres

### Fortune Cards
- [ ] claim_jumping.tres
- [ ] double_or_nothing.tres
- [ ] lucky_nugget.tres
- [ ] miners_luck.tres
- [ ] pan_for_gold.tres
- [ ] prospectors_instinct.tres
- [ ] strike_it_rich.tres

---

## Next Steps

1. **Implement the breaking change** (Update CardData)
2. **Start with ambush card migration** (Fix the timing issue)
3. **Create additional GameEffect types as needed**
4. **Migrate cards systematically by priority**

This migration will modernize the entire card effect system and fix the conditional effect timing issues that prompted this work.