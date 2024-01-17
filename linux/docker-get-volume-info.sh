#!/bin/bash

# Function to get volume details
get_volume_info() {
    volume_name=$1

    # Get volume size
    volume_size=$(docker run --rm -v ${volume_name}:/volume_data alpine sh -c "du -sh /volume_data | cut -f1")

    # Get connected containers
    connected_containers=$(docker ps --filter volume=$volume_name --format "{{.Names}}")

    # Inspect volume for additional details
    volume_inspection=$(docker volume inspect $volume_name)
    volume_driver=$(echo "$volume_inspection" | jq -r '.[0].Driver')
    volume_mountpoint=$(echo "$volume_inspection" | jq -r '.[0].Mountpoint')

    # Approximate volume creation date
    volume_creation_date=$(stat -c %y "$volume_mountpoint" 2>/dev/null | cut -d' ' -f1)

    # Fallback messages
    [ -z "$connected_containers" ] && connected_containers="None"
    [ -z "$volume_creation_date" ] && volume_creation_date="Unknown"

    # Prepare tab-delimited output
    echo -e "$volume_name\t$volume_size\t$connected_containers\t$volume_driver\t$volume_creation_date"
}

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "Docker is not running. Please start Docker and try again."
    exit 1
fi

# Check for jq
if ! command -v jq > /dev/null 2>&1; then
    echo "jq is not installed. Please install jq and try again."
    exit 1
fi

echo -e "Volume Name\tVolume Size\tConnected Containers\tVolume Driver\tCreation Date"
echo "-----------------------------------------------------------------------------------"

# List all Docker volumes, get details, and format output
docker volume ls -q | while read volume; do
    get_volume_info "$volume"
done | column -t -s $'\t'
