#!/bin/bash
# 記号の検討用の画像を作り直して開く。docs/symbols.png と docs/badge.png ができる。
set -euo pipefail

cd "$(dirname "$0")"
mkdir -p build docs

swiftc -O -target arm64-apple-macos14.0 -framework AppKit \
  -o build/mockup Tools/mockup/main.swift

./build/mockup docs
open docs/symbols.png docs/badge.png
