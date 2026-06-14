#!/bin/bash
set -euo pipefail

# Simple script to launch EnterpriseAIMetrics (kills existing instance first)
# Usage: ./Scripts/launch.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
APP_PATH="$PROJECT_ROOT/EnterpriseAIMetrics.app"

echo "==> Killing existing EnterpriseAIMetrics instances"
pkill -x EnterpriseAIMetrics || pkill -f EnterpriseAIMetrics.app || true
sleep 0.5

if [[ ! -d "$APP_PATH" ]]; then
    echo "ERROR: EnterpriseAIMetrics.app not found at $APP_PATH"
    echo "Run ./Scripts/package_app.sh first to build the app"
    exit 1
fi

echo "==> Launching EnterpriseAIMetrics from $APP_PATH"
open -n "$APP_PATH"

# Wait a moment and check if it's running
sleep 1
if pgrep -x EnterpriseAIMetrics > /dev/null; then
    echo "OK: EnterpriseAIMetrics is running."
else
    echo "ERROR: App exited immediately. Check crash logs in Console.app (User Reports)."
    exit 1
fi
