#!/bin/bash

# Build script for Discord.gd GDExtension
# Automatically uses all CPU cores minus one for compilation

set -e

# Calculate number of cores to use (all cores - 1, minimum 1)
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    TOTAL_CORES=$(sysctl -n hw.ncpu)
else
    # Linux
    TOTAL_CORES=$(nproc)
fi

CORES_TO_USE=$((TOTAL_CORES - 1))
if [ "$CORES_TO_USE" -lt 1 ]; then
    CORES_TO_USE=1
fi

echo "Building with $CORES_TO_USE cores (total: $TOTAL_CORES)"

# Create build directory if it doesn't exist
mkdir -p build
cd build

# Configure with CMake
echo "Configuring..."
cmake ..

# Build with parallel jobs
echo "Building..."
cmake --build . -j $CORES_TO_USE

echo "Build complete! Library is in build/bin/"