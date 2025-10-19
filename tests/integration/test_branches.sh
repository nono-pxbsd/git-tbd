#!/bin/bash
# tests/integration/test_branches.sh

set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "${PROJECT_DIR}/lib/loader.sh"

TESTS_PASSED=0
TESTS_FAILED=0

assert_true() {
  echo "✅ $1"
  TESTS_PASSED=$((TESTS_PASSED + 1))
}

assert_false() {
  echo "❌ $1"
  TESTS_FAILED=$((TESTS_FAILED + 1))
}

echo "🧪 Tests d'intégration : branches.sh"
echo "====================================="
echo ""

# Setup
TEST_REPO=$(mktemp -d)
cd "$TEST_REPO"
git init -q
git config user.name "Test"
git config user.email "test@test.com"
echo "test" > README.md
git add README.md
git commit -q -m "Initial commit"
git branch -M main
echo "✅ Setup OK"
echo ""

# Test 1
echo "Test 1: local_branch_exists"
if local_branch_exists "main"; then
  assert_true "main existe"
else
  assert_false "main devrait exister"
fi
echo ""

# Test 2
echo "Test 2: branche inexistante"
if local_branch_exists "nonexistent"; then
  assert_false "nonexistent ne devrait pas exister"
else
  assert_true "nonexistent n'existe pas"
fi
echo ""

# Test 3
echo "Test 3: Créer une branche avec Git"
git checkout -b feature/test -q
if local_branch_exists "feature/test"; then
  assert_true "feature/test créée et détectée"
else
  assert_false "feature/test devrait exister"
fi
echo ""

# Test 4
echo "Test 4: branch_exists"
if branch_exists "main"; then
  assert_true "branch_exists détecte main"
else
  assert_false "branch_exists devrait détecter main"
fi
echo ""

# Cleanup
cd "$PROJECT_DIR"
rm -rf "$TEST_REPO"

TOTAL=$((TESTS_PASSED + TESTS_FAILED))
echo "====================================="
echo "Tests: $TOTAL"
echo "Réussis: $TESTS_PASSED"
echo "Échoués: $TESTS_FAILED"
echo ""

if [[ $TESTS_FAILED -eq 0 ]]; then
  echo "✅ Tous les tests passent"
  exit 0
else
  echo "❌ Des tests ont échoué"
  exit 1
fi