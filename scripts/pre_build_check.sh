#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# pre_build_check.sh — Full system check before ANY AAB/APK build
#
# Run:  bash scripts/pre_build_check.sh
# Or (once made executable):  ./scripts/pre_build_check.sh
#
# Exit codes:
#   0 — all checks passed
#   1 — any check failed (build should abort)
# ============================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Colour

PASS=0
FAIL=0

check() {
  local desc="$1"
  shift
  echo ""
  echo -e "${CYAN}═══ CHECK: ${desc}${NC}"
  if "$@" 2>&1; then
    echo -e "${GREEN}  ✓ PASS${NC}"
    PASS=$((PASS + 1))
  else
    echo -e "${RED}  ✗ FAIL${NC}"
    FAIL=$((FAIL + 1))
  fi
}

warn() {
  echo -e "${YELLOW}  ⚠ WARNING: $*${NC}"
}

# ----- 1. Project root sanity ----------------------------------
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_ROOT"
echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  QA Genie — Pre-Build System Check${NC}"
echo -e "${CYAN}  Project: $PROJECT_ROOT${NC}"
echo -e "${CYAN}  Date:    $(date -u)${NC}"
echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}"

# ----- 2. Detect build type ------------------------------------
IS_DEV_BUILD=false
if [ -n "${IS_DEV:-}" ] || echo "${DART_DEFINES:-}" | grep -q "IS_DEV=true" 2>/dev/null; then
  IS_DEV_BUILD=true
fi

if [ "$IS_DEV_BUILD" = true ]; then
  SOURCE_FILE="index.dev.js"
  TARGET="qa-genie-ai-dev"
  echo -e "${YELLOW}  Build type: DEV (IS_DEV=true)${NC}"
else
  SOURCE_FILE="index.prod.js"
  TARGET="qa-genie-ai"
  echo -e "${GREEN}  Build type: PRODUCTION${NC}"
fi

# ----- 3. Verify index.js is in sync with the right source -----
check "index.js matches ${SOURCE_FILE}" \
  bash -c "diff <(grep -v '^//' functions/index.js) <(grep -v '^//' functions/${SOURCE_FILE}) > /dev/null && echo '  Files are in sync (ignoring comment differences)'"

# ----- 4. Flutter clean + pub get ------------------------------
check "flutter clean" flutter clean
check "flutter pub get" flutter pub get

# ----- 5. Dart static analysis ---------------------------------
check "dart analyze (must be 0 issues)" \
  bash -c "dart analyze --fatal-infos 2>&1 | tee /tmp/qa_genie_analyze.log | grep -q 'No issues found'"

# ----- 6. Firebase functions install ---------------------------
if [ -f functions/package.json ]; then
  check "functions npm dependencies" bash -c "cd functions && npm ls 2>/dev/null > /dev/null && echo '  node_modules OK' || (npm install 2>&1 && echo '  node_modules installed')"
fi

# ----- 7. Firebase project alignment (optional) ----------------
CURRENT_PROJECT=$(firebase projects:list 2>/dev/null | grep "(current)" | awk '{print $1}')
if [ -n "$CURRENT_PROJECT" ]; then
  echo -e "${CYAN}  Firebase CLI current project: $CURRENT_PROJECT${NC}"
  if [ "$IS_DEV_BUILD" = true ] && [ "$CURRENT_PROJECT" != "qa-genie-ai-dev" ]; then
    warn "Firebase CLI is set to $CURRENT_PROJECT, but dev build targets qa-genie-ai-dev"
    warn "Run: firebase use qa-genie-ai-dev"
  elif [ "$IS_DEV_BUILD" = false ] && [ "$CURRENT_PROJECT" != "qa-genie-ai" ]; then
    warn "Firebase CLI is set to $CURRENT_PROJECT, but prod build targets qa-genie-ai"
    warn "Run: firebase use qa-genie-ai"
  fi
fi

# ----- 8. Ensure index.js is deployed (deploy check, not build-blocking) --
echo ""
echo -e "${CYAN}═══ REMINDER${NC}"
if [ "$IS_DEV_BUILD" = false ]; then
  echo -e "  Before installing the AAB on a test device, deploy the updated"
  echo -e "  cloud functions to prod:"
  echo -e "    cd functions && npm run deploy:prod"
  echo -e ""
  echo -e "  This ensures the generate() AppCheck fix is live."
fi

# ----- Summary -------------------------------------------------
echo ""
echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}"
echo -e "  ${GREEN}Passed: $PASS${NC}  |  ${RED}Failed: $FAIL${NC}"
echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}"

if [ "$FAIL" -gt 0 ]; then
  echo -e "${RED}  ✗ Some checks failed. Fix issues before building.${NC}"
  exit 1
fi

echo -e "${GREEN}  ✓ All checks passed. You may proceed with the build.${NC}"
