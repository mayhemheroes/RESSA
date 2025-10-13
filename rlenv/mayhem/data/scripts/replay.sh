#! /bin/bash

set -euo pipefail

if [ $# -ne 1 ]; then
    echo "Usage: $0 [FILE]"
    exit 1
fi

RUST_BACKTRACE=1 /ressa-fuzz $1