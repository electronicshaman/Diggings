# Node: The Singing Shaft

**ID:** `the_singing_shaft`
**Type:** Exploration Node (Atmosphere/Debuff)
**Biome:** Deep Mine
**Prerequisites:** `Region: Underground`

---

## Hook Text

You've been following the main adit for the better part of an hour when you hear it—a sound like wind through a hollow log, but there's no wind down here. The air is still and stale, heavy with the smell of damp earth and something else, something faintly metallic.

The sound is coming from a side shaft, half-collapsed, the timber supports rotted through and leaning at drunken angles. Someone has scratched words into the rock at the entrance, deep gouges that look like they were made with fingernails:

**"DO NOT FOLLOW THE SINGING"**

Below it, in different handwriting, fresher:

**"It sounds like her. It sounds like Mary."**

The singing grows louder. A woman's voice, wordless and beautiful, echoing up from the darkness. It's the loveliest thing you've heard since you left Melbourne, and your feet are already moving towards the shaft before you realise what you're doing.

---

## Choices

### Choice A: "Follow the singing." (Risk)
*   **Effect:**
    *   Test **Sanity** (DC 5).
    *   **On Success:** Discover `hidden_shrine` location. Gain **1 Corruption**. Add Tag `heard_the_siren`.
    *   **On Failure:** Lose **10 Sanity**. Apply **8 Dread**. Apply **3 Confusion**. Add Tag `heard_the_siren`.
*   **Narrative Outcome (Success):** "You follow the voice down into the dark, lantern raised, heart pounding. The shaft twists and turns in ways that don't make sense—you're certain you've been walking downhill, but somehow you're climbing. And then the singing stops, and you find yourself in a cavern that glitters with violet light. There's something here. Something old. You back away slowly, but you've seen where it sleeps."
*   **Narrative Outcome (Failure):** "The voice wraps around you like arms, pulling you deeper. You don't remember dropping your lantern. You don't remember falling. You come to yourself on your hands and knees in absolute darkness, throat raw from screaming, the taste of copper in your mouth. The singing has stopped, but you can still feel it inside your head, an echo that won't fade."

### Choice B: "Block your ears and push past."
*   **Effect:**
    *   Lose **3 Sanity** (the effort of resisting).
    *   Continue to next node in the mine sequence.
*   **Narrative Outcome:** "You tear strips from your shirt and stuff them in your ears. It helps, a little. The singing becomes a muffled drone, still beautiful, still pulling at something deep in your chest, but you can think. You keep your eyes on your boots and push forward, one step at a time, until the sound fades behind you. Your hands are shaking when you finally pull the cloth from your ears."

### Choice C: "Turn back. This shaft is wrong."
*   **Effect:**
    *   Gain **3 Sanity** (from trusting your instincts).
    *   Remove Node `the_singing_shaft` from current path. It may reappear elsewhere.
*   **Narrative Outcome:** "You've survived this long by knowing when to walk away. The singing calls to you, promises you things in a language you almost understand, but you've seen what happens to men who follow voices in the dark. You turn your back on the shaft and retrace your steps. The singing follows you for a long time, growing fainter, growing angrier, before it finally falls silent."

---

## Graph Rewrites
*   **Tag Added:** `heard_the_siren` (Choices A)
*   **Location Unlocked:** `hidden_shrine` (Choice A Success only)
*   **Node Removed:** `the_singing_shaft` may be removed from current path (Choice C)
