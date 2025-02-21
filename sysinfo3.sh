#!/bin/bash

readarray -t array <<< "$(df -h)";
var=$(echo "${array[1]}"| grep -aob '%' | grep -oE '[0-9]+');
df_output="${array[3]:$var-3:4}";

manufacturer=$(cat /sys/class/dmi/id/chassis_vendor);
product_name=$(cat /sys/class/dmi/id/product_name);
version=$(cat /sys/class/dmi/id/bios_version);
serial_number=$(cat /sys/class/dmi/id/product_serial);
hostname=$(hostname);
operating_system=$(hostnamectl | grep "Operating System" | cut -d ' ' -f5-);
architecture=$(arch);
processor_name=$(awk -F':' '/^model name/ {print $2}' /proc/cpuinfo | uniq | sed -e 's/^[ \t]*//');
memory$(dmidecode -t 17 | grep "Size.*MB" | awk '{s+=$2} END {print s / 1024"GB"}');
hdd_model=$(cat /sys/block/sda/device/model);
system_main_ip=$(hostname -I);

printf '{"manufacturer":"%s","product_name":"%s","version":"%s","serial_number":"%s","hostname":"%s","operating_system":"%s","architecture":"%s","processor_name":"%s","memory":"%s","hdd_model":"%s","system_main_ip":"%s"}' "$manufacturer" "$product_name" "$version" "$serial_number" "$hostname" "$operating_system" "$architecture" "$processor_name" "$memory" "$hdd_model" "$system_main_ip"