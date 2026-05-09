# Forge — Schema MVP (Draft)

This draft mirrors **game source-of-truth** fields from `packages/game/src/scripts/cards/card_data.gd` and `packages/game/src/scripts/data/curio_data.gd`.

## Card (MVP)

**Source:** `packages/game/src/scripts/cards/card_data.gd`

Required fields for schema-valid, playable cards:

```ts
Card = {
  id: string;                // Forge ID
  name: string;              // card_name
  description: string;       // description
  cardType: "Attack"|"Skill"|"Power"|"Fortune"|"Hex"|"Curse";
  costs: CardCost[];         // costs[] (energy/sanity/resource)
  effects: EffectRef[];      // effects[] using HandlerRegistry effect IDs
  rarity: "Common"|"Uncommon"|"Rare"|"Eldritch";
  cardOwner: "PLAYER"|"ENEMY"|"NEUTRAL";
  handling: "Standard"|"Equipped"|"Flash"|"Keep"|"Hold"|"Oneshot";
  classAffinity: string[];   // empty = all
  accessibilityTier: "Starting"|"Class"|"Neutral"|"Rare";

  // Optional/advanced
  flavorText?: string;
  baseDurability?: number;   // -1 infinite
  volatileBonus?: boolean;
  luckModifier?: number;
  enemyFaction?: string;     // if ENEMY
}
```

### CardCost (MVP)
- `type`: "energy" | "sanity" | "resource"
- `amount`: number
- `resourceKey`?: string (for class resource like Ammo/Fever)

### EffectRef (MVP)
- `handlerId`: string  *(maps to HandlerRegistry effect types)*
- `params`: Record<string, any>

---

## Curio (MVP)

**Source:** `packages/game/src/scripts/data/curio_data.gd`

```ts
Curio = {
  id: string;
  name: string;              // curio_name
  description: string;
  rarity: "Common"|"Rare"|"Legendary"|"Corrupted";
  mechanicalCategory: "Passive"|"Triggered"|"Modifier"|"Resource";
  effects: CurioEffectRef[]; // modular effects
  stackable: boolean;
  maxStacks: number;

  // Optional/advanced
  flavorText?: string;
  corruptionCost?: number;
  goldCost?: number;
  unlockRequirement?: string;

  // Class synergy (optional)
  synergy?: {
    bushranger?: number;
    prospector?: number;
    tracker?: number;
    publican?: number;
  };
}
```

### CurioEffectRef (MVP)
- `effectId`: string *(maps to CurioEffect subclasses / HandlerRegistry as needed)*
- `triggerEvent`: string *(from CurioEffect.trigger_event enum)*
- `params`: Record<string, any>
- `onlyFirstPerCombat?`, `onlyFirstPerTurn?`, `chanceToTrigger?`

---

## Notes
- **Forge should not invent effect identifiers.** It must use **HandlerRegistry** effect IDs from the game.
- **Schema here is the authoring layer**; game importers can adapt to Godot `.tres` resources.
- We can extend with art references later (icon paths, etc.).
