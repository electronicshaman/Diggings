# Node: The Publican's Offer

**ID:** `the_publican_offer`
**Type:** Rest Node (Recovery/Trade)
**Biome:** Town / Pub
**Prerequisites:** None

---

## Hook Text

The Royal Standard is the only pub in Creswick that hasn't burned down twice, which tells you something about its publican. Mick Shaughnessy is a Cork man with forearms like hams and a face that's seen the wrong end of too many fights. He runs a clean house—clean for the goldfields, anyway—and he doesn't water his whiskey.

The common room is packed with diggers, the air thick with tobacco smoke and the smell of unwashed men. A fiddler in the corner is sawing away at something that might be "The Wild Colonial Boy," and a card game in the back has already produced one black eye and a broken chair.

Shaughnessy spots you at the door and waves you over to a quieter corner of the bar. His expression is friendly enough, but there's a calculation in his eyes. He's heard something about you, that much is clear.

"You look like you've been through it," he says, setting an unmarked bottle on the bar between you. "First drink's on the house. After that, we talk business."

---

## Choices

### Choice A: "Accept the drink and hear him out." (Information/Quest Hook)
*   **Effect:**
    *   Restore **5 Health**.
    *   Gain **2 Sanity** (the comfort of civilization).
    *   Unlock Node `shaughnessys_job` in the current region.
    *   Add Tag `knows_shaughnessy`.
*   **Narrative Outcome:** "The whiskey burns going down, but it's a clean burn, honest. Shaughnessy waits until you've finished before leaning in close. 'There's something in the old Doyle mine,' he says quietly. 'Something that's been taking men. I've lost three regulars this month—good lads, steady drinkers, not the type to wander off.' He slides a small leather pouch across the bar. 'I'll pay well for answers. Better if you can make it stop.'"

### Choice B: "Pay for a room and a meal." (Full Rest)
*   **Effect:**
    *   Pay **8 Gold**.
    *   Restore **All Health**.
    *   Restore **10 Sanity**.
    *   Remove **1 Weak** or **1 Wounded** status (if any).
*   **Narrative Outcome:** "The room upstairs is small but clean, and the bed doesn't have anything living in it that you can see. The meal is mutton stew, heavy on the potatoes, and there's fresh bread with actual butter. You eat until your stomach hurts, then climb the stairs and sleep like the dead. When you wake, the sun is high and the ache in your bones has finally eased. You feel almost human again."

### Choice C: "Ask about the local situation." (Regional Information)
*   **Effect:**
    *   Pay **2 Gold** (drinks for information).
    *   Reveal **3 Hidden Nodes** in current region.
    *   Gain Tag `pub_gossip_creswick`.
*   **Narrative Outcome:** "You buy a round for the table nearest the fire and listen. The diggers talk—they always talk, given enough drink—about the new strike at Poverty Point, about the trooper patrol that went missing near Black Hill, about the woman who walks the creek bed at night, singing songs in no language anyone recognizes. By the time the bottle's empty, you know more about this region than most men learn in a month."

### Choice D: "Just passing through."
*   **Effect:**
    *   None.
*   **Narrative Outcome:** "You nod to Shaughnessy and push back through the crowd towards the door. The publican watches you go with something like disappointment in his eyes. 'Come back if you change your mind,' he calls after you. 'My offer stands.' The noise of the pub fades as the door swings shut behind you, leaving you alone with the dust and the silence."

---

## Graph Rewrites
*   **Tag Added:** `knows_shaughnessy` (Choice A), `pub_gossip_creswick` (Choice C)
*   **Node Unlocked:** `shaughnessys_job` (Choice A)
*   **Map Revealed:** 3 Hidden Nodes (Choice C)
