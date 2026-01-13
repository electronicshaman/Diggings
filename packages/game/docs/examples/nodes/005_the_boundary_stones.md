# Node: The Boundary Stones

**ID:** `the_boundary_stones`
**Type:** Choice Node (Thematic - Indigenous Lore)
**Biome:** Scrub / Sacred Site
**Prerequisites:** None

---

## Hook Text

The stones rise from the red earth like broken teeth—seven of them, arranged in a circle that's too perfect to be natural. They're covered in paintings: white ochre and red, spirals and lines and figures that seem to move when you look at them from the corner of your eye.

You've heard of places like this. The old-timers call them "bora rings" and warn you to stay clear. Bad luck, they say. Bad dreams. The troopers hanged a man last year for disturbing one near Ballarat—not for the sacrilege, but because he walked into town three days later and butchered his own family with a skinning knife.

A stillness hangs over the stones, a silence so complete that you can hear your own heartbeat. No birds sing here. No insects buzz. Even the wind seems to stop at the edge of the circle.

But there's something else. In the centre of the ring, half-buried in the dirt, you can see the glint of metal. Gold, maybe. Or something older.

---

## Choices

### Choice A: "Enter the circle and investigate." (Risk/Reward)
*   **Effect:**
    *   Test **Sanity** (DC 4).
    *   **On Success:** Gain **Curio: "Ancestor Stone"** (Rare). Apply **5 Dread**. Add Tag `violated_sacred_ground`.
    *   **On Failure:** Lose **15 Sanity**. Apply **10 Dread**. Apply **3 Confusion**. Add Tag `violated_sacred_ground`. Inject Node `the_elders_judgement` into future pool.
*   **Narrative Outcome (Success):** "You step across the boundary, and the world... shifts. The colours are wrong—too bright, too sharp. The paintings on the stones are moving now, you're certain of it, telling a story in a language you almost understand. Your fingers close around the object in the dirt: a smooth stone, black as night, warm as a living thing. You pocket it quickly and retreat, but the silence follows you. It will always follow you now."
*   **Narrative Outcome (Failure):** "You step across the boundary and the sky *screams*. You fall to your knees, hands over your ears, but the sound isn't coming from outside—it's inside you, a chorus of voices older than stone, speaking in a tongue that predates language itself. When you can finally see again, you're lying outside the circle, face down in the dirt, blood leaking from your nose. You don't remember leaving. You don't remember anything. But something remembers you."

### Choice B: "Observe from outside the circle." (Safe Information)
*   **Effect:**
    *   Gain Tag `respects_the_old_ways`.
    *   Gain **3 Sanity** (the land approves).
    *   Unlock dialogue options with Indigenous NPCs.
*   **Narrative Outcome:** "You find a spot in the shade of a ghost gum and sit, watching the stones until the sun begins to set. You don't understand the paintings, but you feel them—the warning, the boundary, the ancient agreement between the people who came before and the things that live beneath. When you finally stand to leave, a crow lands on one of the stones and regards you with intelligent eyes. It bobs its head once, almost like a nod, and takes flight."

### Choice C: "Leave this place alone."
*   **Effect:**
    *   None.
    *   Continue on your way.
*   **Narrative Outcome:** "Some doors are better left closed. You skirt the edge of the circle, keeping the stones in sight until they disappear behind the scrub. The silence lifts as you walk, slowly replaced by the ordinary sounds of the bush—cicadas, wind, the distant call of a kookaburra. Whatever was buried there can stay buried."

---

## Graph Rewrites
*   **Tag Added:** `violated_sacred_ground` (Choice A), `respects_the_old_ways` (Choice B)
*   **Node Injected:** `the_elders_judgement` (Choice A Failure)
*   **Curio Gained:** "Ancestor Stone" (Choice A Success)
*   **NPC Unlocks:** Indigenous characters will react differently based on tags.
