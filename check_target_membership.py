import plistlib
import sys

def find_target_by_name(objects, name):
    for key, value in objects.items():
        if value.get('isa') == 'PBXNativeTarget' and value.get('name') == name:
            return key, value
    return None, None

def get_build_phases(objects, target):
    return [objects[bp_id] for bp_id in target.get('buildPhases', [])]

def get_sources_build_phase(build_phases):
    for bp in build_phases:
        if bp.get('isa') == 'PBXSourcesBuildPhase':
            return bp
    return None

def get_file_ref_name(objects, file_ref_id):
    file_ref = objects.get(file_ref_id)
    if file_ref:
        return file_ref.get('path') or file_ref.get('name')
    return None

def main():
    project_path = 'BatteryBoi.xcodeproj/project.pbxproj'
    
    try:
        with open(project_path, 'rb') as f:
            # The pbxproj is often in OpenStep format which plistlib can't read directly if it's not XML/Binary.
            # However, modern Xcode often saves as XML or sometimes the simple text format. 
            # If standard library fails, we might need a regex approach or convert it.
            # Let's try reading it as text and finding the relevant sections manually if plistlib fails
            # or use `plutil` to convert it to xml first.
            pass
    except Exception as e:
        print(f"Error opening file: {e}")
        return

    # Using plutil to convert to xml for easier parsing
    import subprocess
    try:
        subprocess.run(['plutil', '-convert', 'xml1', '-o', 'temp.plist', project_path], check=True)
        with open('temp.plist', 'rb') as f:
            plist = plistlib.load(f)
    except Exception as e:
        print(f"Error converting/reading plist: {e}")
        return

    objects = plist['objects']
    target_id, target = find_target_by_name(objects, 'BatteryBoi (iOS)')
    
    if not target:
        print("Target 'BatteryBoi (iOS)' not found.")
        return

    print(f"Found target 'BatteryBoi (iOS)' ({target_id})")
    
    build_phases = get_build_phases(objects, target)
    sources_phase = get_sources_build_phase(build_phases)
    
    if not sources_phase:
        print("No sources build phase found.")
        return

    files = sources_phase.get('files', [])
    print(f"Target has {len(files)} source files.")
    
    source_files = []
    for build_file_id in files:
        build_file = objects.get(build_file_id)
        if build_file:
            file_ref_id = build_file.get('fileRef')
            name = get_file_ref_name(objects, file_ref_id)
            if name:
                source_files.append(name)

    # Check for specific files
    files_to_check = ['BBSystemConstants.swift', 'BBBatteryConstants.swift', 'BBExtensions.swift', 'BBAlertManager.swift']
    for filename in files_to_check:
        found = False
        for source_file in source_files:
            if source_file and filename in source_file:
                found = True
                print(f"✅ {filename} is present in the target.")
                break
        if not found:
            print(f"❌ {filename} is MISSING from the target.")

if __name__ == '__main__':
    main()
