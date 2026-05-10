#!/usr/bin/env bash
# Builds & runs ReliefNet on a physical iPhone from the CURRENT git branch.
# Passes --dart-define=BUILD_LABEL=<branch>@<sha> (debug banner on home).
#
# Usage:
#   ./scripts/run_ios.sh <flutter_device_id> [extra flutter args...]
# Example:
#   ./scripts/run_ios.sh 00008120-00186D693A43A01E --dart-define=API_BASE_URL=http://203.0.113.10:3000
#
# Typical flow on main:
#   git switch main && git pull
#   flutter devices
#   ./scripts/run_ios.sh <device_id> [--dart-define=API_BASE_URL=...]
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

DEVICE="${1:-}"
if [[ -n "${DEVICE:-}" ]]; then
  shift
fi

BR="$(git branch --show-current)"
SH="$(git rev-parse --short HEAD)"
LABEL="${BR}@${SH}"

echo "Branch: $BR  commit: $SH  BUILD_LABEL=$LABEL"

flutter clean
flutter pub get
( cd ios && pod install )

if [[ -n "${DEVICE:-}" ]]; then
  exec flutter run -d "$DEVICE" --dart-define=BUILD_LABEL="$LABEL" "$@"
fi

echo "Pick a device:"
flutter devices
echo ""
echo "Then run: ./scripts/run_ios.sh <device_id> [--dart-define=API_BASE_URL=http://host:3000]"
