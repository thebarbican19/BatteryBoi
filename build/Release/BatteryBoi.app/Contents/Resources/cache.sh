#!/bin/bash

plist_file="/Library/Preferences/com.apple.Bluetooth.plist"

xml_content=$(plutil -convert xml1 -o - "${plist_file}")

device_cache_content=$(echo "$xml_content" | awk '/<key>DeviceCache<\/key>/,/<\/array>/')

echo "$device_cache_content"
