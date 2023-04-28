#!/bin/bash

# A script to create a read-only .dmg (disk image) file containing a .pkg (package) installer on macOS.

# Function to get input from the user
get_input() {
  # Check if the required arguments were passed as xargs
  if [ $# -ne 2 ]; then
    # Prompt the user for the name of the .dmg image and the path to the .pkg installer
    read -p "Enter the name of the .dmg image: " dmg_name
    read -p "Enter the path to the .pkg installer: " pkg_path
  else
    # Set the variables from the xargs
    dmg_name="$1"
    pkg_path="$2"
  fi

  # Check if the required arguments were provided
  if [[ -z "$dmg_name" || -z "$pkg_path" ]]; then
    echo "Error: You must provide a name for the .dmg image and the path to the .pkg installer."
    return 1
  fi

  return 0
}

# Function to create the .dmg image
create_dmg() {
  # Calculate the required size of the .dmg image
  pkg_size=$(du -sm "$pkg_path" | cut -f1)
  dmg_size=$((pkg_size * 2))

  # Create the .dmg image with the required size and format
  hdiutil create -fs HFS+J -layout CD -size "${dmg_size}m" -volname "${dmg_name%.*}" "$dmg_name"
}

# Function to copy the .pkg installer to the .dmg image
copy_pkg_to_dmg() {
  # Mount the .dmg image
  hdiutil attach "$dmg_name"

  # Copy the .pkg installer to the .dmg image
  cp "$pkg_path" "/Volumes/${dmg_name%.*}"
}

# Function to finalize the .dmg image
finalize_dmg() {
  # Unmount the .dmg image
  hdiutil detach "/Volumes/${dmg_name%.*}" -quiet

  # Convert the .dmg image to read-only format
  hdiutil convert "$dmg_name" -format UDZO -o "$dmg_name"
}

# Main function
main() {
  get_input "$@"
  if [ $? -ne 0 ]; then
    exit 1
  fi

  create_dmg
  copy_pkg_to_dmg
  finalize_dmg
}

# Call the main function
main "$@"
