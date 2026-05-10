#!/usr/bin/env python3
"""Validate beat text lengths in prose-final.json (10-150 chars)."""

import argparse
from pathlib import Path

DEFAULT_RUN_DIR = Path(__file__).parent.parent / "runs" / "poc-township-arrival"


def main():
    parser = argparse.ArgumentParser(description="Validate beat text lengths.")
    parser.add_argument("--run-dir", type=Path, default=DEFAULT_RUN_DIR, help="Directory containing prose-final.json")
    args = parser.parse_args()

    import json
    with open(args.run_dir / "prose-final.json") as f:
        nodes = json.load(f)

    all_ok = True
    for node in nodes:
        nid = node["id"]
        for beat in node.get("content", {}).get("beats", []):
            bid = beat["id"]
            text = beat.get("text", "")
            length = len(text)
            status = "OK" if 10 <= length <= 150 else "FAIL"
            if status == "FAIL":
                all_ok = False
            print(f"{nid} / {bid}: {length} chars [{status}]")

    print()
    if all_ok:
        print("ALL BEATS PASS (10-150 chars)")
    else:
        print("SOME BEATS STILL FAIL - check above")


if __name__ == "__main__":
    main()
