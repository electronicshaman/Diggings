#!/usr/bin/env python3
"""Validate all beat text lengths in prose-final.json (max 150 chars)."""

import argparse
from pathlib import Path

DEFAULT_RUN_DIR = Path(__file__).parent.parent / "runs" / "poc-township-arrival"


def main():
    parser = argparse.ArgumentParser(description="Validate beat text bounds.")
    parser.add_argument("--run-dir", type=Path, default=DEFAULT_RUN_DIR, help="Directory containing prose-final.json")
    args = parser.parse_args()

    import json
    with open(args.run_dir / "prose-final.json") as f:
        nodes = json.load(f)

    print(f"Total nodes: {len(nodes)}")
    all_pass = True
    for node in nodes:
        nid = node["id"]
        beats = node.get("content", {}).get("beats", [])
        print(f"\n--- {nid} ({len(beats)} beats) ---")
        for b in beats:
            text = b.get("text", "")
            length = len(text)
            status = "OK" if length <= 150 else "FAIL"
            if status == "FAIL":
                all_pass = False
            print(f'  {b["id"]:20s} role={b["role"]:12s} chars={length:4d} [{status}]')

    print(f'\n{"="*50}')
    print(f"ALL BEATS WITHIN BOUNDS: {all_pass}")


if __name__ == "__main__":
    main()
