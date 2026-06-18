#!/bin/bash
# QA Genie production build
# Usage: ./build_prod.sh [apk|appbundle]

set -e

MODE="${1:-apk}"

if [ "$MODE" = "appbundle" ]; then
  flutter build appbundle --release --flavor prod --dart-define=MODE=prod
else
  flutter build apk --release --flavor prod --dart-define=MODE=prod
fi

echo "✅ Prod build complete"
