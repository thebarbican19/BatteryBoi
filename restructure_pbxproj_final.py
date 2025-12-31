#!/usr/bin/env python3
"""
Complete restructuring script for pbxproj to create proper folder groups
for Core subdirectories.

Transforms flat file references like:
  D8D9E5CA2A8403D300E295FA /* App/BBAppManager.swift */

Into organized subgroups like:
  [App group]
    - D8D9E5CA2A8403D300E295FA /* BBAppManager.swift */

Usage:
  python3 restructure_pbxproj_final.py --apply
"""

import re
import sys
import uuid
from collections import defaultdict
from pathlib import Path

PBXPROJ_PATH = "/Users/mojito/Sites/BatteryBoi/BatteryBoi.xcodeproj/project.pbxproj"


def read_pbxproj():
    """Read the pbxproj file"""
    with open(PBXPROJ_PATH, 'r', encoding='utf-8') as f:
        return f.read()


def write_pbxproj(content):
    """Write the modified pbxproj file"""
    with open(PBXPROJ_PATH, 'w', encoding='utf-8') as f:
        f.write(content)


def generate_group_id():
    """Generate a unique group ID (24 hex chars, uppercase)"""
    return uuid.uuid4().hex.upper()[:24]


def extract_core_children(content):
    """Extract all children from the Core PBXGroup"""
    # Find the Core group definition
    match = re.search(
        r'D8D9E5BB2A8064A000E295FA /\* Core \*/ = \{\s*isa = PBXGroup;\s*children = \((.*?)\);',
        content,
        re.DOTALL
    )
    if not match:
        return None

    children_section = match.group(1)
    # Extract all entries: FILEID /* comment */,
    children_entries = re.findall(r'(\w+) /\* ([^*]+) \*/', children_section)
    return children_entries


def get_file_reference_info(content, file_id):
    """Get the name and path info for a file reference"""
    # Find: FILE_ID /* display_name */ = { ... path = ...; ...}
    pattern = rf'({file_id}) /\* ([^*]+) \*/ = \{{[^}}]*(?:path = ([^;]+);)?'
    match = re.search(pattern, content, re.DOTALL)
    if match:
        file_id = match.group(1)
        display_name = match.group(2)
        file_path = match.group(3).strip().strip('"') if match.group(3) else display_name
        return display_name, file_path
    return None, None


def organize_files_by_subdirectory(content, children_entries):
    """Organize files into subdirectories based on their display names"""
    files_by_dir = defaultdict(list)
    constants_files = []

    for file_id, display_name in children_entries:
        display_name = display_name.strip()

        # Check if it's a constants file (no slashes, just name)
        if '/' not in display_name:
            constants_files.append((file_id, display_name))
        else:
            # Extract directory from path like "App/BBAppManager.swift"
            parts = display_name.split('/')
            dirname = parts[0]
            filename = parts[1] if len(parts) > 1 else display_name
            files_by_dir[dirname].append((file_id, filename, display_name))

    return files_by_dir, constants_files


def create_new_group_definition(group_id, group_name, file_ids):
    """Create a PBXGroup definition for a subdirectory"""
    children_lines = []
    for file_id in file_ids:
        children_lines.append(f"\t\t\t\t{file_id},")

    children_str = "\n".join(children_lines)

    group_def = f"""\t\t{group_id} /* {group_name} */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
{children_str}
\t\t\t);
\t\t\tpath = {group_name};
\t\t\tsourceTree = "<group>";
\t\t}};
"""
    return group_def


def create_new_core_group(core_group_id, subgroup_ids, constants_file_ids):
    """Create the new Core group that contains subgroups and constants"""
    children_lines = []

    # Add subgroups first (in sorted order)
    for subgroup_id in sorted(subgroup_ids):
        children_lines.append(f"\t\t\t\t{subgroup_id},")

    # Then add constants files
    for const_id in sorted(constants_file_ids):
        children_lines.append(f"\t\t\t\t{const_id},")

    children_str = "\n".join(children_lines)

    core_group_def = f"""\t\tD8D9E5BB2A8064A000E295FA /* Core */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
{children_str}
\t\t\t);
\t\t\tpath = Core;
\t\t\tsourceTree = "<group>";
\t\t}};
"""
    return core_group_def


def update_file_reference_display_name(content, file_id, new_display_name):
    """Update the display name of a file reference"""
    # Pattern: FILE_ID /* old_name */ = {
    pattern = rf'({file_id}) /\* [^*]+ \*/'
    replacement = rf'\1 /* {new_display_name} */'
    return re.sub(pattern, replacement, content, count=1)


def apply_restructuring(content):
    """Apply the complete restructuring"""
    print("Analyzing pbxproj structure...")

    # Extract children from Core group
    children_entries = extract_core_children(content)
    if not children_entries:
        print("Error: Could not find Core group children!")
        return None

    print(f"Found {len(children_entries)} items in Core group")

    # Organize files by subdirectory
    files_by_dir, constants_files = organize_files_by_subdirectory(content, children_entries)

    print(f"Found {len(constants_files)} constants files")
    print(f"Found {len(files_by_dir)} subdirectories:\n")

    # Create mapping of directory to group ID
    subdir_group_ids = {}
    new_groups_str = ""

    for dirname in sorted(files_by_dir.keys()):
        group_id = generate_group_id()
        subdir_group_ids[dirname] = group_id

        file_ids = [fid for fid, _, _ in files_by_dir[dirname]]
        print(f"  {dirname}/ -> {group_id} ({len(file_ids)} files)")

        # Create the group definition
        group_def = create_new_group_definition(group_id, dirname, file_ids)
        new_groups_str += group_def

    # Create the new Core group
    subgroup_ids_list = list(subdir_group_ids.values())
    constants_ids = [fid for fid, _ in constants_files]
    new_core_group = create_new_core_group("D8D9E5BB2A8064A000E295FA", subgroup_ids_list, constants_ids)

    # Replace the old Core group definition with the new one
    old_core_pattern = r'D8D9E5BB2A8064A000E295FA /\* Core \*/ = \{[^}]*children = \([^)]+\);[^}]*\};'
    content = re.sub(old_core_pattern, new_core_group.rstrip(), content, flags=re.DOTALL)

    # Update file reference display names (remove subdirectory prefix)
    for dirname in files_by_dir:
        for file_id, filename, old_display_name in files_by_dir[dirname]:
            content = update_file_reference_display_name(content, file_id, filename)

    # Insert new groups into the PBXGroup section
    pbxgroup_end = content.find('/* End PBXGroup section */')
    if pbxgroup_end == -1:
        print("Error: Could not find end of PBXGroup section!")
        return None

    # Insert new groups before the end marker
    content = content[:pbxgroup_end] + new_groups_str + "\t/* End PBXGroup section */\n" + content[pbxgroup_end + len('/* End PBXGroup section */'):]

    # Remove duplicate end marker if created
    content = re.sub(r'/* End PBXGroup section \*/\s+/* End PBXGroup section \*/', '/* End PBXGroup section */', content)

    return content


def analyze_only(content):
    """Perform analysis without making changes"""
    print("Analyzing pbxproj structure...\n")

    children_entries = extract_core_children(content)
    if not children_entries:
        print("Error: Could not find Core group children!")
        return

    print(f"Found {len(children_entries)} items in Core group:\n")

    files_by_dir, constants_files = organize_files_by_subdirectory(content, children_entries)

    print("Constants files:")
    for file_id, display_name in sorted(constants_files):
        print(f"  - {display_name} [{file_id}]")

    print(f"\nSubdirectories ({len(files_by_dir)}):")
    for dirname in sorted(files_by_dir.keys()):
        print(f"\n  {dirname}/")
        for file_id, filename, full_display in sorted(files_by_dir[dirname]):
            print(f"    - {full_display} [{file_id}]")

    print("\n" + "=" * 70)
    print("Summary:")
    print(f"  - Constants files: {len(constants_files)}")
    print(f"  - Subdirectories to create: {len(files_by_dir)}")
    print(f"  - Total manager files: {sum(len(v) for v in files_by_dir.values())}")
    print("=" * 70)


if __name__ == "__main__":
    try:
        print("=" * 70)
        print("pbxproj Subdirectory Restructuring Tool")
        print("=" * 70 + "\n")

        content = read_pbxproj()

        if "--apply" in sys.argv:
            print("APPLYING CHANGES...\n")
            new_content = apply_restructuring(content)

            if new_content:
                write_pbxproj(new_content)
                print("\n" + "=" * 70)
                print("Changes written to pbxproj!")
                print("=" * 70)
                print("\nNext steps:")
                print("  1. Close Xcode")
                print("  2. Reopen the project")
                print("  3. Verify the new folder structure in the project navigator")
            else:
                print("ERROR: Restructuring failed!")
                sys.exit(1)
        else:
            analyze_only(content)
            print("\nTo apply changes, run:")
            print("  python3 restructure_pbxproj_final.py --apply")
            print("\nNote: The pbxproj.backup file was created for safety.")

    except Exception as e:
        print(f"Error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
