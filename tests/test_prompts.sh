#!/bin/bash
# tests/test_prompts.sh - Tests de non-régression

# 🔧 Pas de set -u pour éviter les problèmes avec nameref
set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Utiliser le loader
source "${PROJECT_DIR}/lib/loader.sh"

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

# 🔧 Wrapper pour éviter le problème avec nameref
test_parse_branch() {
  local input="$1"
  local result_type result_name
  
  # Désactiver temporairement set -u dans cette fonction
  set +u
  
  if parse_branch_input "$input" result_type result_name; then
    echo "$result_type|$result_name"
    return 0
  else
    return 1
  fi
}

# Test avec format valide
if result=$(test_parse_branch "feature/test"); then
  parsed_type="${result%%|*}"
  parsed_name="${result##*|}"
  
  if [[ "$parsed_type" == "feature" && "$parsed_name" == "test" ]]; then
    echo "✅ Parse OK : type=$parsed_type, name=$parsed_name"
  else
    echo "❌ Parse incorrect : type=$parsed_type, name=$parsed_name"
    exit 1
  fi
else
  echo "❌ Parse failed"
  exit 1
fi

# Test avec format invalide
if test_parse_branch "invalid" 2>/dev/null; then
  echo "❌ Parse devrait échouer pour 'invalid'"
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

for name_test in "${valid_names[@]}"; do
  if is_valid_branch_name "$name_test"; then
    echo "✅ '$name_test' est valide"
  else
    echo "❌ '$name_test' devrait être valide"
    exit 1
  fi
done

for name_test in "${invalid_names[@]}"; do
  if is_valid_branch_name "$name_test"; then
    echo "❌ '$name_test' devrait être invalide"
    exit 1
  else
    echo "✅ '$name_test' est bien rejeté"
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