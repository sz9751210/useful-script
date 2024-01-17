#!/bin/bash

# Function to get volume details
get_volume_info() {
    volume_name=$1

    # Get volume size by running a temporary Alpine container
    volume_size=$(docker run --rm -v ${volume_name}:/volume_data alpine sh -c "du -sh /volume_data | cut -f1")

    # Get connected containers
    connected_containers=$(docker ps --filter volume=$volume_name --format "{{.Names}}")

    # Fallback message if no containers are connected
    if [ -z "$connected_containers" ]; then
        connected_containers="None"
    fi

    # Display information
    echo "Volume Name: $volume_name"
    echo "Volume Size: $volume_size"
    echo "Connected Containers: $connected_containers"
    echo "-------------------------"
}

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "Docker is not running. Please start Docker and try again."
    exit 1
fi

# List all Docker volumes and iterate over each volume
docker volume ls -q | while read volume; do
    get_volume_info "$volume"
done
