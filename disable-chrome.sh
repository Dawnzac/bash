#!/bin/bash

CHROME_BINARY="/usr/bin/google-chrome"

if [ ! -f "$CHROME_BINARY" ]; then
    echo "Google Chrome binary not found at $CHROME_BINARY. Exiting."
    exit 1
fi

echo "Stopping all running instances of Google Chrome..."
pkill -f "$CHROME_BINARY"

echo "Disabling Google Chrome..."
sudo chmod -x "$CHROME_BINARY"

if [ ! -x "$CHROME_BINARY" ]; then
    echo "Google Chrome has been disabled. It cannot be executed until re-enabled."
else
    echo "Failed to disable Google Chrome."
    exit 1
fi

echo "Script completed."
