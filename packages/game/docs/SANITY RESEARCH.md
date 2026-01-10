<img src="https://r2cdn.perplexity.ai/pplx-full-logo-primary-dark%402x.png" style="height:64px;margin-right:32px"/>

# generate a markdown document of the findings

Here is a concise, clean markdown document you can drop straight into your repo or wiki.

***

# Integrating Call of Cthulhu–Style Cosmic Horror into **The Rush**

*A design research summary for an Australian Gold Rush roguelite deckbuilder in Godot 4.5, inspired by Call of Cthulhu and Lovecraftian cosmic horror.*

***

## 1. Call of Cthulhu Sanity: Key Lessons

Call of Cthulhu 7e treats **Sanity (SAN)** as a tracked resource that fluctuates in response to “sanity-threatening situations,” using d100 rolls and thresholds to gate effects.[^1][^2]

### 1.1 Core SAN Structure

- **Active Sanity Loss**
    - Sanity rolls (1D100 vs current SAN) when facing horrors; failure causes a specified SAN loss.[^1]
    - Multiple horrors in one scene often share a single roll (e.g. several ghouls = one SAN roll).[^1]
- **Temporary Insanity**
    - If an investigator loses **5+ SAN in a single roll**, the Keeper calls for an INT roll.[^1]
    - Succeeding the INT roll means understanding what was seen and triggers temporary insanity; the mind can no longer repress it.[^1]
    - During a “bout of madness” (1D10 rounds or longer), the investigator cannot lose further SAN and acts involuntarily.[^1]
- **Indefinite Insanity**
    - Losing **20% or more of current SAN in a “day”** can cause longer-term, indefinite insanity with lasting delusions.[^1]
    - Recovery is slow and structured (therapy, time, etc.), often outside normal scenario scope.[^1]


### 1.2 Genre Pillars of Cosmic / Lovecraftian Horror

Lovecraftian (cosmic) horror emphasizes:[^3][^4]

- **Fear of the unknown and unknowable**, with horror rooted in realization rather than intrusion.
- **Cosmic insignificance**, where human morals and concerns are meaningless at cosmic scale.
- **Forbidden knowledge**, which is inherently dangerous and damages sanity when understood.
- **Madness and unstable perception**, where reality and dreams or hallucinations blur.
- **Illusory surface appearances**, hiding a more terrible, objective reality beneath.[^4][^3]

Haahr’s analysis of Lovecraftian horror in games highlights tensions between genre and game design: agency vs powerlessness, victory vs cosmic insignificance, visible mechanics vs unknowable horror.[^3]

***

## 2. Mapping CoC Sanity to a Card Battler

### 2.1 Three-Tier Sanity Model for The Rush

Use a **three-tier SAN architecture** directly inspired by CoC:[^2][^1]

1. **Active Drain (High SAN – 75–100%)**
    - SAN lost when:
        - Eldritch cards are played (yours or enemy’s).
        - Void events or locations trigger.
        - Cursed Curios activate.
    - Each meaningful SAN loss:
        - Adds **Corruption Status** cards to your deck.
        - Reduces effective **max hand size** or energy for the rest of the run.
2. **Temporary Madness (Mid SAN – below ~50%)**
    - Trigger conditions:
        - Drop below 50% SAN.
        - Or lose ≥ a threshold (e.g. 5–10 SAN) in a single event.
    - Effects for 2–3 turns:
        - Player loses control; AI plays random cards from hand.
        - Enemy cannot target you or deals reduced damage (you are “beyond” normal threat).
        - No further SAN loss during this bout, echoing CoC’s protection during madness.[^1]
3. **Indefinite Insanity (Low SAN – 0% or catastrophic loss)**
    - Trigger conditions:
        - SAN reaches 0.
        - Or lose a very large percentage (e.g. 30%) in one turn.
    - Effect:
        - Run ends: character is committed or disappears into the Void.
        - Logged outcome type: *Madness* rather than simple death.

### 2.2 Mythos Insight: Dangerous Knowledge

Borrow CoC’s **Cthulhu Mythos skill** concept, where higher Mythos reduces maximum SAN.[^2][^1]

Design **Mythos Insight** as a separate, persistent stat:

- Gain Mythos Insight when:
    - Defeating eldritch enemies.
    - Reading forbidden tomes / using specific Curios.
    - Surviving particularly warped events.
- Milestone penalties:
    - At, say, 10 Insight: max SAN −10.
    - At ~25 Insight: max SAN −20 and SAN loss is slightly amplified.
    - At ~50 Insight: max SAN −30 and unlock a passive like “Reality Waning” (enemy intents or your UI become unreliable).

This preserves the **“knowledge is a curse”** theme: becoming more competent against eldritch threats makes stability permanently worse.[^4][^3]

***

## 3. Deck Pollution as Eldritch Corruption

### 3.1 Status vs Curse as Mental States

Your Status and Curse archetypes are ideal metaphors for **temporary terror** vs **lasting corruption**.

- **Status (Temporary Madness)**
    - Added by combat events; auto-removed afterward.
    - Represents short-lived panic, confusion, or shock.
    - Examples:
        - *Shell Shock*: This turn you cannot play Attack cards.
        - *Spiraling Thoughts*: All cards cost +1 energy this turn.
- **Curse (Persistent Corruption)**
    - Added by locations, Curios, bosses.
    - Persists across combats unless explicitly removed.
    - Embodies long-term mental scars or Void-touched artifacts.
    - Examples:
        - *The Watcher*: Every X turns, enemy gets a free small attack.
        - *Creeping Void*: Permanently increases deck size, bloat with no benefit.
        - *Price Paid*: Whenever you gain energy, lose SAN instead.


### 3.2 Viral \& Unstable Modifiers as Contagion

Leverage your planned digital-only modifiers:[^5]

- **Viral**:
    - When played, spawns a copy (or evolves into more copies) in your deck.
    - Represents corruption spreading like an infection.
- **Unstable**:
    - Effect or value fluctuates unpredictably (e.g. 2–10 damage to self/enemy).
    - Combines with SAN to express reality breakdown.

In late runs, the deck visually and mechanically reflects the character’s mental state: **more corruption, less reliability, more risk.**

***

## 4. Sanity as Information, Not Just Hit Points

Haahr notes that cosmic horror struggles with the need for clear mechanics vs unknowable reality. A strong solution in a card game is to let **SAN affect how much truthful information the player sees.**[^3]

### 4.1 Enemy Intent Visibility (“Sanity Fog”)

Tie enemy telegraphs to both **encounter familiarity** and **current SAN**:

- **By familiarity (learning):**
    - 1st time vs an enemy type: intents hidden (`???`).
    - 2nd time: show only rough type (Attack/Block/Hex icon).
    - 3rd+ time: show full damage/effect numbers.
- **By SAN:**
    - Above ~75% SAN: use full familiarity rules.
    - Below ~50% SAN: always downgrade one level of clarity (numbers hidden or icons only).
    - Below ~25% SAN: show nothing reliable—everything appears as `???`.

This reconciles **player mastery** (learning patterns) with **Lovecraftian uncertainty** (low sanity obscures even learned truths).[^4][^3]

### 4.2 Card Text and Values Warping

At low SAN, the UI itself can lie:

- Display wrong damage or block values on cards with a small chance.
- Mark uncertain values with a subtle glyph (`8 [?]`).
- Offer a **“Reality Check”** action:
    - Spend 1 SAN to reveal *true* values for this turn.
    - This trades mental stability for perfect information, echoing “the terrible cost of understanding.”[^3][^4]

***

## 5. Cosmic Horror within the Gold Rush Theme

Cosmic horror here sits in tension with the **1850s Australian goldfields**, leveraging Outback Gothic–style imagery.

### 5.1 The Mundane vs The Void

- **Mundane Gold Rush:**
    - Tools: pickaxe, pan, shovel, revolver, lamp, tent.
    - Hardships: heat, flies, thirst, debt, bushrangers.
    - Social spaces: the claim, the creek, the pub, the assay office.
- **Eldritch Intrusions:**
    - Gold veins that glow wrong or whisper.
    - Pits where the night sky is visible at noon.
    - Fossils that don’t match any known creature.
    - Songs in the wind that repeat in your dreams.

Cosmic horror in this setting should feel like **the Outback itself is the first Great Old One**—vast, indifferent, incomprehensible, and only partly mapped.

### 5.2 Encounter \& Enemy Concepts

Use hybrid enemies that start grounded and slide into the surreal:

- **The Digger**
    - Starts as a rival prospector; only later revealed as twisted or puppet-like.
    - Mechanically: predictable, escalating attack–buff pattern the player learns, but becomes more erratic as SAN drops.
- **The Claim-Broker**
    - A merchant offering unfair deals on land and Curios.
    - Mechanically: trades immediate power for SAN or permanent curses.
- **The Singing Chasm**
    - Location-boss: a mine-shaft that drops into a star-filled void.
    - Can only be “sealed,” not killed; normal damage is ineffective.

This aligns with Lovecraft’s focus on **illusory surface appearances** and deeper realities.[^4][^3]

***

## 6. Narrative \& Ending Structures

Lovecraftian horror often resists clean heroism or catharsis, emphasizing bleak realizations and fragmented fates. In a roguelite, you can express this through **run outcomes**:[^3][^4]

- **Escape:** You abandon your claim and return to Melbourne; you survived, but your journal hints at recurring nightmares.
- **Hollow Victory:** You seal a breach, but your SAN is shattered and you end in an asylum.
- **Transformation:** High Mythos Insight + success; you join the Void or become its agent—“victory” in cosmic terms, not human.
- **Madness:** SAN reaches 0; the run ends abruptly with distorted UI and a brief text fragment.

This lets players “win” in multiple ways while preserving themes of **insignificance, madness, and unwholesome survival.**[^4][^3]

***

## 7. Practical Integration Roadmap (High Level)

1. **Sanity Core**
    - Implement SAN as a tracked resource with:
        - Threshold triggers (~75/50/25/0%).
        - Corruption card injection at each threshold.
        - Temporary Madness bouts with loss of control.
2. **Mythos Insight Track**
    - Add a persistent “knowledge” meter:
        - Gained from eldritch encounters.
        - Reduces max SAN at milestones.
3. **Information Corruption**
    - Tie SAN and familiarity to:
        - Enemy intent visibility.
        - Accuracy of card values.
        - Occasional hallucinated UI / false telegraphs.
4. **Deck Corruption \& Curios**
    - Use Status/Curse, Viral, Unstable to depict spreading madness.
    - Curios that:
        - Grant powerful benefits.
        - Carry SAN or Mythos costs long-term.
5. **Gold Rush Theming**
    - Reskin all core beats—cards, enemies, events—to sit at the collision of:
        - Frontier greed and desperation.
        - Lovecraftian cosmic dread.

***

## 8. Design Alignment with Cosmic Horror Research

- **Agency vs Powerlessness:**
Players can win combats and runs, but SAN and Mythos ensure that **victory feels costly**, not triumphant.[^3][^4]
- **Knowable Mechanics vs Unknowable Horror:**
Core rules remain readable, while **perception (UI and information)** becomes unreliable at low SAN, capturing horror in realization, not randomness.[^3][^1]
- **Short Run Structure vs Dread Arc:**
30–45 minute runs map neatly to a rising dread curve: curiosity → unease → panic → revelation or collapse.[^5][^3]

***

You can paste this whole document directly into a `cosmic_horror_research.md` or similar file in your project. If you want, a follow-up can focus purely on card names/effects or on Godot-specific implementation notes.
<span style="display:none">[^10][^11][^12][^13][^14][^15][^16][^6][^7][^8][^9]</span>

<div align="center">⁂</div>

[^1]: https://trpgline.com/rules/coc7/sanity

[^2]: https://cthulhuwiki.chaosium.com/rules/sanity.html

[^3]: https://www.scss.tcd.ie/mads.haahr/papers/haahr-icids-2023.pdf

[^4]: https://wikipedia.nucleos.com/viewer/wikipedia_en_all_maxi_2025-08/Lovecraftian_horror

[^5]: high_level_summary.md

[^6]: https://www.youtube.com/watch?v=dzgLwA_LZrc

[^7]: https://www.youtube.com/watch?v=6qmdVBgknSA

[^8]: https://www.reddit.com/r/callofcthulhu/comments/11l1lws/sanity_loss_and_rounding_in_7e/

[^9]: https://www.youtube.com/watch?v=aPGXdRUNPqo

[^10]: https://www.scss.tcd.ie/Mads.Haahr/papers/haahr-icids-2023.pdf

[^11]: https://www.reddit.com/r/Lovecraft/comments/abzpdc/can_someone_explain_to_me_what_lovecraft_horror/

[^12]: https://www.youtube.com/watch?v=5XKuf_LSilA

[^13]: https://www.reddit.com/r/gamedesign/comments/htayoe/capturing_lovecraftian_horror_in_games/

[^14]: https://lovecraft.fandom.com/wiki/Lovecraftian_Horror

[^15]: https://www.chaosium.com/content/FreePDFs/CoC/CHA23131 Call of Cthulhu 7th Edition Quick-Start Rules.pdf

[^16]: https://ouci.dntb.gov.ua/en/works/4bwMY61l/

