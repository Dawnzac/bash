#!/bin/bash

# Get basic system information
AGENT_ID="$(uuidgen)"
AGENT_VERSION="1.0"
AGENT_INSTALLED_DATE="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
TIMESTAMP="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
DEVICE_NAME="$(hostname)"
MANUFACTURER="$(cat /sys/class/dmi/id/sys_vendor 2>/dev/null || echo 'Unknown')"
MODEL="$(cat /sys/class/dmi/id/product_name 2>/dev/null || echo 'Unknown')"
SERIAL_NUMBER="$(cat /sys/class/dmi/id/product_serial 2>/dev/null || echo 'Unknown')"
OS_NAME="$(uname -s)"
OS_VERSION="$(uname -r)"
OS_ARCH="$(uname -m)"
LAST_RESTARTED_AT="$(who -b | awk '{print $3 "T" $4 "Z"}')"
PENDING_RESTART=false

# Get CPU Information
CPU_MODEL="$(lscpu | grep 'Model name' | awk -F: '{print $2}' | xargs)"
CPU_CORES=$(nproc)
CPU_CLOCK_SPEED=$(lscpu | grep 'MHz' | awk -F: '{print $2}' | xargs)
CPU_CLOCK_SPEED=$(echo "scale=2; $CPU_CLOCK_SPEED / 1000" | bc) # Convert MHz to GHz

# Get RAM Information
RAM_TOTAL_GB=$(free -g | awk '/^Mem:/ {print $2}')
RAM_TYPE="Unknown"  # Can be extracted with dmidecode if root

# Get Storage Information
STORAGE_INFO=$(lsblk -J -o NAME,TYPE,SIZE | jq '[.blockdevices[] | select(.type=="disk") | {"type": "HDD/SSD", "capacityGB": (.size | gsub("G"; "") | tonumber)}]')

# Get Network Interfaces
NETWORK_INTERFACES=$(ip -o -4 addr show | awk '{print $2, $4}' | jq -R -s 'split("\n")[:-1] | map(split(" ") | {name: .[0], ipAddresses: [.[1]]})')

# Get Installed Software
INSTALLED_SOFTWARE=$(dpkg-query -W -f='{"name": "${Package}", "version": "${Version}", "scope": "Global"},' 2>/dev/null | sed 's/,$//')
INSTALLED_SOFTWARE="[${INSTALLED_SOFTWARE}]"

# Create JSON output
JSON_OUTPUT=$(jq -n --arg agentId "$AGENT_ID" --arg agentVersion "$AGENT_VERSION" --arg agentInstalledDateTime "$AGENT_INSTALLED_DATE" --arg timestamp "$TIMESTAMP" \
--arg deviceName "$DEVICE_NAME" --arg manufacturer "$MANUFACTURER" --arg model "$MODEL" --arg serialNumber "$SERIAL_NUMBER" --arg osName "$OS_NAME" \
--arg osVersion "$OS_VERSION" --arg osArchitecture "$OS_ARCH" --arg lastRestartedAt "$LAST_RESTARTED_AT" --argjson pendingRestart "$PENDING_RESTART" \
--arg cpuModel "$CPU_MODEL" --argjson cpuCores "$CPU_CORES" --argjson cpuClockSpeed "$CPU_CLOCK_SPEED" --argjson ramTotalGB "$RAM_TOTAL_GB" \
--arg ramType "$RAM_TYPE" --argjson storage "$STORAGE_INFO" --argjson network "$NETWORK_INTERFACES" --argjson software "$INSTALLED_SOFTWARE" \
'{"agentId": $agentId, "agentVersion": $agentVersion, "agentInstalledDateTime": $agentInstalledDateTime, "timestamp": $timestamp,
  "deviceInfo": {"deviceName": $deviceName, "manufacturer": $manufacturer, "model": $model, "serialNumber": $serialNumber,
  "os": {"name": $osName, "version": $osVersion, "architecture": $osArchitecture}, "lastRestartedAt": $lastRestartedAt,
  "pendingRestart": $pendingRestart, "hardwareSpecs": {"cpu": {"model": $cpuModel, "cores": ($cpuCores | tonumber), "clockSpeedGHz": ($cpuClockSpeed | tonumber)},
  "ram": {"totalGB": ($ramTotalGB | tonumber), "type": $ramType}, "storage": $storage, "networkInterfaces": $network}}, "softwareInfo": $software}')

echo "$JSON_OUTPUT" | jq . > inventory_report.json
