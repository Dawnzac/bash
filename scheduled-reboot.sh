#!/bin/bash

if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root."
    exit 1
fi


schedule_reboot() {
    echo "Scheduling a reboot in 5 minutes..."
    shutdown -r +5 &
    SHUTDOWN_PID=$!
    echo "Reboot scheduled in 5 minutes. PID: $SHUTDOWN_PID"
}


cancel_reboot() {
    echo "Canceling the scheduled reboot..."
    kill "$SHUTDOWN_PID" &>/dev/null
    shutdown -c &>/dev/null
    echo "Scheduled reboot canceled."
}


show_dialog() {
    if command -v zenity &> /dev/null; then
        CHOICE=$(zenity --question --title="Reboot Scheduled" \
            --text="A reboot has been scheduled in 5 minutes.\nDo you want to reboot now?" \
            --ok-label="Reboot Now" --cancel-label="Later")
        
        if [[ $? -eq 0 ]]; then
            reboot_now
        else
            echo "Reboot will occur as scheduled."
        fi
    else
        echo "A reboot has been scheduled in 5 minutes."
        echo "Do you want to reboot now? (y/N)"
        read -r response
        case "$response" in
            [Yy]*)
                reboot_now
                ;;
            *)
                echo "Reboot will occur as scheduled."
                ;;
        esac
    fi
}


reboot_now() {
    echo "Rebooting now..."
    shutdown -r now
}


schedule_reboot
show_dialog
