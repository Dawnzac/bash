#!/bin/bash

CHROME_BINARY="/usr/bin/google-chrome"

if [ ! -f "$CHROME_BINARY" ]; then
    echo "Google Chrome binary not found at $CHROME_BINARY. Exiting."
    exit 1
fi

echo "Enabling Google Chrome..."
sudo chmod +x "$CHROME_BINARY"

if [ -x "$CHROME_BINARY" ]; then
    echo "Google Chrome has been enabled. It can now be executed."
else
    echo "Failed to enable Google Chrome."
    exit 1
fi

echo "Script completed."
