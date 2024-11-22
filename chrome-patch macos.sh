#!/bin/bash

if [ -d "/Applications/Google Chrome.app" ]; then
    echo "Google Chrome is already installed. Checking for updates..."
else
    echo "Google Chrome not found. Installing Google Chrome..."
fi

echo "Downloading the latest Google Chrome package..."
curl -o /tmp/googlechrome.dmg -L https://dl.google.com/chrome/mac/stable/GGRO/googlechrome.dmg

echo "Mounting the .dmg file..."
hdiutil attach /tmp/googlechrome.dmg -nobrowse -quiet

echo "Copying Google Chrome to the Applications folder..."
cp -r /Volumes/Google\ Chrome/Google\ Chrome.app /Applications/

echo "Unmounting the .dmg file..."
hdiutil detach /Volumes/Google\ Chrome -quiet

echo "Cleaning up..."
rm /tmp/googlechrome.dmg

if [ -d "/Applications/Google Chrome.app" ]; then
    echo "Google Chrome has been successfully installed or updated."
else
    echo "Failed to install Google Chrome."
    exit 1
fi

echo "Installation script completed."
