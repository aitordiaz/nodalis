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

if command -v docker &>/dev/null && docker info &>/dev/null; then
  echo "Starting via Docker Compose (accessible from Windows host at http://localhost:$PORT)..."
  (cd "$ROOT_DIR" && docker compose up -d)
  echo "Web container is running. Open http://localhost:$PORT in your Windows browser."
  echo "To view logs: docker compose logs -f"
  echo "To stop:      docker compose down"
else
  echo "Press Ctrl+C to stop."
  python3 -m http.server "$PORT" -d "$WEB_DIR"
fi
