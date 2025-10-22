#!/bin/bash
set -euo pipefail

# RLENV Build Script
# This script rebuilds the application from source located at /rlenv/source/ressa/
#
# Original image: ghcr.io/mayhemheroes/ressa:master
# Git revision: 58806aee2ab2df5a7d7ec5daf32112e700affc7a

# Change to the source directory
cd /rlenv/source/ressa

# Navigate to fuzz directory
cd fuzz

# Build the fuzz target using cargo-fuzz in development mode (unoptimized)
# This helps trigger stack exhaustion bugs by using larger stack frames
echo "Building fuzz target with cargo +nightly fuzz build --dev..."
cargo +nightly fuzz build --dev

# Copy the built fuzz binary to the expected location
echo "Copying fuzz binary to /ressa-fuzz..."
# Note: --dev builds to debug directory instead of release
# Use cat for busybox compatibility when we can't remove the file
cat /rlenv/source/ressa/fuzz/target/x86_64-unknown-linux-gnu/debug/ressa-fuzz > /ressa-fuzz

# Verify build artifacts exist
if [ ! -f /ressa-fuzz ]; then
    echo "Error: Build artifact /ressa-fuzz not found"
    exit 1
fi

echo "Build completed successfully!"
echo "Fuzz binary location: /ressa-fuzz"
