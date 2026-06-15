#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
APP_BUNDLE="${1:-$ROOT/EnterpriseAIMetrics.app}"
DMG_NAME="${2:-EnterpriseAIMetrics.dmg}"
VOLUME_NAME="${3:-EnterpriseAIMetrics}"

if [[ ! -d "$APP_BUNDLE" ]]; then
  echo "ERROR: Missing app bundle at: $APP_BUNDLE" >&2
  exit 1
fi

TEMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/enterpriseaimetrics-dmg.XXXXXX")
STAGE_DIR="$TEMP_DIR/stage"
trap 'rm -rf "$TEMP_DIR"' EXIT

mkdir -p "$STAGE_DIR"
cp -R "$APP_BUNDLE" "$STAGE_DIR/"
ln -s /Applications "$STAGE_DIR/Applications"

if [[ -e "$DMG_NAME" ]]; then
  rm -f "$DMG_NAME"
fi

hdiutil create \
  -volname "$VOLUME_NAME" \
  -srcfolder "$STAGE_DIR" \
  -ov \
  -format UDZO \
  "$DMG_NAME"

echo "Created $DMG_NAME"
