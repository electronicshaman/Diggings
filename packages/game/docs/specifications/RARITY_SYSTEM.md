# Card Rarity System

The card rarity system defines the frequency and power level of cards found in the game, distinct from class availability.

## Rarity Tiers

| Tier | Name | Color Identity | Description | Examples |
| :--- | :--- | :--- | :--- | :--- |
| **1** | **Common** | White/Grey | Found frequently. Standard attacks, basic blocks, simple utility. Should make up ~50% of drafted decks. | *Tent Stake, Flour Sack Barrier* |
| **2** | **Uncommon** | Blue/Green | Found occasionally. Specialized tools, stronger versions of basics, or build-enabling engines. | *Steady Hands, Bark Shield* |
| **3** | **Rare** | Gold/Yellow | Found rarely. Powerful build-defining cards or high-impact one-offs. | *Midas Touch, Dead Eye* |
| **4** | **Eldritch** | Purple/Cosmic | Extremely rare. Unique, potentially game-breaking effects. Often carries a downside or high cost. | *The Motherlode, Dark Pact* |

## Drop Rates (Estimated)

- **Common:** 60%
- **Uncommon:** 30%
- **Rare:** 9%
- **Eldritch:** 1%

*Note: Elite encounters and Bosses may guarantee higher rarity drops.*

## Implementation

Rarity is defined in `CardData.gd` via the `rarity` string property.

```gdscript
@export var rarity: String = "Common" # Common, Uncommon, Rare, Eldritch
```
