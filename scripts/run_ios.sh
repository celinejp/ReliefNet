#!/usr/bin/env bash
# Builds & runs ReliefNet on a physical iPhone from the CURRENT git branch.
# Passes --dart-define=BUILD_LABEL=<branch>@<sha> (debug banner on home).
# Also passes Auth0 + API defaults (override API_BASE_URL via env if needed).
#
# Usage:
#   ./scripts/run_ios.sh <flutter_device_id> [extra flutter args...]
# Example:
#   ./scripts/run_ios.sh 00008120-00186D693A43A01E
#   API_BASE_URL=http://127.0.0.1:3000 ./scripts/run_ios.sh 00008120-00186D693A43A01E
#
# Typical flow on main:
#   git switch main && git pull
#   flutter devices
#   ./scripts/run_ios.sh <device_id>
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

# ReliefNet production API on VPS (override: export API_BASE_URL=... before running).
API_BASE_URL="${API_BASE_URL:-http://144.202.115.202:3000}"
AUTH0_DOMAIN="${AUTH0_DOMAIN:-dev-vbjhh7iok0ix176c.us.auth0.com}"
AUTH0_CLIENT_ID="${AUTH0_CLIENT_ID:-twxAyZTVWuYuqQKFf9MgCNtEJGhEhJy7}"
AUTH0_AUDIENCE="${AUTH0_AUDIENCE:-https://reliefnet-api}"
AUTH0_SCHEME="${AUTH0_SCHEME:-reliefnet}"

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
  exec flutter run -d "$DEVICE" \
    --dart-define=BUILD_LABEL="$LABEL" \
    --dart-define=API_BASE_URL="$API_BASE_URL" \
    --dart-define=AUTH0_DOMAIN="$AUTH0_DOMAIN" \
    --dart-define=AUTH0_CLIENT_ID="$AUTH0_CLIENT_ID" \
    --dart-define=AUTH0_AUDIENCE="$AUTH0_AUDIENCE" \
    --dart-define=AUTH0_SCHEME="$AUTH0_SCHEME" \
    "$@"
fi

echo "Pick a device:"
flutter devices
echo ""
echo "Then run: ./scripts/run_ios.sh <device_id>"
echo "(Optional: API_BASE_URL=http://host:3000 ./scripts/run_ios.sh <device_id>)"
