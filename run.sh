#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

if [[ ! -d app/.dart_tool ]]; then
  ./install.sh
fi

mkdir -p app/assets/config app/assets/data
cp -f config/sources.yaml app/assets/config/sources.yaml
cp -f data/snapshot.json app/assets/data/snapshot.json

cd app
if flutter devices 2>/dev/null | grep -q macos; then
  flutter run -d macos
else
  flutter run
fi
