# Node: The Collapsed Tunnel

**ID:** `the_collapsed_tunnel`
**Type:** State Check Node (Passive/Branching)
**Biome:** Deep Mine
**Prerequisites:** `Region: Underground`

---

## Hook Text (Low Corruption - Default)

The tunnel ahead has caved in—not recently, judging by the dust that's settled over the rubble. A few rotted timber props stick out of the debris like bones. Someone made an attempt to shore things up before the roof came down, but the goldfields don't forgive half-measures.

You can hear water dripping somewhere on the other side of the collapse. The air that seeps through the gaps in the rubble is cool and carries a faint mineral smell. There might be a way through if you're willing to dig, but it'll take time and make noise.

A pickaxe leans against the tunnel wall nearby. Someone left it here. Someone who didn't come back for it.

---

## Hook Text (High Corruption - Alternate)

The tunnel ahead has caved in, but something's wrong with the rubble. The rocks are too smooth, too regular, fitted together like scales on some vast sleeping thing. And they're warm to the touch—warm like skin, warm like something alive.

You can hear sounds from the other side. Not water dripping. Something breathing. Slow, deep breaths that make the dust dance in the air. The gaps between the stones are dark, darker than they should be, and when you lean close, you could swear you see something *looking back*.

A pickaxe leans against the tunnel wall nearby. Its head is covered in a black substance that isn't rust.

---

## State Check Logic

```
IF Corruption >= 7:
    Display "High Corruption" text.
    Apply 3 Dread (passive exposure).
    Enable Choice D.
ELSE:
    Display "Low Corruption" text.
    Disable Choice D.
```

---

## Choices

### Choice A: "Dig through the rubble." (Standard Path)
*   **Effect:**
    *   Test **Strength**.
    *   **On Success:** Clear the passage. Continue to next mine node. Lose **3 Health** (exertion).
    *   **On Failure:** Partial collapse. Lose **8 Health**. Apply **2 Wounded**. Passage still cleared.
*   **Narrative Outcome (Success):** "You attack the rubble with the pickaxe, muscles burning, sweat dripping into your eyes. Stone by stone, timber by timber, you clear a gap wide enough to crawl through. On the other side, the tunnel continues, sloping downward into darkness. The air is cooler here, and you allow yourself a moment's rest before pressing on."
*   **Narrative Outcome (Failure):** "You're halfway through the rubble when something shifts above you. You throw yourself forward as more of the roof comes down, rocks hammering your back and legs. You drag yourself clear, coughing dust, blood running from a gash on your shoulder. But you're through. You're through, and you're not going back."

### Choice B: "Look for another route."
*   **Effect:**
    *   Inject Node `the_narrow_crevice` into immediate path.
    *   Bypass this obstacle.
*   **Narrative Outcome:** "There's more than one way to skin a cat, as your old man used to say. You retreat down the tunnel, lantern raised, searching for side passages you might have missed. It takes time, but eventually you find it—a crack in the wall, barely wide enough to squeeze through. It's not comfortable, but it beats digging."

### Choice C: "Turn back."
*   **Effect:**
    *   Exit the mine. Return to surface map.
*   **Narrative Outcome:** "The goldfields are full of collapsed tunnels and dead ends. No shame in knowing when you're beaten. You retrace your steps, climbing back towards the light, the weight of the earth pressing down on you until you finally emerge into the harsh sunlight. The sky has never looked so welcoming."

### Choice D: "Touch the breathing stones." (High Corruption Only)
*   **Effect:**
    *   Gain **1 Corruption**.
    *   Gain **Curio: "Pulsing Fragment"** (Corrupted Rare).
    *   Apply **5 Dread**.
    *   Inject Node `the_awakened_passage` into immediate path (hostile).
*   **Narrative Outcome:** "Your hand moves before you can stop it, drawn to the warm, smooth surface of the stone. The moment you touch it, the breathing *stops*. The silence is deafening. And then, slowly, horribly, the stones begin to *move*, sliding apart like an opening eye. Beyond is darkness, and in the darkness, something is waiting. Something that knows you now."

---

## Graph Rewrites
*   **State-Dependent:** Text and choices change based on Corruption level.
*   **Node Injected:** `the_narrow_crevice` (Choice B), `the_awakened_passage` (Choice D)
*   **Curio Gained:** "Pulsing Fragment" (Choice D)
