#!/bin/bash -x

# A script to create a read-only .dmg (disk image) file containing a .pkg (package) installer on macOS.
create_bundle_pkg() {
# Variables
output_pkg="/tmp/output_bundle.pkg"

# Prompt user for the directory containing the necessary files
read -p "Enter the path to the directory containing the install script, site token file, and EDR agent installer package: " dir_path

# Set file paths
install_script_path="$dir_path/SentinelOneInstallerHelper"
site_token_file="$dir_path/com.sentinelone.registration-token"
edr_agent_pkg=$(find "$dir_path" -type f -iname "*.pkg" -print -quit)

# Create a temporary working directory
tmp_dir=$(mktemp -d)
mkdir "$tmp_dir/Scripts"



# Copy the install script and site token file to the temporary directory
cp "$install_script_path" "$tmp_dir/Scripts/preinstall"
cp "$site_token_file" "$tmp_dir/Scripts/com.sentinelone.registration-token"
cp "$edr_agent_pkg" "$tmp_dir/Scripts/SentinelOneAgent.pkg"
# Set the permissions for the install script
chmod +x "$tmp_dir/Scripts/preinstall"

# Create a package containing the install script and site token
pkgbuild --nopayload --identifier com.sentinelOne.pkg.S1-v231-Installer --version 23.1 --scripts "$tmp_dir/Scripts" --install-location /Library "$output_pkg"
# Clean up the temporary directory
rm -rf "$tmp_dir"

echo "Package created: $output_pkg"
}

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

  echo "pkg_size: $pkg_size"
  echo "dmg_size: $dmg_size"
  echo "dmg_name: $dmg_name"

  # Create the .dmg image with the required size and format
  set -x
  hdiutil create -fs HFS+J -layout CD -size "${dmg_size}m" -volname "${dmg_name%.*}" "$dmg_name"
  set +x
}

# Function to copy the .pkg installer to the .dmg image
copy_pkg_to_dmg() {
  # Attempt to mount the .dmg image with the given filename
  echo "Trying to mount $dmg_name..."
  if hdiutil attach "$dmg_name"; then
    echo "Mounted $dmg_name successfully."
  else
    # If the mount fails, try appending ".dmg" to the filename and try again
    echo "Mounting $dmg_name failed. Trying $dmg_name.dmg..."
    if hdiutil attach "$dmg_name.dmg"; then
      echo "Mounted $dmg_name.dmg successfully."
    else
      # If both attempts fail, output an error message and exit
      echo "Error: Unable to mount $dmg_name or $dmg_name.dmg"
      exit 1
    fi
  fi

    # Copy the .pkg installer to the .dmg image
  if cp "$pkg_path" "/Volumes/${dmg_name%.*}"; then
    echo "Copied $pkg_path to $dmg_name successfully."
  else
    echo "Error: Unable to copy $pkg_path to $dmg_name"
    exit 1
  fi


}

# Function to finalize the .dmg image
finalize_dmg() {
  # Attempt to unmount the .dmg image with the given filename
  echo "Trying to unmount $dmg_name..."
  if hdiutil detach "/Volumes/${dmg_name%.*}" -quiet; then
    echo "Unmounted $dmg_name successfully."
  else
    # If the unmount fails, try appending ".dmg" to the filename and try again
    echo "Unmounting $dmg_name failed."
    exit 1
  fi

  # Check if the .dmg extension is present in the filename
  if [[ "$dmg_name" == *.dmg ]]; then
    # If the .dmg extension is present, use the filename as is
    echo "Converting $dmg_name to read-only format..."
    if hdiutil convert "$dmg_name" -format UDZO -o "$dmg_name-ro.dmg"; then
      echo "Conversion of $dmg_name to read-only format succeeded."
    else
      echo "Error: Conversion of $dmg_name to read-only format failed."
      exit 1
    fi
  else
    # If the .dmg extension is not present, append it to the filename before converting
    echo "Converting $dmg_name to read-only format..."
    if hdiutil convert "$dmg_name.dmg" -format UDZO -o "$dmg_name-ro.dmg"; then
      echo "Conversion of $dmg_name to read-only format succeeded."
    else
      echo "Error: Conversion of $dmg_name to read-only format failed."
      exit 1
    fi
  fi
}


# Main function
main() {
  # Make the first script executable and run it
  # chmod +x create_bundle_pkg.sh
  # ./create_bundle_pkg.sh
  create_bundle_pkg
  # Set the path to the output .pkg file from the first script
  pkg_path="/tmp/output_bundle.pkg"

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
