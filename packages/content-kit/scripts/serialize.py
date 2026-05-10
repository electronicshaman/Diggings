#!/usr/bin/env python3
"""Serialize prose-final.json nodes into individual JSON files + manifest."""

import argparse
import json
from datetime import datetime, timezone
from pathlib import Path

# Defaults — override with --run-dir and --output-dir
DEFAULT_RUN_DIR = Path(__file__).parent.parent / "runs" / "diggings-arrival"
DEFAULT_OUTPUT_DIR = Path(__file__).parents[2] / "game" / "resources" / "narrative" / "the_diggings" / "arrival"

# Mood defaults by node type — tension/atmosphere/sensoryDetails per schema.
# Biome-specific overrides are loaded from context.json if present.
MOOD_BY_TYPE = {
    "combat": {"tension": 4, "atmosphere": "confrontational", "sensoryDetails": ["metal on stone", "heavy breathing", "mud underfoot"]},
    "choice": {"tension": 3, "atmosphere": "uncertain", "sensoryDetails": ["ink-stained paper", "distant voices", "wood smoke"]},
    "trade": {"tension": 1, "atmosphere": "transactional", "sensoryDetails": ["brass bell jangle", "canvas and rope", "ledgers and ink"]},
    "rest": {"tension": 1, "atmosphere": "quiet relief", "sensoryDetails": ["lavender on thin mattress", "morning light through window", "distant hammers"]},
    "passage": {"tension": 2, "atmosphere": "observant", "sensoryDetails": ["mud track under boots", "canvas tent flaps", "cart wheels groaning"]},
    "state_check": {"tension": 3, "atmosphere": "judged", "sensoryDetails": ["scale on desk", "ledger pages turning", "calloused palm"]},
    "transition": {"tension": 4, "atmosphere": "melancholy shift", "sensoryDetails": ["trooper batons", "wanted posters peeling", "voices sharpening with hunger"]},
}

# Consequence tags for choice options by node ID.
# Extend this dict per-run; falls back to ["unknown_consequence"].
OPTION_TAGS = {
    "township_arrival_choice_01": {
        "opt_vouch": ["reputation_gain", "merchant_debt"],
        "opt_stay_neutral": ["no_consequence", "self_preservation"],
        "opt_warn_owner": ["merchant_favor", "reputation_loss"],
    },
    "township_arrival_choice_02": {
        "opt_identify": ["law_favor", "gang_hostility"],
        "opt_deflect": ["law_suspicion", "gang_neutral"],
        "opt_partial_truth": ["ambiguous_outcome", "tension_maintained"],
    },
}


def load_biome_moods(run_dir: Path) -> dict:
    """Load biome-specific mood overrides from context.json if present."""
    ctx_path = run_dir / "context.json"
    if not ctx_path.exists():
        return {}
    with open(ctx_path) as f:
        ctx = json.load(f)
    moods = {}
    for entry in (ctx.get("target_nodes") or []):
        ntype = entry if isinstance(entry, str) else entry.get("type")
        if not ntype:
            continue
        base = MOOD_BY_TYPE.get(ntype, {})
        if base and ctx.get("biome_sensory_detail"):
            base = dict(base)  # don't mutate the module default
            base["sensoryDetails"] = ctx["biome_sensory_detail"][:3]
        moods[ntype] = base
    return moods


def add_missing_fields(node: dict, biome_moods: dict) -> dict:
    """Add schema-required fields missing from prose-final.json."""
    ntype = node["type"]

    # Add mood to content (required by schema) — prefer biome-specific override
    if "mood" not in node.get("content", {}):
        mood = biome_moods.get(ntype, MOOD_BY_TYPE.get(ntype, {
            "tension": 2, "atmosphere": "neutral", "sensoryDetails": ["dust", "silence"]
        }))
        node["content"]["mood"] = dict(mood)

    # Add consequenceTags to choice options (required by schema)
    if ntype == "choice" and "options" in node.get("content", {}):
        tags_map = OPTION_TAGS.get(node["id"], {})
        for opt in node["content"]["options"]:
            if "consequenceTags" not in opt:
                opt["consequenceTags"] = tags_map.get(opt["id"], ["unknown_consequence"])

    return node


def filename_for(node: dict, prefix: str) -> str:
    """{prefix}_{type}_{NN}.json — e.g. diggings_arrival_combat_01.json"""
    ntype = node["type"]
    num = node["id"].split("_")[-1]  # e.g. "01" from "diggings_arrival_combat_01"
    return f"{prefix}_{ntype}_{num}.json"


def main():
    parser = argparse.ArgumentParser(description="Serialize prose-final.json into narrative node files.")
    parser.add_argument("--run-dir", type=Path, default=DEFAULT_RUN_DIR, help="Directory containing prose-final.json")
    parser.add_argument("--output-dir", type=Path, default=DEFAULT_OUTPUT_DIR, help="Output directory for node files")
    args = parser.parse_args()

    input_path = args.run_dir / "prose-final.json"
    output_dir = args.output_dir
    output_dir.mkdir(parents=True, exist_ok=True)

    # Derive filename prefix from run dir name (e.g. "diggings-arrival" → "diggings_arrival")
    prefix = args.run_dir.name.replace("-", "_")

    # Load biome-specific mood overrides
    biome_moods = load_biome_moods(args.run_dir)

    with open(input_path, "r") as f:
        nodes = json.load(f)

    print(f"Loaded {len(nodes)} nodes from {input_path}")
    if biome_moods:
        print(f"Biome mood overrides loaded for: {', '.join(biome_moods.keys())}")

    filenames = []
    for node in nodes:
        node = add_missing_fields(node, biome_moods)
        fn = filename_for(node, prefix)
        path = output_dir / fn
        with open(path, "w") as f:
            json.dump(node, f, indent=2)
        filenames.append(fn)
        print(f"  Written: {path}")

    # Manifest
    manifest = {
        "nodes": sorted(filenames),
        "count": len(filenames),
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "pipeline_run": args.run_dir.name,
    }
    manifest_path = output_dir / "_manifest.json"
    with open(manifest_path, "w") as f:
        json.dump(manifest, f, indent=2)
    print(f"  Written: {manifest_path}")
    print(f"\nDone. {len(filenames)} node files + manifest.")


if __name__ == "__main__":
    main()
