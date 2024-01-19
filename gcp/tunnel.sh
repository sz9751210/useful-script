#!/bin/bash

# Function to validate non-empty input
validate_input() {
    if [[ -z "$1" ]]; then
        echo "Input cannot be empty. Please try again."
        return 1
    fi
    return 0
}

echo "GCloud Compute Command Generator"

# Prompt for Project ID with validation
while true; do
    echo -n "Enter Project ID: "
    read project_id
    validate_input "$project_id" && break
done

# Prompt for VM Name with validation
while true; do
    echo -n "Enter VM Name: "
    read vm_name
    validate_input "$vm_name" && break
done

# Prompt for Local Port with validation
while true; do
    echo -n "Enter Local Port: "
    read local_port
    validate_input "$local_port" && break
done

# Prompt for Target Port with validation
while true; do
    echo -n "Enter Target Port: "
    read target_port
    validate_input "$target_port" && break
done

# Optional: Prompt for Zone with default value
echo -n "Enter Zone (default: asia-east1-b): "
read zone
zone=${zone:-asia-east1-b}

# Combine into gcloud compute command
gcloud_command="gcloud compute start-iap-tunnel --project $project_id --zone $zone --local-host-port 127.0.0.1:$local_port $vm_name $target_port"

# Print the command
echo "Generated gcloud command:"
echo "$gcloud_command"

# Ask to execute the command
echo -n "Do you want to execute this command? (y/n): "
read execute_answer
if [[ $execute_answer == "y" || $execute_answer == "Y" ]]; then
    eval $gcloud_command
fi

# Ask to store the command
echo -n "Do you want to store this command? (y/n): "
read store_answer
if [[ $store_answer == "y" || $store_answer == "Y" ]]; then
    echo -n "Enter filename to store the command (default: gcloud_command.txt): "
    read filename
    filename=${filename:-gcloud_command.txt}
    echo "$gcloud_command" > "$filename"
    echo "Command stored in file: $filename"
fi
