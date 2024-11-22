#!/bin/bash

if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root."
    exit 1
fi

if [[ -z "$1" ]]; then
    echo "Usage: $0 <application-name>"
    exit 1
fi

APPLICATION_NAME="$1"

echo "Finding services related to '$APPLICATION_NAME'..."
SERVICES=$(systemctl list-units --type=service --all | grep "$APPLICATION_NAME" | awk '{print $1}')

if [[ -z "$SERVICES" ]]; then
    echo "No services found related to '$APPLICATION_NAME'."
    exit 0
fi

echo "Stopping the following services:"
echo "$SERVICES"

for SERVICE in $SERVICES; do
    echo "Stopping $SERVICE..."
    systemctl stop "$SERVICE"
    if [[ $? -eq 0 ]]; then
        echo "$SERVICE stopped successfully."
    else
        echo "Failed to stop $SERVICE. Check the service status for details."
    fi
done

echo "All services related to '$APPLICATION_NAME' have been processed."

#./stop-app-service.sh apache
#systemctl list-units --type=service | grep <application-name>  #to verify if needed
