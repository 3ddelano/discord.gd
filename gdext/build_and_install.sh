#!/bin/bash

# Helper build & install script for Discord.gd GDExtension
# Builds the extension and installs it to the local sample project

set -e

echo "Building extension..."
./build.sh

echo "Installing to sample project..."
cd build
cmake --install . --prefix ../../sample

echo "Installation complete! The extension is now available in the sample project."

/Applications/Godot.app/Contents/MacOS/Godot -e --path $PWD/../../sample