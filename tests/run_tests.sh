#!/bin/bash
# tests/run_tests.sh - Lance tous les tests

set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Couleurs
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
CYAN="\033[0;36m"
BOLD="\033[1m"
RESET="\033[0m"

# Compteurs
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Arguments
RUN_UNIT=true
RUN_INTEGRATION=true
RUN_REGRESSION=true
VERBOSE=false

# Parse arguments
for arg in "$@"; do
  case "$arg" in
    --unit-only)
      RUN_INTEGRATION=false
      RUN_REGRESSION=false
      ;;
    --integration-only)
      RUN_UNIT=false
      RUN_REGRESSION=false
      ;;
    --regression-only)
      RUN_UNIT=false
      RUN_INTEGRATION=false
      ;;
    --verbose|-v)
      VERBOSE=true
      ;;
    --help|-h)
      echo "Usage: $0 [options]"
      echo ""
      echo "Options:"
      echo "  --unit-only           Lance uniquement les tests unitaires"
      echo "  --integration-only    Lance uniquement les tests d'intégration"
      echo "  --regression-only     Lance uniquement les tests de régression"
      echo "  --verbose, -v         Mode verbeux"
      echo "  --help, -h            Affiche cette aide"
      exit 0
      ;;
  esac
done

echo -e "${BOLD}${CYAN}🧪 Suite de tests gittbd v3.1.0${RESET}"
echo "======================================"
echo ""

# Fonction pour lancer un test
run_test() {
  local test_file="$1"
  local test_name=$(basename "$test_file" .sh)
  
  ((TOTAL_TESTS++))
  
  if [[ "$VERBOSE" == true ]]; then
    echo -e "${CYAN}Running: $test_name${RESET}"
    if bash "$test_file"; then
      echo -e "${GREEN}✅ PASS: $test_name${RESET}"
      ((PASSED_TESTS++))
    else
      echo -e "${RED}❌ FAIL: $test_name${RESET}"
      ((FAILED_TESTS++))
    fi
  else
    if bash "$test_file" >/dev/null 2>&1; then
      echo -e "${GREEN}✅${RESET} $test_name"
      ((PASSED_TESTS++))
    else
      echo -e "${RED}❌${RESET} $test_name"
      ((FAILED_TESTS++))
    fi
  fi
}

# Tests unitaires
if [[ "$RUN_UNIT" == true ]]; then
  echo -e "${BOLD}📦 Tests unitaires${RESET}"
  echo "---"
  
  if [[ -d "${SCRIPT_DIR}/unit" ]]; then
    for test in "${SCRIPT_DIR}"/unit/**/*.sh; do
      [[ -f "$test" ]] && run_test "$test"
    done
  else
    echo -e "${YELLOW}⚠️  Pas de tests unitaires trouvés${RESET}"
  fi
  
  echo ""
fi

# Tests d'intégration
if [[ "$RUN_INTEGRATION" == true ]]; then
  echo -e "${BOLD}🔗 Tests d'intégration${RESET}"
  echo "---"
  
  if [[ -d "${SCRIPT_DIR}/integration" ]]; then
    for test in "${SCRIPT_DIR}"/integration/*.sh; do
      [[ -f "$test" ]] && run_test "$test"
    done
  else
    echo -e "${YELLOW}⚠️  Pas de tests d'intégration trouvés${RESET}"
  fi
  
  echo ""
fi

# Tests de régression
if [[ "$RUN_REGRESSION" == true ]]; then
  echo -e "${BOLD}🛡️  Tests de régression${RESET}"
  echo "---"
  
  if [[ -d "${SCRIPT_DIR}/regression" ]]; then
    for test in "${SCRIPT_DIR}"/regression/*.sh; do
      [[ -f "$test" ]] && run_test "$test"
    done
  else
    # Fallback sur les anciens tests à la racine
    for test in "${SCRIPT_DIR}"/test_*.sh; do
      [[ -f "$test" ]] && run_test "$test"
    done
  fi
  
  echo ""
fi

# Résumé
echo "======================================"
echo -e "${BOLD}Résultats${RESET}"
echo "---"
echo -e "Total     : $TOTAL_TESTS tests"
echo -e "${GREEN}Réussis   : $PASSED_TESTS tests${RESET}"

if [[ $FAILED_TESTS -gt 0 ]]; then
  echo -e "${RED}Échoués   : $FAILED_TESTS tests${RESET}"
  echo ""
  echo -e "${RED}❌ Des tests ont échoué${RESET}"
  exit 1
else
  echo ""
  echo -e "${GREEN}✅ Tous les tests sont passés !${RESET}"
  exit 0
fi