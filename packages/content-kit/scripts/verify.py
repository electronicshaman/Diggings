#!/usr/bin/env python3
"""Verify structure of prose-expanded.json nodes."""

import argparse
from pathlib import Path

DEFAULT_RUN_DIR = Path(__file__).parent.parent / "runs" / "poc-township-arrival"


def main():
    parser = argparse.ArgumentParser(description="Verify expanded prose node structure.")
    parser.add_argument("--run-dir", type=Path, default=DEFAULT_RUN_DIR, help="Directory containing prose-expanded.json")
    args = parser.parse_args()

    import json
    with open(args.run_dir / "prose-expanded.json") as f:
        data = json.load(f)
    print(f"Total nodes: {len(data)}")
    for node in data:
        beats_count = len(node.get("content", {}).get("beats", []))
        has_outcomes = "outcomes" in node.get("content", {})
        has_options = "options" in node.get("content", {})
        hook_len = len(node["content"]["narrative_hook"]) if "narrative_hook" in node.get("content", {}) else 0
        print(f"  {node['id']} | type={node['type']:12s} beats={beats_count} outcomes={has_outcomes} options={has_options} hook_len={hook_len}")


if __name__ == "__main__":
    main()
