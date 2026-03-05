# Forge — Export Contract (Draft)

Exports are **neutral JSON bundles** written to `/exports`.

## Folder Layout
```
/exports/
  cards.json
  curios.json
```

## cards.json
```json
{
  "version": 1,
  "generatedAt": "2026-03-05T00:00:00Z",
  "cards": [
    {
      "id": "CRD_ATK_001",
      "name": "Bayonet Rush",
      "cardType": "Attack",
      "rarity": "Common",
      "costs": [{ "type": "energy", "amount": 1 }],
      "effects": [
        { "handlerId": "damage", "params": { "amount": 6 } }
      ],
      "description": "",
      "cardOwner": "PLAYER",
      "handling": "Standard",
      "classAffinity": [],
      "accessibilityTier": "Neutral"
    }
  ]
}
```

## curios.json
```json
{
  "version": 1,
  "generatedAt": "2026-03-05T00:00:00Z",
  "curios": [
    {
      "id": "CUR_COM_001",
      "name": "Worn Bible",
      "rarity": "Common",
      "mechanicalCategory": "Passive",
      "description": "",
      "stackable": false,
      "maxStacks": 1,
      "effects": [
        {
          "effectId": "stat_modifier",
          "triggerEvent": "passive",
          "params": { "stat": "faith", "amount": 1 }
        }
      ]
    }
  ]
}
```

## Notes
- Versioned for future schema evolution.
- Exporters should validate against Forge schemas before writing.
- Importers in Godot will transform JSON into `.tres` resources.
