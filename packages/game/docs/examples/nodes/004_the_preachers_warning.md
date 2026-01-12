# Node: The Preacher's Warning

**ID:** `the_preachers_warning`
**Type:** Choice Node (Thematic - Western Religion)
**Biome:** Town / Road
**Prerequisites:** `Corruption > 3`

---

## Hook Text

He stands in the middle of the track, a scarecrow figure in a black coat gone grey with dust. His Bible is clutched to his chest like a shield, and his eyes—Lord, his eyes are the eyes of a man who has seen the Pit and climbed back out.

"You there!" His voice cracks across the stillness like a whip. "You who walk with the shadow at your heels!"

The other travellers give him a wide berth, hurrying past with their heads down. You've seen his type before—the goldfields are full of hellfire preachers, men driven mad by the sun and the silence. But this one looks at you, *really* looks at you, and you feel something cold settle in your stomach.

"I know what rides your back," he says, quieter now, stepping closer. His breath smells of communion wine and desperation. "I can see it. The stain. It's eating you from the inside, friend. Eating your soul."

He holds out a crude wooden cross, hand-carved and stained with something that might be blood.

"Let me help you. Before it's too late."

---

## Choices

### Choice A: "Accept his blessing." (Cleansing)
*   **Effect:**
    *   Remove **3 Corruption**.
    *   Lose **5 Gold** (donation to the church).
    *   Gain **5 Resolve**.
    *   Add Tag `blessed_by_preacher`.
*   **Narrative Outcome:** "You kneel in the red dust of the track while the preacher speaks words older than the colony, older than the Empire. His hand on your head is feverishly warm, and for a moment—just a moment—you feel something *lift* from your shoulders. Like a weight you'd forgotten you were carrying. When you stand, the world seems brighter. The shadows seem shorter. The preacher smiles, and for an instant, his eyes look almost sane."

### Choice B: "Ask him what he knows." (Information)
*   **Effect:**
    *   Gain Tag `knows_of_the_awakening`.
    *   Lose **2 Sanity** (the truth is heavy).
*   **Narrative Outcome:** "'They're waking up,' he whispers, leaning close enough that you can see the broken veins in his eyes. 'The old things. The hungry things. Every shaft we dig, every nugget we pull from the earth—we're disturbing their sleep. The blacks knew. They kept the songs that held them down. But we broke the songs, didn't we? We broke everything.' He laughs, a sound like breaking glass. 'Revelations, friend. The seals are opening. And we're the ones who broke them.'"

### Choice C: "Push past him."
*   **Effect:**
    *   Gain **1 Corruption** (rejecting the divine).
    *   Continue on your way.
*   **Narrative Outcome:** "You shoulder past the preacher without a word. His hand claws at your sleeve, but his grip is weak, the grip of a man who's been living on faith and creek water. 'It's not too late!' he calls after you. 'It's never too late!' But you're already walking, and you don't look back. You tell yourself you don't believe in any of it. You tell yourself the cold feeling in your chest is just the wind."

---

## Graph Rewrites
*   **Tag Added:** `blessed_by_preacher` (Choice A), `knows_of_the_awakening` (Choice B)
*   **Corruption Modified:** -3 (Choice A), +1 (Choice C)
*   **Unlocks:** If `knows_of_the_awakening` is set, new dialogue options appear with Tracker and Indigenous NPCs.
