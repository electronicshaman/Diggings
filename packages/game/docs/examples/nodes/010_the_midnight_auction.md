# Node: The Midnight Auction

**ID:** `the_midnight_auction`
**Type:** Choice Node (Trade/Corruption)
**Biome:** Town
**Prerequisites:** `Time: Night`, `Gold > 30`

---

## Hook Text

The note was slipped under your door sometime after midnight—a single line in handwriting that seemed to shift when you looked at it too long:

*"The Exchange. Third bell. Come alone."*

You know The Exchange. Everyone does, though nobody talks about it. An abandoned woolshed on the edge of town where certain transactions take place—the kind that don't bear the scrutiny of daylight or decent folk.

The third bell finds you at the shed's sagging doors. Inside, lanterns cast pools of sickly yellow light over a crowd of perhaps two dozen people. You recognise some of them—the assayer from Ballarat, a magistrate's clerk, a woman who runs the boarding house on Chapel Street. None of them meet your eyes.

At the centre of the shed stands a figure in a coat that seems to drink the light. Its face is hidden in shadow, but its voice carries clearly when it speaks.

"Welcome, seekers. Tonight's lots are... special. As always, payment is flexible. Gold. Services. Other currencies." The shadow shifts, and you could swear it's smiling. "Shall we begin?"

---

## Lots Available

### Lot A: "The Cartographer's Eye" (Curio)
*   **Starting Bid:** 25 Gold
*   **Effect:** Gain **Curio: "Cartographer's Eye"** - Reveals all nodes in current region. Passive: +1 Corruption per region entered.
*   **Narrative:** "A glass eye, preserved in amber liquid that glows faintly violet. 'Belonged to a surveyor,' the auctioneer explains. 'He mapped places that don't exist. Or didn't exist, until he drew them. Very useful for finding things that don't want to be found.'"

### Lot B: "The Surgeon's Tonic" (Consumable)
*   **Starting Bid:** 15 Gold
*   **Effect:** Gain **3x "Surgeon's Tonic"** - Restore 20 Health. Apply 2 Dread.
*   **Narrative:** "Three bottles of murky liquid that seems to move on its own. 'Heals anything,' the auctioneer promises. 'Bullet wounds, broken bones, diseases that don't have names yet. Side effects are... manageable.'"

### Lot C: "A Name" (Information)
*   **Starting Bid:** 40 Gold OR 5 Corruption (your choice)
*   **Effect:** Gain Tag `knows_the_patrons_name`. Unlocks hidden dialogue and quest lines related to the cult.
*   **Narrative:** "No item is presented. The auctioneer simply waits. 'Knowledge,' it explains, 'of the one who stirs beneath the ranges. Useful for those who wish to bargain. Dangerous for those who do not understand the terms.'"

### Lot D: "The Escape" (Leave Safely)
*   **No Cost**
*   **Effect:** Leave the auction. Gain **2 Sanity** (relief). Add Tag `declined_the_exchange`.
*   **Narrative:** "You can leave at any time, of course. The door is right there. But you'll always wonder what you missed. And the invitation won't come again."

---

## Special Rules

*   **Bidding War:** If the player bids on Lot A, B, or C, there's a 50% chance another bidder challenges. The player can:
    *   **Outbid:** Pay 50% more Gold.
    *   **Intimidate:** Test Strength/Charisma. Failure means paying 50% more OR gaining 2 Corruption (the auctioneer "settles" the dispute).
    *   **Withdraw:** Lose the lot.

---

## Narrative Outcomes

### If Player Wins Multiple Lots:
"The auctioneer seems pleased—or as pleased as something without a visible face can seem. 'A discerning collector,' it murmurs as it hands over your purchases. 'We shall meet again, I think. The Exchange always finds those who have... appetites.' The crowd parts as you leave, and nobody quite looks at you directly."

### If Player Leaves Without Buying:
"You slip out the door before the next lot is called. The night air is cool against your skin, and for a moment, you feel almost clean. But there's a weight in your pocket—the invitation, which you're certain you left on your bedside table. It's warm to the touch, and the handwriting has changed: *'Next time.'*"

---

## Graph Rewrites
*   **Tags Added:** Various based on purchases and choices.
*   **Curios Gained:** "Cartographer's Eye" (Lot A)
*   **Items Gained:** "Surgeon's Tonic" x3 (Lot B)
*   **Unlocks:** If `knows_the_patrons_name` is set, new story branches become available.
*   **Recurring:** If player attends, inject `midnight_auction_return` into future pool (different lots).
