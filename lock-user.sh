#!/bin/bash

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root."
   exit 1
fi


echo "Setting root password..."
echo "root:secureroot" | chpasswd


echo "Disabling all users except root..."
for user in $(awk -F: '{ if ($3 >= 1000 && $1 != "root") print $1 }' /etc/passwd); do
    usermod -L $user
    echo "Disabled user: $user"
done


echo "Creating user 'exam'..."
useradd -m -s /bin/bash exam
echo "exam:123" | chpasswd

echo "User 'exam' created with password '123'."

echo "Script execution completed. Root password set to 'secureroot', other users disabled, and 'exam' user created."
