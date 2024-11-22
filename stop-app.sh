#!/bin/bash

if [[ $EUID -ne 0 ]]; then
    echo "This script is more effective when run as root."
    echo "You may encounter permission issues for some processes."
fi


if [[ -z "$1" ]]; then
    echo "Usage: $0 <application-name>"
    exit 1
fi

APPLICATION_NAME="$1"

echo "Searching for processes related to '$APPLICATION_NAME'..."
PIDS=$(pgrep -f "$APPLICATION_NAME")

if [[ -z "$PIDS" ]]; then
    echo "No running processes found for '$APPLICATION_NAME'."
    exit 0
fi

echo "Found the following process IDs (PIDs) for '$APPLICATION_NAME':"
echo "$PIDS"

for PID in $PIDS; do
    echo "Stopping process with PID $PID..."
    kill -9 "$PID" 2>/dev/null
    if [[ $? -eq 0 ]]; then
        echo "Process $PID stopped successfully."
    else
        echo "Failed to stop process $PID. It may require elevated permissions."
    fi
done

echo "All processes related to '$APPLICATION_NAME' have been stopped."
