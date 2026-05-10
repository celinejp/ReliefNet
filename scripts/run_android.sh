#!/usr/bin/env bash
# Run ReliefNet on an Android device/emulator with Auth0 + API dart-defines.
#
# Usage:
#   ./scripts/run_android.sh [flutter_device_id] [extra flutter args...]
# Example:
#   ./scripts/run_android.sh emulator-5554
#   API_BASE_URL=http://10.0.2.2:3000 ./scripts/run_android.sh
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

API_BASE_URL="${API_BASE_URL:-http://144.202.115.202:3000}"
HUB_BASE_URL="${HUB_BASE_URL:-http://192.168.137.1:3001}"
AUTH0_DOMAIN="${AUTH0_DOMAIN:-dev-vbjhh7iok0ix176c.us.auth0.com}"
AUTH0_CLIENT_ID="${AUTH0_CLIENT_ID:-twxAyZTvWuYuqQKFf9MgCNtEJGhEhJy7}"
AUTH0_AUDIENCE="${AUTH0_AUDIENCE:-https://reliefnet-api}"
AUTH0_SCHEME="${AUTH0_SCHEME:-reliefnet}"

DEVICE="${1:-}"
if [[ -n "${DEVICE:-}" ]]; then
  shift
fi

flutter pub get

DEFINES=(
  --dart-define=API_BASE_URL="$API_BASE_URL"
  --dart-define=HUB_BASE_URL="$HUB_BASE_URL"
  --dart-define=AUTH0_DOMAIN="$AUTH0_DOMAIN"
  --dart-define=AUTH0_CLIENT_ID="$AUTH0_CLIENT_ID"
  --dart-define=AUTH0_AUDIENCE="$AUTH0_AUDIENCE"
  --dart-define=AUTH0_SCHEME="$AUTH0_SCHEME"
)

if [[ -n "${DEVICE:-}" ]]; then
  exec flutter run -d "$DEVICE" "${DEFINES[@]}" "$@"
fi

echo "Pick a device:"
flutter devices
echo ""
echo "Then: ./scripts/run_android.sh <device_id>"
