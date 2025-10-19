#!/bin/bash
# tests/test_loader.sh - Teste que le loader charge tous les modules

set -euo pipefail

# Couleurs
RED="\033[0;31m"
GREEN="\033[0;32m"
CYAN="\033[0;36m"
RESET="\033[0m"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo -e "${CYAN}🧪 Test du loader${RESET}"
echo "=============================="
echo ""

# Test 1 : Le loader existe
echo "Test 1 : Fichier loader.sh existe"
if [[ -f "${PROJECT_DIR}/lib/loader.sh" ]]; then
  echo -e "${GREEN}✅ loader.sh trouvé${RESET}"
else
  echo -e "${RED}❌ loader.sh manquant${RESET}"
  exit 1
fi

# Test 2 : Le loader se charge sans erreur
echo ""
echo "Test 2 : Chargement du loader"
if source "${PROJECT_DIR}/lib/loader.sh" 2>/dev/null; then
  echo -e "${GREEN}✅ Loader chargé avec succès${RESET}"
else
  echo -e "${RED}❌ Échec du chargement du loader${RESET}"
  exit 1
fi

# Test 3 : Vérifier que les fonctions core sont disponibles
echo ""
echo "Test 3 : Fonctions core disponibles"

functions_to_check=(
  "log_debug"
  "log_info"
  "log_warn"
  "log_error"
  "log_success"
  "print_message"
)

all_ok=true
for func in "${functions_to_check[@]}"; do
  if declare -f "$func" >/dev/null; then
    echo -e "  ${GREEN}✅${RESET} $func"
  else
    echo -e "  ${RED}❌${RESET} $func (manquante)"
    all_ok=false
  fi
done

if [[ "$all_ok" == false ]]; then
  echo -e "${RED}❌ Certaines fonctions sont manquantes${RESET}"
  exit 1
fi

# Test 4 : Tester une fonction
echo ""
echo "Test 4 : Test fonctionnel de log_info"

SILENT_MODE=false
output=$(log_info "Test message" 2>&1)

if [[ -n "$output" ]]; then
  echo -e "${GREEN}✅ log_info fonctionne${RESET}"
else
  echo -e "${RED}❌ log_info ne produit pas de sortie${RESET}"
  exit 1
fi

# Test 5 : Mode silencieux
echo ""
echo "Test 5 : Mode silencieux"

SILENT_MODE=true
output=$(log_info "Should not appear" 2>&1)

if [[ -z "$output" ]]; then
  echo -e "${GREEN}✅ Mode silencieux fonctionne${RESET}"
else
  echo -e "${RED}❌ log_info affiche en mode silencieux${RESET}"
  exit 1
fi

# Résumé
echo ""
echo "=============================="
echo -e "${GREEN}✅ Tous les tests du loader passent !${RESET}"
echo "=============================="