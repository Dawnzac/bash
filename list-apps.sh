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

list_with_apt() {
    echo "Fetching installed packages and updates (apt)..."
    echo "---------------------------------------------"

    echo "Installed Applications:"
    dpkg -l | awk '/^ii/ {print $2, $3}' | column -t

    echo ""
    echo "Available Updates:"
    apt list --upgradable 2>/dev/null | grep -v "Listing"
}

list_with_yum() {
    echo "Fetching installed packages and updates (yum)..."
    echo "-----------------------------------------------"

    echo "Installed Applications:"
    yum list installed | awk '{print $1, $2}' | column -t

    echo ""
    echo "Available Updates:"
    yum list updates 2>/dev/null
}

list_with_dnf() {
    echo "Fetching installed packages and updates (dnf)..."
    echo "-----------------------------------------------"

    echo "Installed Applications:"
    dnf list installed | awk '{print $1, $2}' | column -t

    echo ""
    echo "Available Updates:"
    dnf list updates 2>/dev/null
}

detect_package_manager

case $PACKAGE_MANAGER in
    apt)
        list_with_apt
        ;;
    yum)
        list_with_yum
        ;;
    dnf)
        list_with_dnf
        ;;
esac

#to save it as text ./list-apps > applist.txt