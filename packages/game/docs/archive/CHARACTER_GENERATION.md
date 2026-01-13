# Character Generation System

Last verified: 2025-08-18

## Implementation Status

### ✅ Character Resources Created

The character class system has been implemented with comprehensive resource files for all 4 primary classes:

#### Character Class Structure (CharacterClass.gd)

```gdscript
extends Resource
class_name CharacterClass

# Basic character information
@export_group("Character Identity")
@export var character_class_name: String
@export var description: String
@export var mechanical_specialization: String  # Attack/Skill/Power/Fortune
@export var difficulty_rating: int  # 1=Easy to 4=Expert

# Starting statistics
@export_group("Starting Stats")
@export var base_health: int
@export var base_sanity: int
@export var base_energy: int
@export var starting_gold: int

# Starting deck composition
@export_group("Starting Deck")
@export var starting_deck: Array[CardData]
@export var starting_deck_size: int

# Character mechanics and abilities
@export_group("Class Mechanics")
@export var passive_abilities: Array[String]
@export var active_abilities: Array[String]
@export var unique_resources: Array[String]  # e.g., Ammo, Brew Tokens

# Card accessibility rules
@export_group("Card Access")
@export var class_exclusive_cards: Array[String]
@export var preferred_card_types: Array[String]
@export var forbidden_card_types: Array[String]
```

#### Implemented Character Resources

| Class | File | Specialization | Health | Sanity | Gold | Unique Mechanics |
|-------|------|---------------|--------|--------|------|------------------|
| **Bushranger** | `data/characters/bushranger.tres` | Attack | 55 | 90 | 10 | Ammo system, Outlaw's Edge |
| **Prospector** | `data/characters/prospector.tres` | Fortune | 45 | 110 | 25 | Gold Rush, Risk Tolerance |
| **Tracker** | `data/characters/tracker.tres` | Skill | 50 | 105 | 15 | Setup mechanics, Pathfinding |
| **Publican** | `data/characters/publican.tres` | Power | 50 | 95 | 20 | Brew Tokens, Social Hub |

---

### Data Sources (Current)

- Backstory elements: `data/character_generation/backstory_resources/` — subfolders: `origins/`, `tragedies/`, `motivations/`, `quirks/`
- Name pools and rules: `data/character_generation/data_pools/` — files: `names.json`, `nicknames.json`, `generation_rules.json`
- Starting curios: `data/character_generation/starting_curios/` (empty as of this verification)

Notes:

- Character `.tres` resources exist for all four classes and can be extended with generated backstory hooks.
- As assets land in the backstory folders, wire them into the generation rules JSON for coherent outputs.

## Advanced: Character Generation Through Graph Grammar

Yes! Graph grammar is perfect for procedural backstory generation. Each class becomes a **template** for generating unique characters with interconnected story elements.

## The Concept: Every Run is a New Soul

Instead of playing "The Prospector," you play as "Martha 'Goldpan' Sullivan" or "Chen 'Lucky' Wei" - each with their own generated history that affects both story and gameplay.

## Character Generation Grammar

### Base Structure

```txt
[Name] + [Nickname] + [Origin] → [Tragedy] → [Motivation] → [Quirk]
```

Each element connects to others, creating a story graph that generates both character and run modifiers.

---

## PROSPECTOR - Fortune Seekers & the Desperate

### Name Generator Grammar

**First Names**: Irish, Chinese, Welsh, Cornish (reflecting real gold rush demographics)

- Martha, Bridget, Chen, Wei, Ioan, Rhys, Jago, Tom

**Nicknames** (based on their story):

- "Goldpan", "Lucky", "Dusty", "Fever", "Broke", "Snake-Eyes", "The Banker"

### Backstory Graph Rules

**Origin Node** determines starting modifier:

```txt
[Failed Banker] → Starting gold +20, all shops cost 10% more
[Indebted Farmer] → First mine gives double gold, corruption spreads faster  
[Company Deserter] → See all mines, bounty on your head (more enemies)
[Widow/Widower] → +10 max HP, shops sometimes give free items out of pity
[Escaped Convict] → +2 damage first turn, settlements hostile
```

**Tragedy Node** (why they're desperate for gold):

```txt
[Family Held Hostage] → Timer appears: need 500 gold by day 10
[Dying Child Needs Medicine] → Healing items cost double but work better
[Lost Everything in Flood] → Water nodes give bonuses, fear of rain
[Cursed by Aboriginal Spirit] → Start with powerful curio but corrupted
[Brother Died in These Mines] → Massive damage bonus in mines, sanity loss
```

**Quirk Node** (personality flavor):

```txt
[Superstitious] → Won't enter nodes on 13th action
[Alcoholic] → Must visit pubs or lose sanity
[Religious] → Churches give double benefits
[Greedy] → Can't leave gold nodes without taking everything
```

### Example Generated Prospector

#### Example: Chen 'Snake-Eyes' Wei

- _Origin_: Failed Banker from Guangdong
- _Tragedy_: Lost family fortune in opium deal, needs gold to buy their freedom
- _Motivation_: "One big score to return home with honor"
- _Quirk_: Compulsive gambler - all Gamble cards have +2 variance
- _Starting Modifier_: Shops trust you (+1 card selection) but word spreads (prices increase each visit)

---

## BUSHRANGER - The Hunted & The Hunters

### Name Generator — Bushranger

**First Names**: English, Irish, Australian-born

- Ned, Dan, Harry, Mad Dog, Black Mary, Thunderbolt

**Nicknames**: Based on their crimes/reputation

- "The Gentleman", "Bloodshot", "Three-Day", "Gallows", "Mercy"

### Backstory Graph — Bushranger

**Origin Node**:

```txt
[Wrongly Accused] → Settlements neutral, can clear name with 3 boss kills
[Irish Rebel] → +damage vs authority figures, settlements hostile
[Ex-Trooper] → Knows patrol patterns (sees enemy intents earlier)
[Indigenous Outcast] → Knows hidden paths, traditional weapons deal more
[Escaped Chain Gang] → Stronger when injured, starts with broken chains (curio)
```

**Crime That Started It All**:

```txt
[Killed Corrupt Magistrate] → Law nodes spawn extra enemies but give gold
[Robbed Bank for Poor] → Poor nodes give free healing, rich nodes hostile
[Horse Theft] → Move extra node per day, horses fear you
[Accidentally Killed Deputy] → All gun cards have recoil damage
```

### Example Generated Bushranger

#### Example: Mary 'Mercy' O'Sullivan

- _Origin_: Ex-Trooper turned outlaw after refusing to massacre innocents
- _Crime_: Killed her commanding officer to save Aboriginal family
- _Motivation_: "Make them pay for what they made me do"
- _Quirk_: Shows mercy - gets bonus gold if enemies survive with <5 HP
- _Starting Modifier_: Military training (+10 HP), haunted by ghosts (sanity drains in combat)

---

## TRACKER - The Seekers & The Lost

### Name Generator — Tracker

**First Names**: Often Aboriginal-influenced or frontier names

- Jacky, Billy, Warru, Tom, Sarah, Moonlight

**Nicknames**: Based on tracking reputation

- "Never-Lost", "Ghost", "Bloodhound", "The Finder", "Shadow"

### Backstory Graph — Tracker

**Origin Node**:

```txt
[Aboriginal Guide] → Knows true names of places (bonus at sacred sites)
[Lost Surveyor] → Has incomplete map showing treasure, but it's cursed
[Bounty Hunter] → Can see criminal nodes, they give extra rewards
[Missing Person Investigator] → Following trail of vanished people
[Naturalist] → Studying the corruption, takes less corruption damage
```

**What They're Tracking**:

```txt
[Missing Sister] → Sister appears as special node that moves
[The Thing That Killed Everyone] → Boss is hunting you too
[Map to El Dorado] → Nodes sometimes shimmer with false gold
[Their Own Forgotten Past] → Amnesia: discover backstory through nodes
```

### Example Generated Tracker

#### Example: Jacky 'Ghost' Nameless

- _Origin_: Woke up in the goldfields with no memory, only tracking skills
- _Tracking_: Their own past - special nodes reveal memory fragments
- _Motivation_: "The land remembers what I've forgotten"
- _Quirk_: Dreamwalker - can sometimes see through fog of war while resting
- _Starting Modifier_: No identity (shops suspicious), but corruption can't stick to someone who doesn't exist (-50% corruption gain)

---

## PUBLICAN - The Social & The Spirited

### Name Generator — Publican

**First Names**: Working class British/Irish/Australian

- Molly, Rose, Big Jim, Whistling Jack, Mother Francis

**Nicknames**: Based on their establishment

- "Last Round", "The Landlord", "Honest", "Watered-Down", "Credit"

### Backstory Graph — Publican

**Origin Node**:

```txt
[Inherited Cursed Pub] → Pub nodes have special events, ghosts help sometimes
[Traveling Merchant] → Caravan gives mobile shop, but attracts bandits
[Ex-Priest/Nun] → Blessed alcohol has healing properties, demons hate you
[Criminal Informant] → Knows everyone's secrets, information is currency
[Brewing Prodigy] → Experimental brews have random effects
```

**Their Establishment's Story**:

```txt
[Built on Aboriginal Sacred Ground] → Powerful but cursed location effects
[Last Pub Before Hell] → Demons are regular customers, pay well but corrupting
[Traveling Wagon] → Pub moves around map, following you
[Underground Speakeasy] → Hidden from law but connected to smuggler network
```

### Example Generated Publican

#### Example: Mother Francis 'Last Round' O'Brien

- _Origin_: Ex-nun who inherited brother's cursed pub
- _Establishment_: "The Pearly Gates" - last pub before the breach zones
- _Motivation_: "Keep the darkness at bay with light and laughter"
- _Quirk_: Teetotaler - doesn't drink own product (immune to hangover but less brew generation)
- _Starting Modifier_: Holy water brewery (drinks damage undead), but guilty conscience (double corruption from violence)

---

## Dynamic Story Events Based on Generated Backstory

The character's generated story creates unique events:

### Prospector Chen 'Snake-Eyes' Wei might encounter

- **"Old Creditor"** node: Pay 50 gold or fight upgraded enemy
- **"Letter from Home"** event: Lose sanity but gain powerful motivation card
- **"Another Banker"** shop: Recognizes you, offers credit but at terrible terms

### Bushranger Mary 'Mercy' O'Sullivan might encounter

- **"Trooper Patrol"** node: Your old unit - harder fight but know their patterns
- **"Aboriginal Family"** event: The ones you saved offer blessing
- **"Commanding Officer's Ghost"** boss: Special nemesis fight

## Procedural Dialogue

Based on backstory elements, generate barks and commentary:

```gdscript
func generate_battle_start_dialogue(character, enemy):
    if character.tragedy == "family_hostage" and enemy.type == "bandit":
        return "You're not the only one who takes hostages, mate."
    elif character.origin == "failed_banker" and enemy.type == "prospector":
        return "I used to finance people like you. Now I am you."
    elif character.quirk == "superstitious" and current_action_count == 13:
        return "Thirteen... this won't end well."
```

## How This Affects Gameplay

### Starting Deck Modifications

Each backstory element adds/modifies one card:

- Failed Banker: One Strike becomes "IOU" (delayed damage but more)
- Family Hostage: Adds "Desperate Strike" (more damage when low on time)
- Superstitious: Adds "Lucky Charm" (block that works on non-13 turns)

### Graph Evolution Based on Story

- Chen's creditors spawn debt collector nodes over time
- Mary's military past means trooper nodes move toward her
- Jacky's memory fragments create special revelation nodes
- Mother Francis's pub attracts faithful customers (friendly nodes)

### Run-Specific Victory Conditions

Beyond just "beat the boss":

- Chen needs 500 gold to save family
- Mary needs to kill 3 authority figures to clear name
- Jacky needs to visit 5 memory nodes to remember identity
- Francis needs to keep corruption below 30% to maintain faith

## The Beauty of This System

1. **Every run tells a unique story** even with the same class
2. **Replay value** - "I wonder what backstory I'll get this time"
3. **Emergent narrative** - backstory creates unique situations
4. **Player attachment** - named characters with stories feel more real
5. **Procedural but coherent** - graph grammar ensures stories make sense

The character becomes more than just a class - they're a desperate soul with a past, a tragedy, and a reason to delve into corruption. Their story shapes the run, and the run resolves their story.
