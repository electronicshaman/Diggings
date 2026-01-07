# Custom Resources

This document outlines the custom resources implemented for each character class in the Card Battler Prototype.

## Classes and Resources

| Class | Resource Name | Description | Mechanics |
| :--- | :--- | :--- | :--- |
| **Bushranger** | `Ammo` | Represents ammunition for firearms. | • **Gain:** Skill cards often reload/gain Ammo.<br>• **Cost:** Attack cards often consume Ammo. |
| **Preacher** | `Faith` | Represents divine favor and spiritual power. | • **Gain:** Fortune/Prayer cards gain Faith.<br>• **Effect:** Some cards have conditional effects (bonus damage/healing) based on Faith amount (e.g., "If Faith >= 3"). |
| **Prospector** | `Fever` | Represents "Gold Fever" and adrenaline. | • **Gain:** Risks and successful strikes build Fever.<br>• **Cost:** Powerful abilities or defensive stances may consume Fever to activate. |
| **Publican** | `Brew` | Represents stock of alcohol and social influence. | • **Gain:** Brewing and serving drinks increases Brew.<br>• **Cost:** Serving powerful drinks or using influence costs Brew. |
| **Tracker** | `Scent` | Represents tracking progress and primal instincts. | • **Gain:** Survival skills and preparation gain Scent.<br>• **Cost:** Precision strikes and special maneuvers consume Scent. |

## Implementation Details

### Data Structure

Custom resources are stored in `PlayerData.gd` within the `custom_resources` Dictionary.

- Key: Resource Name (String, e.g., "Ammo")
- Value: Current Amount (int)

### Card Configuration

Cards interact with custom resources via two main properties in `CardData.gd` and its effects:

1. **Costs:**
    - Property: `unique_resource_costs` (Dictionary)
    - Usage: Defines the cost to play a card.
    - Example: `{"Ammo": 1}`

2. **Effects (Gains/Spending during resolution):**
    - Resource: `ResourceEffect`
    - Property: `resource_type` (String) set to the custom resource name.
    - Usage: increments (positive amount) or decrements (negative amount) the resource.

3. **Conditions:**
    - Resource: `EffectCondition`
    - Type: `CUSTOM_RESOURCE_AMOUNT`
    - Usage: Checks the current value of a custom resource to trigger conditional effects.
