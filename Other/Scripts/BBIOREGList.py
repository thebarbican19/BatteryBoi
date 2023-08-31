import subprocess
import json

def identify_device_type(product_name):
    if "Mouse" in product_name:
        return "Mouse"
    elif "Keyboard" in product_name:
        return "Keyboard"
    elif "Trackpad" in product_name:
        return "Trackpad"
    else:
        return "Unknown"

def get_device_battery_info():
    # Execute the ioreg command to get device information
    try:
        output = subprocess.check_output(
            ['ioreg', '-c', 'AppleDeviceManagementHIDEventService', '-r', '-l'],
            text=True
        )
    except subprocess.CalledProcessError as e:
        print(f"An error occurred while running the ioreg command: {e}")
        return None

    # Initialize an empty list to hold device info
    devices = []

    # Initialize an empty dictionary to hold individual device info
    device_info = {}

    # Iterate over each line in the command output
    for line in output.strip().split('\n'):
        # If this line marks the beginning of a new device, and
        # device_info is not empty, append it to devices list and clear it
        if line.startswith('+') and device_info:
            devices.append(device_info)
            device_info = {}

        # Look for battery percentage
        if 'BatteryPercent' in line:
            try:
                # Extract the battery percentage
                battery_percent = int(line.split('=')[-1].strip())
                device_info['device_batteryLevelMain'] = battery_percent
            except (IndexError, ValueError):
                print("Failed to parse BatteryPercent")

        # Look for the device name
        if line.strip().startswith('"Product" ='):
            try:
                # Extract the device name
                device_name = line.split('=')[-1].strip().strip('"')
                device_info['device_product'] = device_name
                device_info['device_minorType'] = identify_device_type(device_name)
            except (IndexError, ValueError):
                print("Failed to parse Product")

        # Look for the device address
        if 'DeviceAddress' in line:
            try:
                # Extract the device address
                device_address = line.split('=')[-1].strip().strip('"')
                device_info['device_address'] = device_address
            except (IndexError, ValueError):
                print("Failed to parse DeviceAddress")

    # Append any remaining device_info
    if device_info:
        devices.append(device_info)

    # Return the devices info as a JSON payload
    return json.dumps(devices, indent=4)

if __name__ == '__main__':
    print(get_device_battery_info())
