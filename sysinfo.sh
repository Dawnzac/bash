#!/bin/bash

if ! command -v jq &> /dev/null; then
    echo "jq is not installed. Installing silent mode..."
    sudo DEBIAN_FRONTEND=noninteractive apt-get update -yq && sudo DEBIAN_FRONTEND=noninteractive apt-get install -yq jq
fi

# Generate UUID for agent
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

IS_VM=$(systemd-detect-virt)

if [[ "$IS_VM" != "none" ]]; then
    CPU_MODEL="$(cat /proc/cpuinfo | grep 'model name' | head -1 | awk -F: '{print $2}' | xargs)"
else
    CPU_MODEL="$(lscpu | grep 'Model name' | awk -F: '{print $2}' | xargs)"
fi
CPU_CORES=$(nproc || echo 0)
CPU_CLOCK_SPEED=$(awk '/cpu MHz/ {print $4}' /proc/cpuinfo | head -1 | awk '{printf "%.2f", $1/1000}' || echo 0.0)

RAM_TOTAL_GB=$(awk '/MemTotal/ {printf "%.2f", $2/1024/1024}' /proc/meminfo || echo 0)
RAM_TYPE="Unknown"

STORAGE_TOTAL_GB=$(df -h --output=size / | tail -1 | tr -d 'G' || echo 0)
STORAGE_USED_GB=$(df -h --output=used / | tail -1 | tr -d 'G' || echo 0)
STORAGE_INFO="[{\"type\": \"HDD/SSD\", \"capacityGB\": $STORAGE_TOTAL_GB, \"usedGB\": $STORAGE_USED_GB}]"


NETWORK_INTERFACES=$(ip -json addr show | jq '[.[] | {name: .ifname, macAddress: .address, ipAddresses: [.addr_info[].local] | unique}]' 2>/dev/null || echo '[]')

INSTALLED_SOFTWARE=$(dpkg-query -W -f='{"name": "${Package}", "version": "${Version}", "scope": "Global"},' 2>/dev/null | sed 's/,$//' 2>/dev/null)
if [[ -z "$INSTALLED_SOFTWARE" ]]; then INSTALLED_SOFTWARE='[]'; else INSTALLED_SOFTWARE="[$INSTALLED_SOFTWARE]"; fi

LOGGED_IN_USERS=$(last -F | awk '{print "{\"username\": \"" $1 "\", \"loginTime\": \"" $4 "T" $5 "Z\", \"logoutTime\": " (NF>6 ? "\"" $6 "T" $7 "Z\"" : "null") ", \"sessionType\": \"Console\"}"}' | paste -sd, -)
if [[ -z "$LOGGED_IN_USERS" ]]; then LOGGED_IN_USERS='[]'; else LOGGED_IN_USERS="[$LOGGED_IN_USERS]"; fi

RUNNING_APPS=$(ps -eo comm,pid --sort=-%mem | awk 'NR>1 {print "{\"name\": \"" $1 "\", \"processId\": " $2 ", \"status\": \"Running\"}"}' | paste -sd, -)
if [[ -z "$RUNNING_APPS" ]]; then RUNNING_APPS='{"applicationList": []}'; else RUNNING_APPS="{\"applicationList\": [$RUNNING_APPS]}"; fi

# Dummy Customer Information for the time being
CUSTOMER_INFO='{"customerId": "420", "customerName": "Space X Ltd.", "customerLicenseType": "Enterprise", "group": {"groupId": "AEX12", "groupName": "Starship", "agentAddedToGroupOn": "2024-01-01T12:00:00Z"}}'

AGENT_STATUS="Active"

JSON_OUTPUT=$(jq -n --arg agentId "$AGENT_ID" --arg agentVersion "$AGENT_VERSION" --arg agentInstalledDateTime "$AGENT_INSTALLED_DATE" --arg timestamp "$TIMESTAMP" \
--arg deviceName "$DEVICE_NAME" --arg manufacturer "$MANUFACTURER" --arg model "$MODEL" --arg serialNumber "$SERIAL_NUMBER" --arg osName "$OS_NAME" \
--arg osVersion "$OS_VERSION" --arg osArchitecture "$OS_ARCH" --arg lastRestartedAt "$LAST_RESTARTED_AT" --argjson pendingRestart "$PENDING_RESTART" \
--arg cpuModel "$CPU_MODEL" --argjson cpuCores "$CPU_CORES" --argjson cpuClockSpeed "$CPU_CLOCK_SPEED" --argjson ramTotalGB "$RAM_TOTAL_GB" \
--arg ramType "$RAM_TYPE" --argjson storage "$STORAGE_INFO" --argjson network "$NETWORK_INTERFACES" --argjson software "$INSTALLED_SOFTWARE" \
--argjson loggedInUsers "$LOGGED_IN_USERS" --argjson runningApps "$RUNNING_APPS" --argjson customerInfo "$CUSTOMER_INFO" --arg status "$AGENT_STATUS" \
'{"agentId": $agentId, "agentVersion": $agentVersion, "agentInstalledDateTime": $agentInstalledDateTime, "timestamp": $timestamp,
  "deviceInfo": {"deviceName": $deviceName, "manufacturer": $manufacturer, "model": $model, "serialNumber": $serialNumber,
  "os": {"name": $osName, "version": $osVersion, "architecture": $osArchitecture}, "lastRestartedAt": $lastRestartedAt,
  "pendingRestart": $pendingRestart, "hardwareSpecs": {"cpu": {"model": $cpuModel, "cores": ($cpuCores | tonumber), "clockSpeedGHz": ($cpuClockSpeed | tonumber)},
  "ram": {"totalGB": ($ramTotalGB | tonumber), "type": $ramType}, "storage": $storage, "networkInterfaces": $network}}, "softwareInfo": $software, "loggedInUsers": $loggedInUsers, "runningApplications": $runningApps, "customerInfo": $customerInfo, "status": $status}')

echo "$JSON_OUTPUT" | jq . > agent_report.json
