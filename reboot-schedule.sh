#!/bin/bash

if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root."
    exit 1
fi

schedule_reboot() {
    local reboot_time
    echo "Enter the time to schedule the reboot (HH:MM, 24-hour format):"
    read -r reboot_time

    if [[ ! "$reboot_time" =~ ^([01]?[0-9]|2[0-3]):[0-5][0-9]$ ]]; then
        echo "Invalid time format. Please enter time as HH:MM."
        exit 1
    fi

    echo "Scheduling reboot at $reboot_time..."
    echo "shutdown -r $reboot_time" | at "$reboot_time" 2>/dev/null
    if [[ $? -eq 0 ]]; then
        echo "Reboot scheduled successfully for $reboot_time."
    else
        echo "Failed to schedule reboot. Ensure the 'at' service is installed and running."
    fi
}

reboot_now() {
    echo "Rebooting the system now..."
    reboot
}

main() {
    # Check if Zenity is available
    if command -v zenity &> /dev/null; then
        choice=$(zenity --list --title="Reboot Options" \
            --column="Action" --text="Choose an action:" \
            "Reboot Now" "Schedule Reboot" "Cancel")
    else
        echo "Choose an action:"
        echo "1) Reboot Now"
        echo "2) Schedule Reboot"
        echo "3) Cancel"
        read -r choice
    fi

    case $choice in
        "Reboot Now"|"1")
            reboot_now
            ;;
        "Schedule Reboot"|"2")
            schedule_reboot
            ;;
        "Cancel"|"3"|"")
            echo "No action taken. Exiting."
            exit 0
            ;;
        *)
            echo "Invalid choice. Exiting."
            exit 1
            ;;
    esac
}

main
