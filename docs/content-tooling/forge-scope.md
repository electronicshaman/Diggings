# Forge — Phase 0 Scope (MVP)

**Purpose:** Atlas‑style authoring system for **Cards + Curios** with minimal‑input bulk generation and JSON export.

## MVP Requirements (Day 1)
- **CRUD** for Cards
- **CRUD** for Curios
- **Bulk skeleton generation** (no LLM required)
- **JSON export**

## Schema Baseline
- **Cards:** match existing game schema (single source of truth)
- **Curios:** match existing game schema (single source of truth)
- **Effects:** reuse existing **HandlerRegistry** effect IDs

## Distribution Targets
Forge will maintain a **distribution matrix** (by rarity + type) similar to Atlas.

## ID Format
No fixed preference. We’ll pick a clean, modern convention (deterministic, sortable, collision‑safe).

## Export Contract
- **Export location:** neutral `/exports` folder (not directly into `/packages/game`)
- **Format:** JSON bundles for cards + curios

---

## Immediate Next Steps
1) **Extract game schemas** for cards + curios (source of truth)
2) **Define Forge schema MVP** (Card/Curio Zod + types)
3) **Design distribution matrix** (rarity × type)
4) **Define ID convention** (proposal + approval)
5) **Draft export schema** (JSON contract)
