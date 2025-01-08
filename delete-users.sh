#!/bin/bash

# Define the username and password for the new user
NEW_USER="Exam 2025"
PASSWORD="2025"

# Create the new user "Exam 2025" with password
echo "Creating user $NEW_USER with password $PASSWORD..."
sudo useradd -m -s /bin/bash "$NEW_USER"
echo "$NEW_USER:$PASSWORD" | sudo chpasswd

# Loop through all the users and delete every other user
echo "Deleting every other user..."
i=0
for USER in $(cut -d: -f1 /etc/passwd); do
    if [[ "$USER" != "root" && "$USER" != "$NEW_USER" && $(($i % 2)) -eq 0 ]]; then
        echo "Deleting user $USER and their files..."
        sudo userdel -r "$USER"
    fi
    i=$((i + 1))
done

echo "User deletion complete and new user $NEW_USER created successfully."