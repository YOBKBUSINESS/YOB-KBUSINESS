#!/bin/bash
# ──────────────────────────────────────────────────────────────
# YOB K Business — Local development launcher
# Usage: ./start.sh [--no-flutter] [--target chrome|macos|ios|android]
# ──────────────────────────────────────────────────────────────

set -e

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET="chrome"
LAUNCH_FLUTTER=true

# Parse arguments
for arg in "$@"; do
  case $arg in
    --no-flutter)   LAUNCH_FLUTTER=false ;;
    --target=*)     TARGET="${arg#*=}" ;;
  esac
done

# ── Colors ──────────────────────────────────────────────────
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

log()  { echo -e "${CYAN}[YOB]${NC} $1"; }
ok()   { echo -e "${GREEN}[✓]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
err()  { echo -e "${RED}[✗]${NC} $1"; exit 1; }

# ── Cleanup on exit ─────────────────────────────────────────
cleanup() {
  echo ""
  warn "Shutting down..."
  [ -n "$API_PID" ] && kill "$API_PID" 2>/dev/null && ok "API stopped"
  [ -n "$FLUTTER_PID" ] && kill "$FLUTTER_PID" 2>/dev/null && ok "Flutter stopped"
  cd "$ROOT_DIR" && docker compose down && ok "Database stopped"
}
trap cleanup INT TERM

# ── Step 1: Check prerequisites ─────────────────────────────
log "Checking prerequisites..."

command -v docker  >/dev/null 2>&1 || err "Docker not found. Install from https://docker.com"
command -v fvm     >/dev/null 2>&1 || err "FVM not found. Install with: dart pub global activate fvm"

ok "Prerequisites OK"

# ── Step 2: Start PostgreSQL ─────────────────────────────────
log "Starting PostgreSQL..."
cd "$ROOT_DIR"
docker compose up -d

log "Waiting for database to be healthy..."
until docker compose ps | grep -q "healthy"; do
  printf "."
  sleep 2
done
echo ""
ok "Database ready"

# ── Step 3: Start API server ─────────────────────────────────
log "Starting API server (dart_frog)..."
cd "$ROOT_DIR/packages/yob_api"
fvm dart_frog dev &
API_PID=$!

log "Waiting for API to be ready on http://localhost:8080..."
for i in $(seq 1 20); do
  if curl -s http://localhost:8080/ >/dev/null 2>&1; then
    break
  fi
  sleep 2
done

if curl -s http://localhost:8080/ >/dev/null 2>&1; then
  ok "API running at http://localhost:8080"
else
  warn "API may still be starting up — check output above"
fi

# ── Step 4: Launch Flutter app ───────────────────────────────
if [ "$LAUNCH_FLUTTER" = true ]; then
  log "Launching Flutter app (target: $TARGET)..."
  cd "$ROOT_DIR/apps/yob_app"
  fvm flutter run -d "$TARGET" &
  FLUTTER_PID=$!
  ok "Flutter launched on $TARGET"
fi

# ── Done ─────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}═══════════════════════════════════════${NC}"
echo -e "${GREEN}  YOB K Business is running locally!   ${NC}"
echo -e "${GREEN}═══════════════════════════════════════${NC}"
echo -e "  API:      http://localhost:8080"
echo -e "  Login:    admin@yobkbusiness.com"
echo -e "  Password: admin123"
echo -e ""
echo -e "  Press ${YELLOW}Ctrl+C${NC} to stop all services"
echo ""

# Keep script alive until Ctrl+C
wait
