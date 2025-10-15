#!/bin/bash
# tests/test_prompts.sh - Tests de non-régression

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

source "${PROJECT_DIR}/lib/config.sh"
source "${PROJECT_DIR}/lib/utils.sh"
source "${PROJECT_DIR}/lib/branches.sh"

echo "🧪 Suite de tests pour gittbd"
echo "=============================="
echo ""

# Test 1 : Système de logs
echo "Test 1 : Système de logs"
echo "-------------------------"

SILENT_MODE=false
DEBUG_MODE=false

log_info "Ceci est un log info (doit s'afficher)"
log_warn "Ceci est un warning (doit s'afficher)"
log_error "Ceci est une erreur (doit s'afficher)"
log_success "Ceci est un succès (doit s'afficher)"

echo ""
echo "En mode SILENT :"
SILENT_MODE=true

log_info "Ceci ne doit PAS s'afficher"
log_warn "Ceci ne doit PAS s'afficher"
log_error "Ceci doit s'afficher (erreurs toujours visibles)"

SILENT_MODE=false
echo ""
echo "En mode DEBUG :"
DEBUG_MODE=true

log_debug "Ceci est un debug (doit s'afficher)"

DEBUG_MODE=false
echo ""
echo "✅ Test 1 OK"
echo ""

# Test 2 : Validation de branches
echo "Test 2 : Validation de branches"
echo "--------------------------------"

if parse_branch_input "feature/test" type name; then
  if [[ "$type" == "feature" && "$name" == "test" ]]; then
    echo "✅ Parse OK : type=$type, name=$name"
  else
    echo "❌ Parse incorrect"
    exit 1
  fi
else
  echo "❌ Parse failed"
  exit 1
fi

if parse_branch_input "invalid" type name 2>/dev/null; then
  echo "❌ Parse devrait échouer"
  exit 1
else
  echo "✅ Parse échoue correctement pour 'invalid'"
fi

echo ""
echo "✅ Test 2 OK"
echo ""

# Test 3 : Vérification des icônes
echo "Test 3 : Icônes de branches"
echo "---------------------------"

for branch_type in feature fix hotfix chore doc test refactor release; do
  icon=$(get_branch_icon "$branch_type")
  if [[ -n "$icon" ]]; then
    echo "✅ $branch_type → $icon"
  else
    echo "❌ Pas d'icône pour $branch_type"
    exit 1
  fi
done

echo ""
echo "✅ Test 3 OK"
echo ""

# Test 4 : Validation de noms de branches
echo "Test 4 : Validation de noms"
echo "---------------------------"

valid_names=("login-form" "fix-bug-123" "new-feature")
invalid_names=("a" "ab" "  " "--test" "test--" "test//path")

for name in "${valid_names[@]}"; do
  if is_valid_branch_name "$name"; then
    echo "✅ '$name' est valide"
  else
    echo "❌ '$name' devrait être valide"
    exit 1
  fi
done

for name in "${invalid_names[@]}"; do
  if is_valid_branch_name "$name"; then
    echo "❌ '$name' devrait être invalide"
    exit 1
  else
    echo "✅ '$name' est bien rejeté"
  fi
done

echo ""
echo "✅ Test 4 OK"
echo ""

# Test 5 : Normalisation de noms
echo "Test 5 : Normalisation de noms"
echo "-------------------------------"

normalized=$(normalize_branch_name "Feature Login Form")
expected="feature-login-form"

if [[ "$normalized" == "$expected" ]]; then
  echo "✅ Normalisation OK : '$normalized'"
else
  echo "❌ Attendu '$expected', obtenu '$normalized'"
  exit 1
fi

echo ""
echo "✅ Test 5 OK"
echo ""

# Test 6 : Disponibilité de fzf
echo "Test 6 : Vérification de fzf"
echo "-----------------------------"

if command -v fzf >/dev/null 2>&1; then
  echo "✅ fzf est installé : $(which fzf)"
  fzf_version=$(fzf --version | head -n1)
  echo "   Version : $fzf_version"
else
  echo "⚠️  fzf n'est pas installé (recommandé mais optionnel)"
  echo "   Installation : sudo apt install fzf"
fi

echo ""
echo "✅ Test 6 OK"
echo ""

# Résumé final
echo "=============================="
echo "✅ Tous les tests sont passés !"
echo "=============================="
