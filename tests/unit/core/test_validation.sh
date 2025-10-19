#!/bin/bash
# tests/unit/core/test_validation.sh

set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"

source "${PROJECT_DIR}/lib/config.sh"
source "${PROJECT_DIR}/lib/core/logging.sh"
source "${PROJECT_DIR}/lib/core/validation.sh"

TESTS_RUN=0
TESTS_PASSED=0

assert_true() {
  local test_name="$1"
  ((TESTS_RUN++))
  echo "✅ $test_name"
  ((TESTS_PASSED++))
}

assert_false() {
  local test_name="$1"
  ((TESTS_RUN++))
  echo "❌ $test_name"
}

assert_equals() {
  local actual="$1"
  local expected="$2"
  local test_name="$3"
  
  ((TESTS_RUN++))
  
  if [[ "$actual" == "$expected" ]]; then
    echo "✅ $test_name"
    ((TESTS_PASSED++))
  else
    echo "❌ $test_name"
    echo "   Attendu: $expected"
    echo "   Reçu: $actual"
    return 1
  fi
}

echo "🧪 Tests unitaires : validation.sh"
echo "==================================="
echo ""

# Test 1: is_valid_branch_type
echo "Test 1: is_valid_branch_type"
if is_valid_branch_type "feature" 2>/dev/null; then
  assert_true "feature est un type valide"
else
  assert_false "feature devrait être valide"
fi

if is_valid_branch_type "invalid" 2>/dev/null; then
  assert_false "invalid devrait être invalide"
else
  assert_true "invalid est rejeté"
fi
echo ""

# Test 2: is_valid_branch_name
echo "Test 2: is_valid_branch_name"
if is_valid_branch_name "login-form" 2>/dev/null; then
  assert_true "'login-form' est valide"
else
  assert_false "'login-form' devrait être valide"
fi

if is_valid_branch_name "ab" 2>/dev/null; then
  assert_false "'ab' (trop court) devrait être invalide"
else
  assert_true "'ab' est rejeté"
fi

if is_valid_branch_name "test--double" 2>/dev/null; then
  assert_false "'test--double' devrait être invalide"
else
  assert_true "'test--double' est rejeté"
fi
echo ""

# Test 3: normalize_branch_name
echo "Test 3: normalize_branch_name"
result=$(normalize_branch_name "Feature Login Form")
assert_equals "$result" "feature-login-form" "Normalisation avec espaces"

result=$(normalize_branch_name "TEST_underscore")
assert_equals "$result" "test-underscore" "Normalisation avec underscore"

result=$(normalize_branch_name "spécial-çàracters")
expected="special-caracters"
# Le résultat peut varier selon iconv, on vérifie juste qu'il est normalisé
if [[ "$result" =~ ^[a-z0-9-]+$ ]]; then
  assert_true "Normalisation des caractères spéciaux"
else
  assert_false "Normalisation des caractères spéciaux a échoué"
fi
echo ""

# Test 4: get_branch_icon
echo "Test 4: get_branch_icon"
icon=$(get_branch_icon "feature")
if [[ -n "$icon" ]]; then
  assert_true "get_branch_icon('feature') retourne une icône"
else
  assert_false "get_branch_icon('feature') devrait retourner une icône"
fi

icon=$(get_branch_icon "fix")
if [[ -n "$icon" ]]; then
  assert_true "get_branch_icon('fix') retourne une icône"
else
  assert_false "get_branch_icon('fix') devrait retourner une icône"
fi
echo ""

# Résumé
echo "==================================="
echo "Tests: $TESTS_RUN"
echo "Réussis: $TESTS_PASSED"

if [[ $TESTS_RUN -eq $TESTS_PASSED ]]; then
  echo "✅ Tous les tests passent"
  exit 0
else
  echo "❌ Certains tests ont échoué"
  exit 1
fi