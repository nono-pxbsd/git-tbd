#!/bin/bash
# tests/unit/core/test_git_wrapper.sh

set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"

source "${PROJECT_DIR}/lib/config.sh"
source "${PROJECT_DIR}/lib/core/logging.sh"
source "${PROJECT_DIR}/lib/core/git_wrapper.sh"

TESTS_RUN=0
TESTS_PASSED=0

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

echo "🧪 Tests unitaires : git_wrapper.sh"
echo "===================================="
echo ""

# Test 1: get_platform_term avec GitHub
echo "Test 1: get_platform_term avec GitHub"
GIT_PLATFORM="github"
result=$(get_platform_term)
assert_equals "$result" "PR" "GitHub retourne 'PR'"
echo ""

# Test 2: get_platform_term avec GitLab
echo "Test 2: get_platform_term avec GitLab"
GIT_PLATFORM="gitlab"
result=$(get_platform_term)
assert_equals "$result" "MR" "GitLab retourne 'MR'"
echo ""

# Test 3: get_platform_term_long avec GitHub
echo "Test 3: get_platform_term_long avec GitHub"
GIT_PLATFORM="github"
result=$(get_platform_term_long)
assert_equals "$result" "Pull Request" "GitHub retourne 'Pull Request'"
echo ""

# Test 4: get_platform_term_long avec GitLab
echo "Test 4: get_platform_term_long avec GitLab"
GIT_PLATFORM="gitlab"
result=$(get_platform_term_long)
assert_equals "$result" "Merge Request" "GitLab retourne 'Merge Request'"
echo ""

# Test 5: Valeur par défaut (si non défini)
echo "Test 5: Valeur par défaut"
GIT_PLATFORM="unknown"
result=$(get_platform_term)
assert_equals "$result" "PR" "Valeur inconnue retourne 'PR' par défaut"
echo ""

# Résumé
echo "===================================="
echo "Tests: $TESTS_RUN"
echo "Réussis: $TESTS_PASSED"

if [[ $TESTS_RUN -eq $TESTS_PASSED ]]; then
  echo "✅ Tous les tests passent"
  exit 0
else
  echo "❌ Certains tests ont échoué"
  exit 1
fi