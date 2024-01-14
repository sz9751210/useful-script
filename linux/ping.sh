#!/bin/bash

ping_ip() {
    local ip=$1
    local count=$2
    echo "Pinging $ip..."
    ping -c "$count" -W 1 "$ip" &> /dev/null

    if [ $? -eq 0 ]; then
        echo "Ping to $ip was successful."
        ((success_count++))
    else
        echo "Ping to $ip failed."
        ((fail_count++))
    fi
}

# List of IP addresses
ip_list=("8.8.8.8" "1.1.1.1")
ping_attempts=4
success_count=0
fail_count=0

# Ping each IP address
for ip in "${ip_list[@]}"; do
    ping_ip "$ip" "$ping_attempts"
done

# Summary report
echo "Ping summary: $success_count successful, $fail_count failed."
