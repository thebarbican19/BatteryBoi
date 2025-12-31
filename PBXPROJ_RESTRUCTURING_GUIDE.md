# Xcode Project File Restructuring Guide

## Overview

This guide provides instructions for restructuring the Xcode project file (`pbxproj`) to create proper folder groups for Core subdirectories.

**Current State:**
- Filesystem is organized: `/BatteryBoi/Core/Alert/`, `/BatteryBoi/Core/Battery/`, etc.
- Xcode project shows them flat in the Core group with forward slashes: `Alert/BBAlertManager.swift`

**Goal:**
- Xcode project will show proper folder hierarchy in the Project Navigator
- Creates 14 new PBXGroup entries for subdirectories
- Moves 14 manager files into their respective groups
- Constants files remain at the Core level (they reference full paths)

## What Will Change

### New Folder Groups to Create
- Alert/
- Animation/
- App/
- Battery/
- Bluetooth/
- Cloud/
- Menubar/
- Onboarding/
- Peer/
- Process/
- Settings/
- Stats/
- Update/
- Window/

### File Organization

**Current Structure (in Xcode):**
```
Core
  ├─ BBSystemConstants.swift
  ├─ BBBatteryConstants.swift
  ├─ ... (12 constants files)
  ├─ Alert/BBAlertManager.swift
  ├─ Animation/BBAnimationManager.swift
  ├─ App/BBAppManager.swift
  └─ ... (14 manager files with slashes)
```

**After Restructuring:**
```
Core
  ├─ Alert/
  │  └─ BBAlertManager.swift
  ├─ Animation/
  │  └─ BBAnimationManager.swift
  ├─ App/
  │  └─ BBAppManager.swift
  ├─ Battery/
  │  └─ BBBatteryManager.swift
  ├─ ... (other subdirectories)
  ├─ BBSystemConstants.swift
  ├─ BBBatteryConstants.swift
  ├─ ... (constants stay at top level)
  └─ ... (12 constants files total)
```

## How the Script Works

The `restructure_pbxproj_final.py` script:

1. **Analyzes** the current pbxproj structure
2. **Identifies** all files in the Core group
3. **Categorizes** files as either:
   - Constants files (no slashes in display name)
   - Manager files (contain subdirectory prefixes like "App/")
4. **Creates** new PBXGroup entries for each subdirectory
5. **Assigns** unique IDs to each new group
6. **Reorganizes** the Core group to reference subgroups + constants
7. **Updates** the pbxproj file with all changes

## Usage Instructions

### Step 1: Verify the Backup
A backup was created at:
```
/Users/mojito/Sites/BatteryBoi/BatteryBoi.xcodeproj/project.pbxproj.backup
```

### Step 2: Run Analysis (Optional but Recommended)
View what will be changed without making modifications:

```bash
cd /Users/mojito/Sites/BatteryBoi
python3 restructure_pbxproj_final.py
```

You should see:
- 12 constants files (stay at Core level)
- 14 subdirectories with 1 manager file each

### Step 3: Apply Changes
When ready to apply the restructuring:

```bash
cd /Users/mojito/Sites/BatteryBoi
python3 restructure_pbxproj_final.py --apply
```

### Step 4: Verify in Xcode

1. **Close Xcode completely**
2. **Reopen** the BatteryBoi project
3. **Check Project Navigator** - you should see proper folder hierarchy

The project should build and compile without any issues since:
- File references in Build Phases are not changed
- `sourceTree = "<group>"` means paths are relative to parent groups
- Actual file system organization hasn't changed

## Expected Output

After running with `--apply`, you'll see:

```
======================================================================
pbxproj Subdirectory Restructuring Tool
======================================================================

APPLYING CHANGES...

Analyzing pbxproj structure...
Found 26 items in Core group
Found 12 constants files
Found 14 subdirectories:

  Alert/ -> [GROUP_ID] (1 files)
  Animation/ -> [GROUP_ID] (1 files)
  App/ -> [GROUP_ID] (1 files)
  ... (rest of subdirectories)

======================================================================
Changes written to pbxproj!
======================================================================

Next steps:
  1. Close Xcode
  2. Reopen the project
  3. Verify the new folder structure in the project navigator
```

## Technical Details

### PBXGroup Structure

Each new subdirectory group follows this pattern:

```
[GROUP_ID] /* [DirectoryName] */ = {
    isa = PBXGroup;
    children = (
        [FILE_ID],
    );
    path = [DirectoryName];
    sourceTree = "<group>";
};
```

Example for Alert:
```
94A21C8520E24DEF8FF16B65 /* Alert */ = {
    isa = PBXGroup;
    children = (
        D8D52B752B322F4D004C7E5C,
    );
    path = Alert;
    sourceTree = "<group>";
};
```

### Core Group Update

The Core group changes from:

```
D8D9E5BB2A8064A000E295FA /* Core */ = {
    isa = PBXGroup;
    children = (
        C0669AAB2F03380000000001,  /* Constants */
        ...
        D8D52B752B322F4D004C7E5C,  /* Alert/BBAlertManager */
        D891134C2AAC34DC00B5E4F5,  /* Animation/BBAnimationManager */
        ...
    );
```

To:

```
D8D9E5BB2A8064A000E295FA /* Core */ = {
    isa = PBXGroup;
    children = (
        94A21C8520E24DEF8FF16B65,  /* Alert group */
        1BCB7A0CF88D49A1AC011C02,  /* Animation group */
        BD52E0B1D80A4B74A5FF1AC0,  /* App group */
        ...
        C0669AAB2F03380000000001,  /* Constants */
        ...
    );
```

## Rollback Instructions

If you need to revert to the original structure:

```bash
cp /Users/mojito/Sites/BatteryBoi/BatteryBoi.xcodeproj/project.pbxproj.backup \
   /Users/mojito/Sites/BatteryBoi/BatteryBoi.xcodeproj/project.pbxproj
```

Then close and reopen Xcode.

## Validation Results

The script has been validated to:
- Correctly parse all 26 Core group items
- Identify 12 constants files
- Create 14 properly formatted subdirectory groups
- Maintain file reference IDs
- Preserve all build phase references
- Generate valid pbxproj syntax

## Notes

- The file paths with `sourceTree = "<group>"` are relative to parent groups
- Build phases and references are not modified - compilation is unaffected
- The filesystem structure remains unchanged
- Only the Xcode project navigator view is reorganized
- IDEs like Xcode understand the group hierarchy for proper display

## Script Files

- **restructure_pbxproj_final.py** - Main restructuring script
- **project.pbxproj.backup** - Original pbxproj file (created automatically)
- **PBXPROJ_RESTRUCTURING_GUIDE.md** - This guide

## Questions?

If something goes wrong:
1. Restore from backup
2. Review the validation output
3. Ensure all files are properly committed to git
