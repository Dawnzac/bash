#!/bin/bash

if command -v google-chrome &> /dev/null; then
    echo "Google Chrome is already installed. Checking for updates..."
else
    echo "Google Chrome not found. Installing Google Chrome..."
fi


echo "Updating package list..."
sudo apt update -y


echo "Downloading the latest Google Chrome package..."
wget -O /tmp/google-chrome-stable_current_amd64.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb


echo "Installing Google Chrome..."
sudo apt install -y /tmp/google-chrome-stable_current_amd64.deb


if command -v google-chrome &> /dev/null; then
    echo "Google Chrome has been successfully installed or updated."
else
    echo "Failed to install Google Chrome."
    exit 1
fi

echo "Cleaning up..."
rm /tmp/google-chrome-stable_current_amd64.deb

echo "Installation script completed."
