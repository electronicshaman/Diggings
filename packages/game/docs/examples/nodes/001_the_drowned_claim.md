# Node: The Drowned Claim

**ID:** `the_drowned_claim`
**Type:** Choice Node (Risk/Reward)
**Biome:** Goldfields / Creek
**Prerequisites:** None

---

## Hook Text

The creek bed hasn't seen water in months, but there's a pool here that shouldn't exist. It sits in the hollow of what was once Old Macgregor's claim—you recognise the rusted windlass, the collapsed timber frame of his shaft head. They found Macgregor three days after the Eureka boys came through, face down in six inches of mud, drowned in a creek that had been dry for a fortnight.

The pool is perfectly still. Perfectly black. The afternoon sun beats down on the ochre dirt around it, but nothing reflects off that water. No light touches it, and no flies buzz near its edge.

As you approach, you notice something glinting at the bottom. Gold, perhaps—a nugget the size of your fist, resting in the silt. Easy pickings.

The water doesn't ripple. Even when a hot wind kicks dust across the clearing, the surface remains utterly, impossibly still.

---

## Choices

### Choice A: "Reach in for the gold."
*   **Effect:** 
    *   Test **Luck**.
    *   **On Success:** Gain **25 Gold**. Add Tag `touched_the_black_water`.
    *   **On Failure:** Lose **8 Health**. Apply **5 Dread**. Add Tag `touched_the_black_water`.
*   **Narrative Outcome (Success):** "Your hand breaks the surface—cold, impossibly cold, like plunging your arm into a winter grave. Your fingers close around the nugget. You yank your arm free, gasping. The gold is real, heavy, warm from your grip. But you can't shake the feeling that something down there brushed against your knuckles. Something that was waiting."
*   **Narrative Outcome (Failure):** "Your fingers touch the nugget and something *grabs back*. A grip like iron, like the roots of a dead tree, pulling you down. You wrench free with a scream, falling back onto the cracked mud, your arm numb to the shoulder. The gold is gone. The pool is still. And you swear—just for a moment—you saw a face looking up at you from the black."

### Choice B: "Leave it. No gold is worth that."
*   **Effect:** None. Gain **2 Sanity** (from avoiding temptation).
*   **Narrative Outcome:** "You've seen enough. Macgregor was a greedy man, and greed killed him. You back away from the pool, keeping your eyes on that still, black surface until the scrub hides it from view. Some things are better left buried."

### Choice C: "Throw a stone into the pool." (Investigate)
*   **Effect:** 
    *   Inject Node `the_thing_in_the_water` into future pool (triggered if `touched_the_black_water` is set).
    *   Gain **1 Corruption**.
*   **Narrative Outcome:** "You pick up a smooth river stone and toss it into the centre of the pool. It vanishes without a splash, without a ripple. The water simply... accepts it. For a long moment, nothing happens. Then, from somewhere deep beneath the earth, you hear a sound like a sigh. Like something waking up."

---

## Graph Rewrites
*   **Tag Added:** `touched_the_black_water` (Choices A/C)
*   **Node Injected:** `the_thing_in_the_water` (Choice C only)
