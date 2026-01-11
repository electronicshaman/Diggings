#!/usr/bin/env python3
"""
Migrate CardData resources to use the new CardCost system.
Reads .tres files, extracts energy_cost and sanity_cost, and adds them to the costs array.

Usage:
    python migrate_card_costs.py [--dry-run] [--rollback] [--validate-only]

Options:
    --dry-run       Preview changes without writing
    --rollback      Restore from .bak backups
    --validate-only Only validate existing files, don't migrate
"""

import os
import re
import sys
import shutil
import argparse
from pathlib import Path
from typing import Optional, Tuple, List

CARDS_PATH = Path(__file__).parent.parent.parent.parent / "src" / "data" / "cards"

# Cost script paths
COST_SCRIPTS = {
    "energy": "res://scripts/combat/costs/energy_cost.gd",
    "sanity": "res://scripts/combat/costs/sanity_cost.gd",
}


class MigrationResult:
    def __init__(self):
        self.migrated: List[Path] = []
        self.skipped: List[Path] = []
        self.failed: List[Tuple[Path, str]] = []
        self.already_migrated: List[Path] = []


def parse_tres_structure(content: str) -> dict:
    """Parse .tres file structure into components."""
    result = {
        "header": "",
        "ext_resources": [],
        "sub_resources": [],
        "resource_section": "",
    }

    lines = content.split('\n')
    current_section = None
    section_content = []

    for i, line in enumerate(lines):
        if line.startswith('[gd_resource'):
            result["header"] = line
        elif line.startswith('[ext_resource'):
            result["ext_resources"].append(line)
        elif line.startswith('[sub_resource'):
            if current_section == "sub_resource":
                result["sub_resources"].append('\n'.join(section_content))
            current_section = "sub_resource"
            section_content = [line]
        elif line.startswith('[resource]'):
            if current_section == "sub_resource":
                result["sub_resources"].append('\n'.join(section_content))
            current_section = "resource"
            section_content = [line]
        elif current_section:
            section_content.append(line)

    if current_section == "resource":
        result["resource_section"] = '\n'.join(section_content)

    return result


def get_next_ext_resource_id(ext_resources: List[str]) -> int:
    """Get next available ext_resource ID."""
    max_id = 0
    for ext in ext_resources:
        match = re.search(r'id="([^"]+)"', ext)
        if match:
            try:
                id_val = int(match.group(1))
                max_id = max(max_id, id_val)
            except ValueError:
                # Non-numeric ID like "energy_cost_script"
                pass
    return max_id + 1


def get_next_sub_resource_id(sub_resources: List[str]) -> int:
    """Get next available sub_resource ID."""
    max_id = 0
    for sub in sub_resources:
        match = re.search(r'id="([^"]+)"', sub)
        if match:
            try:
                id_val = int(match.group(1))
                max_id = max(max_id, id_val)
            except ValueError:
                pass
    return max_id + 1


def migrate_card(file_path: Path, dry_run: bool = False) -> Tuple[bool, str]:
    """
    Migrate a single card file.

    Returns:
        Tuple of (success, message)
    """
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
    except Exception as e:
        return False, f"Failed to read: {e}"

    # Check if already migrated (has costs array with content)
    if re.search(r'costs\s*=\s*\[\s*SubResource', content):
        return False, "Already migrated"

    # Extract energy_cost and sanity_cost
    energy_match = re.search(r'energy_cost\s*=\s*(\d+)', content)
    sanity_match = re.search(r'sanity_cost\s*=\s*(\d+)', content)

    energy_cost = int(energy_match.group(1)) if energy_match else 0
    sanity_cost = int(sanity_match.group(1)) if sanity_match else 0

    if energy_cost == 0 and sanity_cost == 0:
        return False, "No costs to migrate"

    # Parse file structure
    structure = parse_tres_structure(content)

    if not structure["resource_section"]:
        return False, "No [resource] section found"

    # Track new IDs
    next_ext_id = get_next_ext_resource_id(structure["ext_resources"])
    next_sub_id = get_next_sub_resource_id(structure["sub_resources"])

    new_ext_resources = []
    new_sub_resources = []
    cost_refs = []

    # Add energy cost
    if energy_cost > 0:
        ext_id = f"energy_cost_{next_ext_id}"
        next_ext_id += 1
        sub_id = next_sub_id
        next_sub_id += 1

        new_ext_resources.append(
            f'[ext_resource type="Script" path="{COST_SCRIPTS["energy"]}" id="{ext_id}"]'
        )
        new_sub_resources.append(
            f'[sub_resource type="Resource" id="{sub_id}"]\n'
            f'script = ExtResource("{ext_id}")\n'
            f'amount = {energy_cost}'
        )
        cost_refs.append(f'SubResource("{sub_id}")')

    # Add sanity cost
    if sanity_cost > 0:
        ext_id = f"sanity_cost_{next_ext_id}"
        next_ext_id += 1
        sub_id = next_sub_id
        next_sub_id += 1

        new_ext_resources.append(
            f'[ext_resource type="Script" path="{COST_SCRIPTS["sanity"]}" id="{ext_id}"]'
        )
        new_sub_resources.append(
            f'[sub_resource type="Resource" id="{sub_id}"]\n'
            f'script = ExtResource("{ext_id}")\n'
            f'amount = {sanity_cost}'
        )
        cost_refs.append(f'SubResource("{sub_id}")')

    # Build new file content
    lines = []

    # Header
    # Update load_steps in header
    old_load_steps_match = re.search(r'load_steps=(\d+)', structure["header"])
    if old_load_steps_match:
        old_steps = int(old_load_steps_match.group(1))
        new_steps = old_steps + len(new_ext_resources) + len(new_sub_resources)
        new_header = re.sub(r'load_steps=\d+', f'load_steps={new_steps}', structure["header"])
    else:
        new_header = structure["header"]
    lines.append(new_header)
    lines.append("")

    # Ext resources (original + new)
    for ext in structure["ext_resources"]:
        lines.append(ext)
    for ext in new_ext_resources:
        lines.append(ext)
    lines.append("")

    # Sub resources (original + new cost resources)
    for sub in structure["sub_resources"]:
        lines.append(sub)
        lines.append("")
    for sub in new_sub_resources:
        lines.append(sub)
        lines.append("")

    # Resource section with costs array added
    resource_lines = structure["resource_section"].split('\n')
    new_resource_lines = []
    costs_added = False

    for line in resource_lines:
        new_resource_lines.append(line)
        # Add costs array right after [resource]
        if line.strip() == '[resource]' and not costs_added:
            costs_line = f'costs = [{", ".join(cost_refs)}]'
            new_resource_lines.append(costs_line)
            costs_added = True

    lines.extend(new_resource_lines)

    new_content = '\n'.join(lines)

    if dry_run:
        return True, f"Would migrate (energy={energy_cost}, sanity={sanity_cost})"

    # Create backup
    backup_path = file_path.with_suffix('.tres.bak')
    try:
        shutil.copy2(file_path, backup_path)
    except Exception as e:
        return False, f"Failed to create backup: {e}"

    # Write new content
    try:
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(new_content)
    except Exception as e:
        # Restore from backup on failure
        shutil.copy2(backup_path, file_path)
        return False, f"Failed to write: {e}"

    return True, f"Migrated (energy={energy_cost}, sanity={sanity_cost})"


def validate_tres_file(file_path: Path) -> Tuple[bool, str]:
    """
    Validate a .tres file structure.

    Returns:
        Tuple of (valid, message)
    """
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
    except Exception as e:
        return False, f"Failed to read: {e}"

    # Check basic structure
    if not content.startswith('[gd_resource'):
        return False, "Missing gd_resource header"

    if '[resource]' not in content:
        return False, "Missing [resource] section"

    # Check for broken EnergyCost/SanityCost format
    if re.search(r'\[sub_resource type="EnergyCost"', content):
        return False, "Contains broken EnergyCost sub_resource format"

    if re.search(r'\[sub_resource type="SanityCost"', content):
        return False, "Contains broken SanityCost sub_resource format"

    # If it has costs array, verify the sub_resources use script references
    if re.search(r'costs\s*=\s*\[', content):
        # Check that cost sub_resources have script = ExtResource
        cost_sub_match = re.findall(r'\[sub_resource[^\]]*\](.*?)(?=\[|\Z)', content, re.DOTALL)
        for sub_content in cost_sub_match:
            if 'amount = ' in sub_content and 'script = ExtResource' not in sub_content:
                # This might be a cost sub_resource without script reference
                if not any(handler in sub_content for handler in ['ignores_defense', 'card_filter', 'resource_type']):
                    return False, "Cost sub_resource missing script reference"

    return True, "Valid"


def rollback_file(file_path: Path) -> Tuple[bool, str]:
    """Restore file from .bak backup."""
    backup_path = file_path.with_suffix('.tres.bak')

    if not backup_path.exists():
        return False, "No backup found"

    try:
        shutil.copy2(backup_path, file_path)
        backup_path.unlink()
        return True, "Restored from backup"
    except Exception as e:
        return False, f"Failed to restore: {e}"


def process_directory(dir_path: Path, dry_run: bool = False, validate_only: bool = False, rollback: bool = False) -> MigrationResult:
    """Recursively process all .tres files in a directory."""
    result = MigrationResult()

    for item in dir_path.iterdir():
        if item.is_dir():
            sub_result = process_directory(item, dry_run, validate_only, rollback)
            result.migrated.extend(sub_result.migrated)
            result.skipped.extend(sub_result.skipped)
            result.failed.extend(sub_result.failed)
            result.already_migrated.extend(sub_result.already_migrated)
        elif item.suffix == '.tres':
            # Check if it's a CardData resource
            try:
                with open(item, 'r', encoding='utf-8') as f:
                    first_lines = f.read(500)
            except:
                continue

            is_card_data = (
                ('script = ExtResource' in first_lines and 'card_data' in first_lines.lower()) or
                'type="CardData"' in first_lines or
                'script_class="CardData"' in first_lines
            )

            if not is_card_data:
                continue

            if rollback:
                success, msg = rollback_file(item)
                if success:
                    result.migrated.append(item)
                    print(f"  Rolled back: {item.name}")
                else:
                    result.skipped.append(item)
            elif validate_only:
                valid, msg = validate_tres_file(item)
                if valid:
                    result.skipped.append(item)
                else:
                    result.failed.append((item, msg))
                    print(f"  INVALID: {item.name} - {msg}")
            else:
                success, msg = migrate_card(item, dry_run)
                if success:
                    result.migrated.append(item)
                    prefix = "[DRY-RUN] " if dry_run else ""
                    print(f"  {prefix}Migrated: {item.name} - {msg}")
                elif "Already migrated" in msg:
                    result.already_migrated.append(item)
                elif "No costs to migrate" in msg:
                    result.skipped.append(item)
                else:
                    result.failed.append((item, msg))
                    print(f"  FAILED: {item.name} - {msg}")

    return result


def main():
    parser = argparse.ArgumentParser(description='Migrate CardData resources to use CardCost system')
    parser.add_argument('--dry-run', action='store_true', help='Preview changes without writing')
    parser.add_argument('--rollback', action='store_true', help='Restore from .bak backups')
    parser.add_argument('--validate-only', action='store_true', help='Only validate existing files')
    args = parser.parse_args()

    print("=" * 60)
    if args.rollback:
        print("CardCost Migration - ROLLBACK MODE")
    elif args.validate_only:
        print("CardCost Migration - VALIDATION ONLY")
    elif args.dry_run:
        print("CardCost Migration - DRY RUN")
    else:
        print("CardCost Migration")
    print("=" * 60)
    print(f"Cards path: {CARDS_PATH}")
    print()

    if not CARDS_PATH.exists():
        print(f"ERROR: Cards directory not found: {CARDS_PATH}")
        sys.exit(1)

    result = process_directory(CARDS_PATH, args.dry_run, args.validate_only, args.rollback)

    print()
    print("=" * 60)
    print("Summary:")
    print(f"  Migrated/Processed: {len(result.migrated)}")
    print(f"  Already migrated:   {len(result.already_migrated)}")
    print(f"  Skipped (no cost):  {len(result.skipped)}")
    print(f"  Failed:             {len(result.failed)}")

    if result.failed:
        print()
        print("Failed files:")
        for path, msg in result.failed:
            print(f"  - {path.relative_to(CARDS_PATH)}: {msg}")

    print("=" * 60)

    if result.failed:
        sys.exit(1)


if __name__ == "__main__":
    main()
