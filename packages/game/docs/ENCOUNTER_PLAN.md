# Australian Environmental Events & Wildlife System

Last verified: 2025-08-18

## Current Implementation Snapshot

Detected encounter resources in `data/encounters/`:

### Common

- `abandoned_camp.tres`
- `brown_snake_encounter.tres`
- `found_supplies.tres`
- `injured_traveler.tres`
- `lost_prospector.tres`
- `old_mine_shaft.tres`
- `redback_in_swag.tres`
- `wounded_eagle.tres`

### Rare

- `mysterious_merchant.tres`

### Legendary

- (none yet)

### Region-specific

- (none yet)

### Story

- (none yet)

Notes:

- Use these as anchors to prioritize wiring the planned events below.
- As new `.tres` are added, expand this snapshot to stay accurate.

## Native Fauna Encounters

### Dangerous Creatures (Combat or Event)

#### Eastern Brown Snake

```gdscript
"Brown Snake Strike" - Event
Options:
- Stand perfectly still (Gamble: 70% escape, 30% take 5 damage + poison)
- Back away slowly (Lose 1 action/time, no damage)
- Strike with tool (Combat: Fast enemy, 5 HP, venomous strike)

If bitten: Poison effect - lose 2 HP per hex traveled until treated
Treatment: Antivenom (town), Bush medicine (rare), or Tourniquet (stops poison, reduces movement)
```

#### Redback Spider

```gdscript
"Redback in the Swag" - Camp Event
Wake to find redback in bedroll
- Carefully shake out (Grit check - success: no effect, fail: bitten)
- Sleep elsewhere (No rest benefit, keep sanity)
- Crush it (Safe but bad omen - corruption +1)

Bite effect: Slow poison - lose 1 sanity per day phase
```

#### Sydney Funnel-Web Spider

```gdscript
"Funnel-Web Territory" - Hex modifier
This hex has aggressive spiders
- Move carefully (Double time cost)
- Rush through (Normal time, 30% bite chance)
- Clear with fire (Remove modifier, attract attention)
```

#### Dropbear (Mythical/Corrupted Koala)

```gdscript
"From Above!" - Forest hex event
A corrupted koala drops from trees
- Look up first (Wisdom check - avoid if passed)
- Takes 8 damage if it lands on you
- Becomes combat if avoided: Corrupted beast, attacks sanity
```

### Wildlife Rescue Events (Moral Choices)

#### Injured Kangaroo

```gdscript
"Joey in Trouble" - Event
Find joey with leg caught in abandoned mining equipment
Options:
- Help free it (Lose time, gain "Bush Friend" blessing)
- Mercy kill (Gain food rations, lose sanity)
- Leave it (No effect but haunts you - occasional sanity loss)

Consequence: "Bush Friend" - Animals warn of danger, +1 hex vision in bush
```

#### Wombat in Collapsed Burrow

```gdscript
"Cave-in Survivor" - Mining hex event
Wombat trapped in collapsed mine entrance
Options:
- Dig it out (Time cost, wombat shows you safe paths later)
- Ignore (No immediate effect)
- Follow its tunnel (Find alternate route - might be safer or dangerous)

Later benefit: Wombat appears to warn before cave-ins
```

#### Wounded Wedge-tailed Eagle

```gdscript
"Eagle's Plight" - Mountain hex event
Majestic eagle with prospector's shot in wing
Options:
- Tend wound (Use medical supplies, gain "Eagle Eye" - see 1 extra hex)
- Put out of misery (Gain "Eagle Feather" curio - resist corruption)
- Leave (Eagle dies, scavengers drawn to your path)
```

#### Echidna Crossing

```gdscript
"Spiny Wanderer" - Path event
Echidna family crossing your path (Aboriginal cultural significance)
Options:
- Wait respectfully (Lose time, gain luck bonus)
- Walk around (Extra hex travel)
- Disturb them (Save time but bad luck - next Gamble auto-fails)
```

### Corrupted Australian Fauna

#### Thylacine Ghost (Tasmanian Tiger - extinct but haunting)

```gdscript
"Impossible Stripes" - Night event only
See extinct thylacine in the shadows
Options:
- Follow it (Led to either treasure or danger - 50/50)
- Ignore (Sanity check - it's impossible, right?)
- Offer food (Gain "Ghost Guide" - warns of extinct/impossible things)

Note: Seeing extinct animal damages sanity but might reveal hidden truths
```

#### Possessed Dingo Pack

```gdscript
"Howls in the Dark" - Combat encounter
Pack leader has eldritch corruption
- Fight alpha (Single combat, others flee if won)
- Throw food (Distract them, lose rations)
- Fire scares them (Use torch/matches, attracts other attention)
```

#### Giant Goanna (Monitor lizard grown huge)

```gdscript
"Ancient Monitor" - Boss-type encounter
Corrupted by eating tainted gold
- Scales deflect bullets (Guns cards do half damage)
- Bite causes gold fever (Gamble cards cost double)
- Defeating it yields corrupted gold (valuable but dangerous)
```

## Environmental Hazards

### Weather Events

#### Dust Storm

```gdscript
"Dust Devil Rising" - Regional event
Affects multiple hexes for full day
- Visibility reduced to adjacent only
- Movement costs +1 action
- Cannot use Guns cards in combat (dust jams them)
- Finding shelter negates effects
```

#### Flash Flooding

```gdscript
"Creek Becomes Torrent" - After rain
Low areas become dangerous
- Swept away (Moved 2 hexes in random direction)
- Climb to safety (Grit check, exhaustion if failed)
- Lost equipment possible
- Reveals gold in aftermath
```

#### Bushfire

```gdscript
"Smoke on the Horizon" - Multi-turn event
Fire spreading across hexes
- Fire moves 1 hex per turn in wind direction
- Creates fleeing animal events
- Can clear corrupted areas but destroys resources
- Smoke causes visibility and breathing issues
```

#### Cold Snap (Winter)

```gdscript
"Bitter Victorian Winter" - Night modifier
Unexpected freeze
- Without warm gear: lose HP each night phase
- Campfire mandatory (attracts attention)
- Water sources frozen (can't pan for gold)
- Some enemies hibernate/weakened
```

### Mining Hazards

#### Mine Shaft Collapse

```gdscript
"Timber Groaning" - Mine hex event
Old supports failing
- Engineering check to shore up
- Rush through (Gamble: might collapse)
- Turn back (Lose progress)
- If trapped: mini-game to dig out, sanity loss
```

#### Bad Air (Carbon monoxide)

```gdscript
"Stale Air" - Deep mine event
Canary stops singing / You feel dizzy
- Immediate retreat (Lose items in rush)
- Push through (Constitution check, damage if failed)
- Aired tunnels might have been sealed for reasons...
```

#### Fool's Gold

```gdscript
"Pyrite Discovery" - Mining event
Glittering vein that's not real gold
- Experience check to identify
- Mining it anyway yields "Fool's Gold" (cursed currency)
- Realizing deception: sanity loss
- Can trick others with it later
```

## Character Class Interactions

### Prospector

- Better at identifying real gold vs fool's gold
- Can read geological signs for mine safety
- Animals are more aggressive (they know what prospectors do)

### Bushranger

- Intimidates some wildlife (snakes flee)
- Can hunt animals for resources
- Bushfire experience (knows escape routes)

### Tracker

- Animal empathy (can calm/befriend easier)
- Reads weather signs (advance warning)
- Knows which creatures are corrupted vs natural

### Publican

- Can make antivenoms from alcohol + herbs
- Animals drawn to food smells
- Knows folk remedies for bites/stings

## Persistent Consequences System

### Karma Tracking

```gdscript
var wildlife_karma = 0  # -10 to +10
# Helping animals: +karma
# Harming animals: -karma

func get_random_event():
    if wildlife_karma > 5:
        # More helpful animal events
        return helpful_animal_events.pick_random()
    elif wildlife_karma < -5:
        # More aggressive animal events
        return hostile_animal_events.pick_random()
```

### Reputation Effects

```gdscript
"Known to the Bush" - Achievement/Status
- Helped 3+ animals
- Eagles circle overhead showing danger
- Wombats reveal hidden paths
- Snakes give warning before striking
```

### Environmental Storytelling

```gdscript
"The Prospector Who Saved the Joey"
- NPCs remember your actions
- Aboriginal guides respect animal kindness
- Some traders give discounts
- Corrupted animals might remember and hesitate
```

## Implementation Priority

### Phase 1: Basic Dangerous Fauna

- Brown snake events (common, realistic danger)
- Spider in equipment (camp events)
- Simple choice events (help/ignore/harm)

### Phase 2: Weather & Environment

- Dust storms (visibility mechanic test)
- Mine collapses (hex danger zones)
- Flash floods (forced movement)

### Phase 3: Karma & Consequences

- Track animal interactions
- Persistent reputation effects
- Corrupted creature variants

### Phase 4: Complex Narratives

- Multi-event chains (saved joey returns to help)
- Environmental changes (bushfire clearing corruption)
- Mythical creatures (thylacine ghosts, dropbears)

## Design Philosophy

The Australian environment should feel:

- **Dangerous but fair** - Nature gives warnings if you know how to read them
- **Alive and reactive** - Your actions have consequences
- **Uniquely Australian** - These events couldn't happen anywhere else
- **Integrated with corruption** - Some animals sense/react to eldritch influence
- **Respectful** - Real animals behave realistically, corruption explains the supernatural

This system makes the world feel lived-in and reactive while providing uniquely Australian challenges that no other game offers!
