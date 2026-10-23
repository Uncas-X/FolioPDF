#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
export CLANG_MODULE_CACHE_PATH=/private/tmp/FolioPDF-module-cache
export SWIFTPM_MODULECACHE_OVERRIDE=/private/tmp/FolioPDF-module-cache
python3 scripts/check-docs.py
python3 scripts/check-localization.py
swift test --disable-sandbox --cache-path /private/tmp/FolioPDF-swiftpm-cache
