#!/bin/bash

if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root."
    exit 1
fi

detect_package_manager() {
    if command -v apt &> /dev/null; then
        PACKAGE_MANAGER="apt"
    elif command -v yum &> /dev/null; then
        PACKAGE_MANAGER="yum"
    elif command -v dnf &> /dev/null; then
        PACKAGE_MANAGER="dnf"
    else
        echo "No supported package manager found. Exiting."
        exit 1
    fi
}

update_with_apt() {
    echo "Updating package list..."
    apt update -y

    echo "Checking for available updates..."
    UPGRADABLE=$(apt list --upgradable 2>/dev/null | grep -v "Listing" | wc -l)
    
    if [[ $UPGRADABLE -gt 0 ]]; then
        echo "There are $UPGRADABLE packages available for update."
        echo "Downloading and installing updates..."
        apt upgrade -y
        echo "All updates have been installed successfully."
    else
        echo "Your system is up-to-date."
    fi
}

update_with_yum_or_dnf() {
    echo "Checking for available updates..."
    $PACKAGE_MANAGER check-update -q
    if [[ $? -eq 100 ]]; then
        echo "Updates are available."
        echo "Downloading and installing updates..."
        $PACKAGE_MANAGER upgrade -y
        echo "All updates have been installed successfully."
    else
        echo "Your system is up-to-date."
    fi
}

detect_package_manager

case $PACKAGE_MANAGER in
    apt)
        update_with_apt
        ;;
    yum|dnf)
        update_with_yum_or_dnf
        ;;
esac


read -p "Some updates may require a reboot. Reboot now? (y/N): " response
if [[ "$response" =~ ^[Yy]$ ]]; then
    reboot
fi
