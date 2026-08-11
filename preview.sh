#!/bin/bash
# 絵をメニューバーの実寸で確かめる。docs/preview.png ができて開く。
#
#   ./preview.sh Resources/konechi-default.png
set -euo pipefail

cd "$(dirname "$0")"
mkdir -p build docs

swiftc -O -target arm64-apple-macos14.0 -framework AppKit \
  -o build/preview Tools/preview/main.swift

./build/preview "$@"
open docs/preview.png
