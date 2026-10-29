#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

command -v flutter >/dev/null
command -v dart >/dev/null

mkdir -p app/assets/config app/assets/data app/assets/icons
cp -f config/sources.yaml app/assets/config/sources.yaml
cp -f data/snapshot.json app/assets/data/snapshot.json

(cd packages/news_core && dart pub get)
(cd tools/aggregator && dart pub get)
(cd app && flutter pub get)

echo "[OK] Dependencies installed."
