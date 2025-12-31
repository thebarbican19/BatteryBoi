# Quick Start: Restructure pbxproj

## TL;DR

```bash
cd /Users/mojito/Sites/BatteryBoi

# Step 1: Preview what will change
python3 restructure_pbxproj_final.py

# Step 2: Apply the changes
python3 restructure_pbxproj_final.py --apply

# Step 3: In Xcode
# - Close project
# - Reopen project
# - Verify folder structure in Project Navigator
```

## What Happens

**Creates 14 new folder groups in Xcode:**
```
Core/
├── Alert/
├── Animation/
├── App/
├── Battery/
├── Bluetooth/
├── Cloud/
├── Menubar/
├── Onboarding/
├── Peer/
├── Process/
├── Settings/
├── Stats/
├── Update/
├── Window/
└── [12 constants files stay here]
```

## If Something Goes Wrong

```bash
# Restore original
cp BatteryBoi.xcodeproj/project.pbxproj.backup BatteryBoi.xcodeproj/project.pbxproj
# Reopen Xcode
```

## Details

Full guide: See `PBXPROJ_RESTRUCTURING_GUIDE.md`

Script: `restructure_pbxproj_final.py`

Backup: `BatteryBoi.xcodeproj/project.pbxproj.backup`
