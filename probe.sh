#!/bin/bash
# 判定ロジックを端末から確かめる。アプリと同じ Sources/Link.swift を使う。
#
#   ./probe.sh          いまの主経路
#   ./probe.sh en0 en9  指定したデバイスの種別だけを引く
set -euo pipefail

cd "$(dirname "$0")"
mkdir -p build

swiftc -O -target arm64-apple-macos14.0 -framework SystemConfiguration \
  -o build/probe Sources/Link.swift Tools/probe/main.swift

./build/probe "$@"
