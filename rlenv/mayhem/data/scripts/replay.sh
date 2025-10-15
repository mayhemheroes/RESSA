#! /bin/bash

set -euo pipefail

if [ $# -ne 1 ]; then
    echo "Usage: $0 [FILE]"
    exit 1
fi

export ASAN_OPTIONS=symbolize=0:print_stacktrace=0 

/ressa-fuzz $1
