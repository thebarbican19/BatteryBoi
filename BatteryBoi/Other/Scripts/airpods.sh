#!/bin/bash
# Airpods.sh

echo "Starting script..."

BATTERY_INFO=(
  "BatteryPercentCombined"
  "HeadsetBattery"
  "BatteryPercentSingle"
  "BatteryPercentCase"
  "BatteryPercentLeft"
  "BatteryPercentRight"
)

echo "Reading Bluetooth defaults..."
BT_DEFAULTS=$(defaults read /Library/Preferences/com.apple.Bluetooth)
echo "Fetching system profiler data..."
SYS_PROFILE=$(system_profiler SPBluetoothDataType 2>/dev/null)
echo "Extracting MAC addresses..."
MAC_ADDR=$(grep -b2 "Minor Type: " <<<"${SYS_PROFILE}" | awk '/Address/{print $3}')

for macAddress in $MAC_ADDR
do
  if [ $macAddress ]; then
    echo "Processing device: $macAddress"
    BT_DATA=$(grep -ia6 '"'"$macAddress"'"' <<<"${BT_DEFAULTS}")
    SHORT_MAC_ADDR=$(echo "$macAddress" | awk '{print substr($0,0,8)}')
    CONNECTED=$(grep -ia6 "$macAddress" <<<"${SYS_PROFILE}" | awk '/Connected: Yes/{print 1}')
    result="$(grep -i -A 4 ^"${SHORT_MAC_ADDR}" $1)"

    if [ "$result" ]; then
      regex="(BatteryPercentSingle) = ([0-9]+)"
      if [[ $BT_DATA =~ $regex ]]; then
        echo $macAddress"@@"${BASH_REMATCH[2]}
      else
        DEVICE_SELECTED=$(grep -b2 "Apple" <<<"$result" | awk '{print $3}')
        if [ "$result" ]; then
          if [[ $DEVICE_SELECTED = *'Apple'* ]]; then
            if [[ "${CONNECTED}" ]]; then
              for info in "${BATTERY_INFO[@]}"; do
                echo "Checking $info..."
                declare -x "${info}"="$(awk -v pat="${info}" '$0~pat{gsub (";",""); print $3 }' <<<"${BT_DATA}")"
                [[ -n "${!info}" ]] && OUTPUT="${OUTPUT} $(awk '/BatteryPercent/{print substr($0,15)": "}' <<<"${info}")${!info}%"
              done
              newVar=$(echo "${OUTPUT}" | perl -pe 's/([:%])|([A-Z])\w+//g')
              if [ -z "$newVar" ]
              then
                echo "No battery info for $macAddress"
              else
               echo $macAddress"@@""$newVar" | xargs
              fi
            else
             echo $macAddress"@@""not connected"
            fi
          fi
        else
          echo $macAddress"@@""unknown device"
        fi
      fi
    else
      echo "unknown"
    fi
  else
    echo "MAC address not found."
  fi
done

echo "Script completed."
exit 0
