#!/bin/bash

# Check if Docker is installed and running
if ! [ -x "$(command -v docker)" ]; then
  echo "Error: Docker is not installed." >&2
  exit 1
fi

if ! docker info > /dev/null 2>&1; then
  echo "Error: Docker is not running." >&2
  exit 1
fi

echo "Docker is installed and running."

# Get a list of Docker volumes
echo "Fetching Docker volumes..."
volume_list=$(docker volume ls -q)
if [ -z "$volume_list" ]; then
  echo "No Docker volumes found."
  exit 1
fi

# Display a selection menu for Docker volumes
echo "Please select a Docker volume:"
select volume_name in $volume_list; do
  if [ -n "$volume_name" ]; then
    echo "Selected volume: $volume_name"
    break
  else
    echo "Invalid selection. Please try again."
  fi
done

# Ask for base directory path
read -p "Enter base directory path where the volume folder will be created: " base_dir

# Create target folder path from volume name
target_folder="$base_dir/$volume_name"

# Check if the target folder exists, if not, create it
if [ ! -d "$target_folder" ]; then
  echo "Target folder does not exist. Creating it at '$target_folder'..."
  mkdir -p "$target_folder"
fi

# Creating a temporary container to access the volume
temp_container="temp-$(date +%s)"
docker run --name $temp_container -v $volume_name:/volume_data busybox

# Copying data from the volume to the target folder
docker cp $temp_container:/volume_data/. $target_folder

# Removing the temporary container
docker rm $temp_container

echo "Volume '$volume_name' has been successfully copied to '$target_folder'."
