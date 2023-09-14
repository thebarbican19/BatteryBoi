import subprocess
import json

def get_profiles():
    try:
        output = subprocess.check_output(['sudo', 'profiles', 'show'], text=True)
        lines = output.splitlines()

        profiles = []
        current_id = None
        current_display = None

        for line in lines:
            if 'profileIdentifier:' in line:
                current_id = line.split(': ')[1].strip()
            elif 'profileDisplayName:' in line:
                current_display = line.split(': ')[1].strip()

            if current_id and current_display:
                profiles.append({
                    "id": current_id,
                    "display": current_display
                })
                current_id = None
                current_display = None

        return profiles

    except subprocess.CalledProcessError:
        print("Failed to execute command.")
        return []

profiles = get_profiles()
print(json.dumps(profiles, indent=4))
