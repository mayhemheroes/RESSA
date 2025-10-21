#! /bin/bash

set -euo pipefail

if [ $# -ne 1 ]; then
    echo "Usage: $0 [FILE]"
    exit 1
fi

export ASAN_OPTIONS=symbolize=0:print_stacktrace=0

# Disable ASLR for reproducible crashes
# setarch -R disables address space randomization
setarch $(uname -m) -R /ressa-fuzz $1
