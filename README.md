# macOS DMG Creator

This is a Bash script that creates a read-only .dmg (disk image) file containing a .pkg (package) installer on macOS. It 
can be used to easily distribute and install applications on macOS systems.

## Usage

To use the script, you can either pass the required arguments (the .dmg image name and the .pkg installer path) when 
running the script, or you can run the script without arguments and it will prompt you to enter the necessary information.

### Without Arguments
```bash
./create_dmg_with_bundle_pkg.sh
```

## Dependencies

This script relies on the following macOS utilities:

- `hdiutil`: a command-line utility to create, manipulate, and convert disk images
- `du`: a command-line utility to estimate file space usage
- `cut`: a command-line utility to remove sections from each line of files

Make sure your macOS system has these utilities installed before running the script.

## License

This script is released under the MIT License. See the [LICENSE](LICENSE) file for more information.







