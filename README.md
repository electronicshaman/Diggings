# Diggings

Monorepo for **The Diggings & The Void**.

## Packages

- `packages/game` — Godot game project (formerly card-battler-prototype)
- `packages/atlas` — Narrative node tooling (formerly node-gen-web)

## Active milestone

The active milestone is the deterministic curated three-fight mini-run. New
Game takes static class selection into three fights, with a card-or-recovery
choice after each of the first two fights, ending in a summary. Quick Duel
remains available as a single-fight developer sandbox. Canonical design:
[`docs/superpowers/specs/2026-07-12-core-game-recovery-design.md`](docs/superpowers/specs/2026-07-12-core-game-recovery-design.md).

## Quick start

### Game
Open in Godot:
```
packages/game/src/project.godot
```

## Frozen tooling

Atlas (narrative node tooling), content-kit, generated narrative JSON, the
narrative runtime, maps, shops, and saving are frozen and not part of the
active milestone.

```bash
pnpm install
pnpm dev:atlas
```

## Docs
See `/docs` for the canonical documentation set.
