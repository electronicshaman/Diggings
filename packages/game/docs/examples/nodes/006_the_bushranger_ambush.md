# Node: The Bushranger's Ambush

**ID:** `the_bushranger_ambush`
**Type:** Encounter Node (Combat)
**Biome:** Road / Scrub
**Prerequisites:** `Gold > 20`

---

## Hook Text

The road narrows between two granite outcrops, perfect country for an ambush if you've ever seen it. You're halfway through the pass when a figure steps out from behind a boulder, a carbine levelled at your chest.

"That's far enough, friend."

He's a big man, bearded, dressed in the ragged remnants of what might once have been a trooper's uniform. Two more emerge from the scrub behind you—a wiry fellow with a knife and a woman with dead eyes and a shotgun. Bushrangers. The scourge of the goldfields.

"Here's how this works," the big man says, almost conversationally. "You hand over your gold, your supplies, and anything else we fancy. You do that, you walk away with your life. You don't..." He shrugs, and the motion makes the barrel of his carbine bob. "Well. The crows have to eat something."

The woman hasn't blinked since she stepped into view. There's something wrong about the way she holds herself, something too still, too patient. And now that you look closer, you can see that the shadows around her don't quite match the angle of the sun.

---

## Choices

### Choice A: "Hand over your valuables." (Surrender)
*   **Effect:**
    *   Lose **All Gold**.
    *   Lose **1 Random Curio** (if any).
    *   Continue on your way, shaken but alive.
*   **Narrative Outcome:** "You raise your hands slowly and let them take what they want. The big man goes through your pack with practiced efficiency while the woman watches, that dead gaze never leaving your face. 'Smart,' the leader says when they're done, tossing your empty pack at your feet. 'Smarter than most.' They melt back into the scrub as quickly as they appeared, and you're left standing in the dust, alive and poor."

### Choice B: "Fight back." (Combat)
*   **Effect:**
    *   Start Combat: **BUSHRANGER GANG** (3 enemies).
    *   **On Win:** Gain **30 Gold**. Gain **Curio: "Trooper's Badge"** (Common). Add Tag `killed_harrigans_boys`.
    *   **On Loss:** Standard death/wound consequences.
*   **Narrative Outcome (Victory):** "The big man's eyes widen as you move—faster than he expected, faster than anyone expects. The fight is brutal, short, and bloody. When it's over, you're standing in a circle of bodies, breathing hard, the copper taste of violence in your mouth. You rifle through their pockets and find more gold than honest men should carry. The woman—the last to fall—smiles at you as she dies, a smile that has too many teeth."

### Choice C: "Try to talk your way out." (Skill Check)
*   **Effect:**
    *   Test **Charisma/Luck**.
    *   **On Success:** Lose **10 Gold** (partial bribe). Continue safely. Gain Tag `owes_harrigan_a_favour`.
    *   **On Failure:** Forced into Combat (as Choice B).
*   **Narrative Outcome (Success):** "'Wait,' you say, keeping your voice steady. 'I know Harrigan. We've done business.' It's a lie—you've never met the man—but you've heard the name in enough pubs to take a gamble. The big man hesitates. The woman's head tilts, birdlike. After a long moment, the leader lowers his carbine. 'Ten coin,' he says. 'Call it a toll. And you tell Harrigan that Burke says hello.' You pay the toll and walk, feeling their eyes on your back until the scrub swallows the road behind you."

---

## Graph Rewrites
*   **Tag Added:** `killed_harrigans_boys` (Choice B Victory), `owes_harrigan_a_favour` (Choice C Success)
*   **Node Injected:** If `killed_harrigans_boys` is set, inject `harrigans_revenge` into future pool.
*   **Gold/Curio Modified:** Various based on outcome.
