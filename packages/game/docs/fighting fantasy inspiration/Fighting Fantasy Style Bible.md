# Australian Gothic & Graph Narrative Style Bible
## A Guide for Creating Dynamic Interactive Content

---

## 1. Overview & Philosophy

We are blending the classic "You are the Hero" immersion of gamebooks with a **Graph Rewriting** narrative architecture.

In this system, the "story" is not a fixed tree but a dynamic graph where **Nodes** (events/scenes) are injected, removed, or modified based on the game state.

**The Core Ethos:**
Narrative is **fragmented but cohesive**. You are not writing a linear chapter; you are writing a *narrative atom*—a specific situation that can trigger when the conditions are right, dynamically "rewriting" the graph of future possibilities available to the player.

**Tone:**
*   **Setting:** 1850s Australian Gold Rush (Victoria). Heat, dust, flies, greed.
*   **Genre:** Cosmic Horror. The land is ancient, wrong, and waking up.
*   **Perspective:** Second Person ("You"), Present Tense.

---

## 2. Narrative Voice: "The Bush Ballad of the Void"

### Literary Synthesis: Lawson, Paterson & Lovecraft
We aim for the **rhythm and dry wit of the Australian Bush Ballad** colliding with the **unnameable horror of the Cosmic**.

*   **Henry Lawson's Influence (The Grit):** Focus on the stoic acceptance of hardship. The horror is just another thing trying to kill you, like the drought or the flood. Use his dry, sardonic acceptance of the impossible.
*   **Banjo Paterson's Influence (The Rhythm):** The romanticism of the landscape, but twisted. The grandeur of the "wide brown land" becomes the terror of the "wide empty void."
*   **H.P. Lovecraft's Influence (The Dread):** The adjective-heavy, creeping realization that the universe is vast, uncaring, and structurally wrong.

**The Synthesis Example:**
> *"You boil the billy by the creek, watching the gum leaves drift. It’d be a peaceful night, if the stars weren't moving in patterns that make your eyes water. There’s a thing in the waterhole—ancient as the granite and twice as hungry—but a man’s gotta drink, so you take your chances."*

### Second Person Present Tense
Immediate, sensory, and grounded. The player *is* the character.

> *"The dry heat of the gully presses against your chest. Your pick strikes something hard—not rock, but something smooth and warm. You recoil as the dirt begins to pulse."*

### The "Sanity Scale" Impact
Descriptions should shift based on the player's potential mental state (or the corruption level of the region). The narrator becomes unreliable.

| State | Description Style | Example |
|-------|-------------------|---------|
| **Lucid** | Gritty, historical, sensory. Focus on thirst, weight of gear, harsh sunlight. | *"A crow watches you from the dead gum tree."* |
| **Touched** | Paranoia creeps in. Shadows stretch too far. Wildlife seems to be watching. | *"The crow hasn't blinked in minutes. It knows what you're carrying."* |
| **Madness** | Hallucinatory. The geometry of the mineshaft is wrong. Colors that don't exist. | *"The bird is a hole in the sky. It screams with your father's voice."* |

---

## 3. Dynamic Narrative Structure (Graph Rewriting)

Unlike a book with page numbers ("Turn to 40"), we use **Graph Nodes**. Each piece of writing is a Node that operates on the world state.

### A. Anatomies of a Node
When designing a narrative event, define:

1.  **Prerequisites (The Trigger):** What must be true for this node to be *woven* into the graph?
    *   *e.g., Has tag `visited_bakery`, `corruption > 5`, `class: Bushranger`.*
2.  **The Hook (Text):** The sensory setup.
3.  **The Choices (Edges):** Actions the player can take.
4.  **The Rewrites (Effects):** How does this choice rebuild the graph? This is the most crucial part for the graph rewriting system.
    *   *Inject Node:* "Unlock the `Hidden Shrine` location."
    *   *Remove Node:* "The `Rickety Bridge` collapses; remove it from the map."
    *   *Modify State:* "Add tag `hunted_by_cult`." (This tag might automatically trigger other Nodes later).

### B. Example of Graph Thinking

**Static Book Approach:**
> *"If you want to fight the cultist, turn to page 45. If you run, turn to page 90."*

**Graph Approach (Writer's View):**
> **Node:** `The_Whispering_Claim`
> **Prerequisites:** `Biome: Goldfields`, `Day > 3`
> **Text:** *"A fantastical contraption sits on your claim, humming with a sound that makes your teeth ache. A hooded figure is tightening a brass valve."*
> **Choice 1:** *"Attack."* -> **Effect:** Start Combat (Cultist). **On Win:** Inject Node `Cult_Revenge_Squad` into future pool.
> **Choice 2:** *"Sabotage."* -> **Effect:** Test `Mechanics`. **On Success:** Add Loot. Remove Node `The_Whispering_Claim` permanently. Update Tag `cult_interference` +1.

---

## 4. Vocabulary & Word Choice

Abandon "Dungeon" and "Dragon" tropes. Use the language of the Diggings and the Void.

### The Mundane (Gold Rush)
*   **Verbs:** Prospect, excavate, pan, trudge, swear, gamble, bushwhack, graft.
*   **Nouns:** Billy, damper, claim, nugget, vein, quartz, ironbark, trooper, license, tent-city, cradle, windlass.
*   **Adjectives:** Alluvial, scorched, ochre, stifling, fly-blown, rusty, sun-bleached.

### The Eldritch (Lovecraftian)
*   **Verbs:** Writhe, pulse, whisper, dissolve, mutate, screech, warp, unravel.
*   **Nouns:** Void, geometry, abyss, dissonance, ichor, stars, ancestors, hunger, resonance.
*   **Adjectives:** Cyclopean, non-Euclidean, viscous, impossible, ancient, hollow, violet, throbbing.

---

## 5. Thematic Pillars: Faith & Folklore

The horror of this world is viewed through two distinct but intertwining lenses. It is not just "Post-Lovecraft"; it is Australian.

### A. Western Religion (The Apocalyptic Veil)
To the colonists, the Awakening is the End Times.
*   **Perspective:** The horror is Demonic. The madness is Sin.
*   **Voice:** Biblical, rigid, fearful, desperate. Quoting Revelations or Psalms as wards against the dark.
*   **Key Imagery:** Broken crosses, burning missions, stained glass corrupted by violet light, the "Hell" beneath the earth.

### B. Indigenous Lore (The Ancient Law)
To the First Nations characters, this is a violation of the Dreaming.
*   **Perspective:** The horror is a corruption of the Songlines, a "Wrongness" that was sung into sleep eons ago and has been woken by the picks of the white man.
*   **Voice:** Authoritative, cyclical, grounded in Deep Time. It treats the Lovecraftian entities not as "gods" but as dangerous, invasive fauna or corrupted spirits.
*   **Key Imagery:** Warped gum trees, silent billabongs, sacred sites bleeding ichor, the "Rainbow Serpent" fighting a darker, shapeless smooth thing.

### C. The Synthesis (Where They Meet)
The most unique "Australian Gothic" moments happen when these collide.
*   *Example:* A bushranger etching a cross into a bullet, while a tracker smokes the gun barrel with eucalyptus leaves. Both magics are needed.

---

## 6. Passage Types & Scenarios

### A. Exploration Nodes (Atmosphere)
Sets the scene for a biome or location.
> *"The gum trees here are pale, their bark hanging in strips like peeling skin. There is no sound of birds—only the rhythmic thumping of a piston engine somewhere deep underground."*

### B. Interaction Nodes (Risk/Reward)
Offers a clear trade or gamble.
> *"The Publican wipes a glass with a rag that looks suspiciously stained. 'Heard you've been down the deep mine,' he mutters. 'I'll trade you a bottle of my reserve brew for a look at that rock you found.'*
> *Do you **Trade the Strange Ore** (Lose 1 Ore, Gain Sanity) or **Decline**?"*

### C. Combat Nodes (The Introduction)
Don't just say "A monster appears." Make it horrifying.
> *"The piling of rocks shifts. A **GIBBERER** unfolds itself from the scree, its limbs too many and too long, a pickaxe fused into what used to be a hand."*
> *Action: Start Combat Encounter.*

### D. Consequence Nodes (State Changes)
Describe the physical and mental toll.
> *"You stare too long into the abyss of the open mine. The darkness isn't empty; it's waiting. You feel a piece of your mind chip away like slate."*
> *Effect: Lose 5 Sanity. Add a ‘Paranoia’ Status Card to your deck.*

---

## 7. Mechanical Integration

Map narrative consequences to our game resources (`CLAUDE.md` reference):

*   **Health:** Physical wounds. *"The bullet grazes your ribs. Lose 5 Health."*
*   **Sanity:** Mental trauma. *"You understand the whispers for a second. It is too much. Lose 3 Sanity."*
*   **Gold:** Material wealth. *"You pry the gold teeth from the skull. Gain 5 Gold."*
*   **Corruption:** The taint of the land. *"You eat the strange glowing fungus. It tastes like copper. Gain 1 Corruption."*
*   **Deck Modifications:** The most direct link to gameplay.
    *   *"Add a **Curse** card to your deck."*
    *   *"Upgrade a card to **Polychrome**."*
    *   *"Remove a generic **Strike**."*

---

## 8. Writing Checklist

1.  **Is it Sensory?** Can I smell the dust or hear the buzzing?
2.  **Is it Era-Appropriate?** No modern slang. Authentic 1850s grit.
3.  **Is it Dynamic?** Does this node change the state of the story graph (add tags, unlock nodes, modify deck)?
4.  **Are the Stakes Clear?** Does the player know they are risking Sanity or Health?
