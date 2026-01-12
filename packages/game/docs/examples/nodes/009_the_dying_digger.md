# Node: The Dying Digger

**ID:** `the_dying_digger`
**Type:** Choice Node (Moral/Resource)
**Biome:** Goldfields / Any
**Prerequisites:** None

---

## Hook Text

You smell him before you see him—blood and infection and the sickly sweetness of gangrene. He's propped against a dead gum tree, one leg twisted at an angle that makes your stomach turn. A mining accident, maybe. A claim-jumper's bullet, more likely. The red stain on his shirt has long since dried brown.

He's young—can't be more than twenty, fresh off the boat from somewhere cold judging by his pale skin and the wool coat that's far too heavy for this heat. His eyes find you as you approach, and there's a terrible clarity in them. He knows he's dying. He's just waiting for it to happen.

"Water," he croaks. "Please. I have gold. I'll pay."

He fumbles at a pouch on his belt with fingers that won't stop shaking. There's gold in there, you can see the glint of it. Probably everything he's earned since he stepped off the ship at Geelong.

The sun beats down. The flies are already circling.

---

## Choices

### Choice A: "Give him water and stay with him." (Mercy)
*   **Effect:**
    *   Lose **1 Supplies** (if any) OR Lose **5 Health** (dehydration).
    *   Gain **5 Sanity** (human connection).
    *   Gain **15 Gold** (his gratitude).
    *   Add Tag `showed_mercy`.
    *   Skip one travel node (time spent).
*   **Narrative Outcome:** "You kneel beside him and hold your canteen to his lips. He drinks greedily, water spilling down his chin, and when he's done he grips your hand with surprising strength. 'Thomas,' he says. 'My name's Thomas Brennan. From Cork.' He talks while the light fades from his eyes—about his mother, about the girl he left behind, about the fortune he was going to find and the man he was going to become. You stay until the talking stops. Then you close his eyes, pocket his gold, and dig a grave that's probably too shallow. It's all you can do."

### Choice B: "Take his gold and leave." (Pragmatism)
*   **Effect:**
    *   Gain **20 Gold**.
    *   Gain **2 Corruption**.
    *   Lose **3 Sanity** (guilt).
    *   Add Tag `abandoned_dying_man`.
*   **Narrative Outcome:** "You tell yourself there's nothing you can do. You tell yourself he's dead already, just doesn't know it yet. You tell yourself a lot of things as you pull the pouch from his belt and walk away. He calls after you—pleading at first, then cursing, then just making sounds that aren't words anymore. The sounds stop eventually. The silence that follows is worse."

### Choice C: "End his suffering quickly." (Dark Mercy)
*   **Effect:**
    *   Gain **15 Gold**.
    *   Lose **5 Sanity** (the weight of the act).
    *   Add Tag `mercy_killer`.
    *   If `Class: Preacher`: Gain **3 Resolve** instead of losing Sanity.
*   **Narrative Outcome:** "His eyes meet yours, and something passes between you—an understanding, maybe. A request. 'Thank you,' he whispers, and you're not sure if he's thanking you for what you're about to do or for stopping to look at him at all. It's over quickly. Cleaner than the alternative. You take his gold because someone will, and you walk away with the taste of copper in your mouth and a new weight on your shoulders."

### Choice D: "Search him for supplies and leave."
*   **Effect:**
    *   Gain **20 Gold**.
    *   Gain **1 Random Card** (from his pack).
    *   Gain **3 Corruption**.
    *   Add Tag `robbed_dying_man`.
*   **Narrative Outcome:** "You go through his pockets with efficient, practiced hands. Gold. A folding knife. A letter addressed to someone named Mary, creased soft from reading. You take everything useful and leave the rest. He's still breathing when you walk away, but that's not your problem. Nothing out here is your problem except survival. The flies descend before you're out of earshot."

---

## Graph Rewrites
*   **Tags Added:** Various based on choice (affects future NPC reactions, possible haunting events).
*   **Note:** If `abandoned_dying_man` or `robbed_dying_man` is set, inject Node `the_diggers_ghost` into future pool (low probability).
*   **Preacher Class:** Alternative mechanical outcome for Choice C.
