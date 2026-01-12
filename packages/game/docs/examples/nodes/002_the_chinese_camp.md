# Node: The Chinese Camp

**ID:** `the_chinese_camp`
**Type:** Interaction Node (Trade/Social)
**Biome:** Goldfields / Settlement
**Prerequisites:** None

---

## Hook Text

The smell hits you first—ginger, woodsmoke, and something frying in a wok. The Chinese camp sits apart from the main diggings, a cluster of canvas tents and timber huts flying faded red banners. The troopers leave them alone, mostly. The white diggers leave them alone too, though not out of respect.

You know better. The Celestials have been here longer than the rush, and they know things about this land that the new chums will never learn. Their medicine works when the surgeon's saw fails. Their joss sticks burn in patterns that keep the night-things at bay.

An old man sits outside the largest tent, mending a fishing net with fingers that move too fast to follow. He doesn't look up as you approach, but he speaks.

"You carry something wrong with you," he says, in English that's better than most of the Cornishmen. "I can see it. A shadow that doesn't match your shape."

He gestures to a low stool across from him. "Sit. We talk business, maybe."

---

## Choices

### Choice A: "Ask about the shadow." (Information)
*   **Effect:** 
    *   Pay **5 Gold**.
    *   Reveal the player's current **Corruption** level and its effects.
    *   Gain Tag `warned_by_chen`.
*   **Narrative Outcome:** "The old man—Chen, he calls himself—takes your coin and tucks it away. He studies you with eyes that are far too sharp for his weathered face. 'The shadow grows,' he says simply. 'Each time you touch the wrong things, take the wrong paths, it grows. When it is bigger than you...' He mimes something swallowing something else. 'You understand? Be careful what you dig up, gwai lo. Some gold is not worth the darkness that comes with it.'"

### Choice B: "Buy medicine." (Healing)
*   **Effect:**
    *   Pay **10 Gold**.
    *   Restore **15 Health** OR Remove **1 Curse Card** from Deck.
*   **Narrative Outcome:** "Chen disappears into his tent and returns with a clay pot sealed with red wax. The contents smell like burnt earth and something floral you can't identify. 'Drink half now, half tomorrow,' he instructs. 'Do not ask what is inside. You would not believe me, and it would not help.' The brew tastes like someone boiled a swamp, but within minutes, you feel the ache in your bones begin to ease."

### Choice C: "Ask about protection." (Buff)
*   **Effect:**
    *   Pay **15 Gold**.
    *   Start next 3 Combats with **3 Guard** and **2 Resolve**.
    *   Add Tag `chen_ward_active`.
*   **Narrative Outcome:** "Chen produces a slip of yellow paper covered in brushwork characters. He presses it to your chest, mutters something in a dialect you don't recognise, and the paper *dissolves* into your skin with a sensation like warm water. 'Ward,' he explains. 'Old magic. The hungry things will find you harder to bite.' He pauses. 'For a time.'"

### Choice D: "Leave."
*   **Effect:** None.
*   **Narrative Outcome:** "You nod to the old man and back away. He returns to his net, fingers flying, humming a tune that sounds older than the hills themselves. You get the feeling he'll be here when the rush is over, when the towns are ghosts, when the land reclaims what was taken."

---

## Graph Rewrites
*   **Tag Added:** `warned_by_chen` (Choice A), `chen_ward_active` (Choice C)
*   **Unlocks:** If `warned_by_chen` is set, future nodes may offer alternative dialogue options.
