import subprocess
import json

def identify_device_type(product_name):
    product_names = "Keyboard Mouse Trackpad".split()
    return product_name if product_name in product_names else "Unknown"

def get_device_battery_info():
    try:
        output = subprocess.check_output(
            ['ioreg', '-c', 'AppleDeviceManagementHIDEventService', '-r', '-l'],
            text=True
        )
    except subprocess.CalledProcessError as e:
        print(f"An error occurred while running the ioreg command: {e!r}")
        return None

    devices_list = []
    device_info = {}

    for line in output.strip().split('\n'):
        if line.startswith('+') and device_info:
            device_name = device_info.get('device_name', device_info.get('device_product', 'Unknown Device'))
            devices_list.append({device_name: device_info})
            device_info = {}

        if 'BatteryPercent' in line:
            try:
                battery_percent = int(line.split('=')[-1].strip())
                device_info['device_batteryLevelMain'] = str(battery_percent)  # Convert to string
            except (IndexError, ValueError):
                print("Failed to parse BatteryPercent")

        if line.strip().startswith('"Product" ='):
            try:
                device_product = line.split('=')[-1].strip().strip('"')
                device_info['device_product'] = device_product
                device_info['device_minorType'] = identify_device_type(device_product)
            except (IndexError, ValueError):
                print("Failed to parse Product")

        if 'DeviceAddress' in line:
            try:
                device_address = line.split('=')[-1].strip().strip('"')
                device_info['device_address'] = device_address
            except (IndexError, ValueError):
                print("Failed to parse DeviceAddress")

        if 'DeviceName' in line:
            try:
                device_name = line.split('=')[-1].strip().strip('"')
                device_info['device_name'] = device_name
            except (IndexError, ValueError):
                print("Failed to parse DeviceName")

        if 'RSSI' in line:
            try:
                rssi_value = int(line.split('=')[-1].strip())
                device_info['device_rssi'] = rssi_value
            except (IndexError, ValueError):
                print("Failed to parse RSSI")

    if device_info:
        device_name = device_info.get('device_name', device_info.get('device_product', 'Unknown Device'))
        devices_list.append({device_name: device_info})

    return json.dumps(devices_list, indent=4)

if __name__ == '__main__':
    print(get_device_battery_info())
