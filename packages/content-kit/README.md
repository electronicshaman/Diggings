# Content Kit

Pipeline tooling for generating narrative content from lore-trained prompts into Godot-readable JSON node files.

## Directory structure

```
packages/content-kit/
  prompts/              # LLM prompt templates for each pipeline stage
    act-tones.md        # Tone and voice guidance per act/biome
    beat-outliner.md    # Beat outline generation prompt
    critic.md           # Critic/review pass prompt
    exemplars.md        # Example nodes for few-shot prompting
    prose-expander.md   # Prose expansion prompt (beats → full text)
    vernacular.md       # Period-appropriate language reference

  rules/                # Generation constraints and game mechanics
    beat-sequences.md   # Valid beat ordering rules
    biomes.md           # Biome definitions and transitions
    card-handlers.md    # Card effect handler mapping
    defaults.md         # Default values for generated fields
    distributions.md    # Probability distributions for random elements
    eligibility.md      # Node type eligibility per biome/context
    lookup-data.md      # Reference data tables

  schemas/              # JSON schema definitions and style guides
    beat-sequences.md   # Beat sequence schema
    eligibility.md      # Eligibility rules schema
    generation.md       # Generation pipeline schema
    node.md             # Narrative node JSON schema
    style-guide.md      # Prose style guide

  scripts/              # Pipeline tools (see below)
    serialize.py        # Serialize prose-final.json → individual node files + manifest
    validate.py         # Validate beat text bounds (≤150 chars)
    validate_beats.py   # Validate beat length range (10-150 chars)
    verify.py           # Verify expanded node structure

  runs/                 # Per-run working data
    poc-township-arrival/   # POC run: township arrival sequence
      context.json          # Prompt context / lore training data
      beat-outlines.json    # Beat outline stage output
      critic-results.json   # Critic/review stage output
      prose-expanded.json   # Expanded prose with beats, outcomes, options
      prose-final.json      # Final validated prose (input to serializer)
```

## Scripts

| Script | Purpose | Input | Output |
|---|---|---|---|
| `verify.py` | Check expanded node structure | `prose-expanded.json` | stdout report |
| `validate.py` | Validate beat text bounds (≤150 chars) | `prose-final.json` | pass/fail per beat |
| `validate_beats.py` | Validate beat length range (10-150 chars) | `prose-final.json` | pass/fail per beat |
| `serialize.py` | Serialize nodes into individual JSON files + manifest | `prose-final.json` | `packages/game/resources/narrative/.../*.json` |

## Usage

All scripts accept a `--run-dir` argument pointing to the run directory:

```bash
# Validate the POC run (default)
python3 packages/content-kit/scripts/validate.py

# Validate a different run
python3 packages/content-kit/scripts/validate.py --run-dir packages/content-kit/runs/my-new-run

# Serialize nodes to game resources
python3 packages/content-kit/scripts/serialize.py \
  --run-dir packages/content-kit/runs/poc-township-arrival \
  --output-dir packages/game/resources/narrative/township/arrival
```

## Pipeline flow

1. **Context** — `context.json` holds the lore training data and prompt context for a generation run.
2. **Beat outlines** — LLM generates structural beat outlines → `beat-outlines.json`.
3. **Critic review** — A critic pass reviews beats → `critic-results.json`.
4. **Prose expansion** — Beats are expanded with full prose, outcomes, and options → `prose-expanded.json`.
5. **Final validation** — Text bounds checked, issues fixed → `prose-final.json`.
6. **Serialization** — `serialize.py` writes individual node files to `packages/game/resources/narrative/` matching the Godot narrative schema.

## Adding a new run

```bash
mkdir packages/content-kit/runs/my-new-biome
# Copy or generate context.json, then run pipeline stages...
python3 packages/content-kit/scripts/serialize.py \
  --run-dir packages/content-kit/runs/my-new-biome \
  --output-dir packages/game/resources/narrative/the-bush/encounter_01
```
