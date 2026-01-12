# Narrative Node Types & Effect Integration
## A Catalog of Graph Rewriting Components

---

## 1. Overview

This document defines the specific **Node Types** available for the graph rewriting narrative system. It acts as the bridge between the **Australian Gothic Style Bible** and the **Status Effects Specification**.

Each Node Type represents a template for a "narrative atom" that can be injected into the story graph.

---

## 2. Standard Node Types

### A. The "Encounter" Node (Combat)
A mandatory conflict, often foreshadowed by the environment.
*   **Narrative Function:** Pacing spike; tension release through action.
*   **Key Fields:** `EnemyID`, `EnvironmentTag` (e.g., *Cave, Scrub*).
*   **Example Text:** "The silence of the gully is broken by a wet, tearing sound. From behind the rusted remains of a cradle, a shape rises. It wears the tattered remains of a trooper's uniform, but the face is a featureless expanse of grey, fungoid flesh. It raises a weapon that has fused with its hand."
*   **Typical Outcome:**
    *   **Win:** Inject `Loot_Node` + Inject `XP_Reward`.
    *   **Loss:** Death or Inject `Severely_Wounded_Node`.

### B. The "Choice" Node (Branching)
The standard interactive event where player agency defines the story.
*   **Narrative Function:** Agency and Roleplaying.
*   **Structure:**
    *   **Hook:** Deep sensory description of the situation (2-3 paragraphs).
    *   **Option A:** Risk (Skill Check) - "Attempt to pick the ancient lock."
    *   **Option B:** Cost (Pay Resource) - "Smash it open (Lose 1 Durability/Health)."
    *   **Option C:** Leave (No change) - "Walk away."

### C. The "State Check" Node (Passive)
A node that resolves instantly without player input to weave consequences into the narrative flow.
*   **Narrative Function:** Reactivity; showing the world remembers.
*   **Example:** *The text changes based on your corruption.*
    *   *Low Corruption:* " The camp is quiet. a few diggers sit by the fire."
    *   *High Corruption:* "The camp is silent as the grave. The diggers stare at you with eyes that reflect no firelight, their movements jerky and unnatural."
*   **Logic:** *IF Condition Met -> Inject Node X, ELSE -> Inject Node Y.*

### D. The "Rest" Node (Recovery)
A moment of respite in a hostile world.
*   **Narrative Function:** Pacing release; reflection.
*   **Example Text:** "You find a hollow beneath the roots of a massive Ironbark. It is dry here, and surprisingly cool. For a moment, the oppressive buzzing of the flies ceases. You unroll your swag and dare to close your eyes, letting the smell of eucalyptus wash away the stench of blood and sulfur."
*   **Mechanics:** Restore Health/Sanity, modify Deck (Remove Curse).

---

## 3. Integrating Status Effects (Buffs & Debuffs)

Narrative nodes should play with the **Status Effects** defined in `STATUS_EFFECTS_SPEC.md`. These effects are not just for combat; they act as "narrative tags" that persist into the next battle.

### A. Debuffs (The Hostile Land)

| Status | Narrative Flavor | Node Implementation Example |
| :--- | :--- | :--- |
| **Poison** | **Envenomation / Sickness**<br>Snake bites, rotten damper, festering wounds. | **Node:** *The Stagnant Creek*<br>**Choice:** Drink deeply.<br>**Result:** Restore 5 Health, Apply **10 Poison** (starts ticking next combat). |
| **Dread** | **Eldritch Exposure**<br>Whispers, geometry that hurts to look at. | **Node:** *The Glyph*<br>**Choice:** Study the markings.<br>**Result:** Gain 'Ancient Knowledge' (Tag), Apply **5 Dread** (Sanity rot). |
| **Wounded** | **Physical Trauma**<br>Traps, falls, sudden violence. | **Node:** *Collapsed Adit*<br>**Fail Check:** Rocks crush your leg.<br>**Result:** Lose 5 HP, Apply **Permanent Wounded** (until Campfire). |
| **Weak** | **Exhaustion / Heat**<br>Heatstroke, thirst, starvation. | **Node:** *The Long March*<br>**Condition:** No supplies.<br>**Result:** Apply **3 Weak** (Damage output reduced). |
| **Confusion** | **Disorientation**<br>Gas, concussion, manic rambling. | **Node:** *Spores*<br>**Fail Check:** Breathe in the yellow dust.<br>**Result:** Apply **4 Confusion** (Hand size reduced). |
| **Curse** | **Persistent Haunting**<br>Stolen idols, bad omens. | **Node:** *Grave Robbing*<br>**Choice:** Take the ring.<br>**Result:** Add **"Greed" Curse** to Deck. |

### B. Buffs (The Survivor's Edge)

| Status | Narrative Flavor | Node Implementation Example |
| :--- | :--- | :--- |
| **Grit** | **Adrenaline / Anger**<br>Righteous fury, desperation. | **Node:** *The Ambush Turned*<br>**Success:** You spot them first.<br>**Result:** Start next combat with **3 Grit** (+Damage). |
| **Clarity** | **Insight / Focus**<br>Maps, plans, moments of lucidity. | **Node:** *High Vantage*<br>**Choice:** Survey the land.<br>**Result:** Start next combat with **2 Clarity** (+Hand Size). |
| **Resolve** | **Stoicism**<br>Prayer, memory of purpose, stubbornness. | **Node:** *The Locket*<br>**Choice:** Remember who you fight for.<br>**Result:** Start next combat with **5 Resolve** (Sanity Heal). |
| **Surge** | **Momentum**<br>A lucky break, perfect preparation. | **Node:** *Fresh Supplies*<br>**Choice:** Eat the hearty meal.<br>**Result:** Start next combat with **3 Surge** (Bonus Energy turn 1). |

---

## 4. Specific Node Templates (Examples)

### Template 1: The "Risk-Reward" Buff Node
**Title:** *The Abandoned Smithy*
**Biome:** Town / Ruin
**Prereq:** None
**Text:** "The forge itself is cold, dead iron smelling of rust and long abandonment. Yet, amidst the scattered tools and refuse, a half-finished breastplate sits upon the anvil. It looks clumsy—rough-hammered and heavy—but as you run your hand over the metal, you feel a solidity that the modern, mass-produced gear lacks. It would be a burden to carry, but it might just turn a blade when it matters."
*   **Choice A: "Take it." (Gain Defense)**
    *   **Effect:** Start next 2 Combats with **5 Guard**.
    *   **Cost:** Add 'Heavy Gear' Tag (Maybe slows travel).
    *   **Narrative Outcome:** "You strap the heavy plate over your chest. It constricts your breathing, a constant weight, but the steel is thick enough to stop a musket ball."
*   **Choice B: "Scrap it." (Gain Resource)**
    *   **Effect:** Gain 10 Gold.
    *   **Narrative Outcome:** "Iron is scarce out here. You take a hammer to the plate, breaking it down into usable scrap that the local trader might appreciate."

### Template 2: The "Corruption" Debuff Node
**Title:** *The Singing Crystal*
**Biome:** Deep Mine
**Prereq:** `Sanity > 5`
**Text:** "You round a bend in the adit and the light from your lantern catches it—a violet crystal embedded in the quartz wall, pulsating with a rhythm that seems to match your own heartbeat. It hums, a low, thrumming vibration that makes your teeth ache and your vision swim. There is a terrible beauty to it, a promise of power that whispers directly into the base of your skull, urging you to reach out."
*   **Choice A: "Touch it." (Power at a Cost)**
    *   **Effect:** Add **Random Rare Card** to Deck.
    *   **Penalty:** Apply **10 Dread** (Sanity rot starts immediately next fight).
    *   **Narrative Outcome:** "Your fingers graze the facet. A jolt of cold fire races up your arm, searing new knowledge into your mind. You understand things now—terrible, geometrical truths—but the humming hasn't stopped. It's inside you now."
*   **Choice B: "Smash it." (Safety)**
    *   **Effect:** Lose 2 Health (Shrapnel). Remove Node from Graph.
    *   **Narrative Outcome:** "You swing your pick with desperate force. The crystal shatters with a scream like tearing metal. Shards fly, cutting your cheek, but the oppressive singing finally ceases."

### Template 3: The "Class Specific" Node
**Title:** *The Bushman's Sign*
**Biome:** Scrub
**Prereq:** `Class: Tracker`
**Text:** "To any other digger, this patch of scrub is just another tangle of dry wattle and dust. But you stop, crouching low. A broken twig here, a disturbance in the ant dirt there—someone has passed through here recently. Not a man, not a kangaroo. Something heavy, dragging its left leg, moving with a purpose that suggests it is hunting, not grazing."
*   **Choice A: "Read the signs."**
    *   **Effect:** Gain **Clarity 3** (Preparation). Reveal nearby Map Nodes.
    *   **Narrative Outcome:** "You piece together the creature's path. You know where it feeds, where it waters. When you face it, you won't be surprised."
*   **Choice B: "Ignore it."**
    *   **Effect:** None.
    *   **Narrative Outcome:** "Whatever it is, it's not your problem today. You keep your head down and move on, leaving the tracks behind."

### Template 4: The "Syncretic Lore" Node
**Title:** *The Broken Mission*
**Biome:** Outskirts
**Prereq:** `Class: Preacher` or `Tag: Ancient_Knowledge`
**Text:** "The skeleton of a church stands against the violet sky, its roofless timber ribs bleached white. But inspect closer, and you see why it burned. The font has been replaced with a smooth, black grinding stone that feels warm to the touch. Scratched into the floorboards are circles within circles—Dreaming motifs—but they have been violently crossed out with charcoal crucifixes, over and over, as if the priest here was trying to cancel out a song he couldn't stop hearing."
*   **Choice A: "Pray (Western Ward)."**
    *   **Effect:** Remove **All Curses** from Deck. Gain **5 Resolve** (Sanity Heal).
    *   **Narrative Outcome:** "You kneel in the ashes and speak the old words. They feel thin here, but they hold. The buzzing in your head quiets, if only for a moment."
*   **Choice B: "Listen to the Stone (Indigenous Lore)."**
    *   **Effect:** Gain **Focus 3**. Add **"Eldritch Insight"** Card to Deck (Powerful Skill).
    *   **Narrative Outcome:** "You ignore the crosses and place your hand on the warm stone. You can hear the earth breathing below it. It is not Satanic; it is simply vast. You understand now why the priest went mad."

---

## 5. Implementation Checklist for Writers

When creating a node that gives a Status Effect:
1.  **Check `STATUS_EFFECTS_SPEC.md`:** Ensure you are using the correct name (e.g., use "Grit" not "Strength").
2.  **Define Duration:** narrative buffs usually apply to the *start* of the next combat.
    *   *Syntax:* `ApplyStatus(Target: Player, Type: Grit, Stacks: 3, Duration: NextCombat)`
3.  **Thematic Match:** Don't give "Poison" for a mental trauma event (use "Dread"). Don't give "Weak" for a broken shield (use "Rattled" or lose Health).
