# Forge — ID Scheme (Draft)

Goal: deterministic, sortable, collision‑safe IDs that are human‑readable.

## Proposed IDs

### Cards
`CRD_{TYPE}_{NNN}`

Examples:
- `CRD_ATK_001`
- `CRD_SKL_014`
- `CRD_POW_003`
- `CRD_FOR_007`
- `CRD_HEX_004`
- `CRD_CUR_002`

### Curios
`CUR_{RARITY}_{NNN}`

Examples:
- `CUR_COM_001`
- `CUR_RAR_006`
- `CUR_LEG_002`
- `CUR_COR_003`

## Prefix Map
- **ATK** Attack
- **SKL** Skill
- **POW** Power
- **FOR** Fortune
- **HEX** Hex
- **CUR** Curse

- **COM** Common
- **RAR** Rare
- **LEG** Legendary
- **COR** Corrupted

## Rules
- IDs are **assigned at creation** and never change.
- Forge will scan existing IDs per category and assign next available sequence.
- Avoid UUIDs for content — readability matters for designers.
