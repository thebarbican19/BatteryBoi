import subprocess
import plistlib
import json

def get_bluetooth_info_from_system_profiler():
    # Use system_profiler to get XML formatted Bluetooth information
    result = subprocess.run(['system_profiler', 'SPBluetoothDataType', '-xml'], capture_output=True)
    if result.returncode != 0:
        raise Exception("Failed to retrieve Bluetooth info from system_profiler")

    # Parse the returned XML
    plist_data = plistlib.loads(result.stdout)
    bluetooth_info = plist_data[0]['_items'][0]
    
    # Extracting connected devices
    connected_devices = bluetooth_info.get('device_connected', [])
    
    return connected_devices

if __name__ == '__main__':
    connected_devices = get_bluetooth_info_from_system_profiler()
    print(json.dumps(connected_devices, indent=4))
