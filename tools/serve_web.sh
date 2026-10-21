#!/usr/bin/env bash
set -e

PORT="${1:-8080}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WEB_DIR="$ROOT_DIR/apps/nodalis_app/build/web"

if [ ! -d "$WEB_DIR" ] || [ "$2" == "--build" ]; then
  echo "Building web bundle..."
  export PATH="$HOME/.local/flutter/bin:$PATH"
  (cd "$ROOT_DIR/apps/nodalis_app" && flutter build web --no-pub)
fi

echo "================================================="
echo " Nodalis Web Server running at:"
echo "   http://localhost:$PORT"
echo "================================================="
echo "Press Ctrl+C to stop."

python3 -m http.server "$PORT" -d "$WEB_DIR"
