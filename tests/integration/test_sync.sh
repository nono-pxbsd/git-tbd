#!/bin/bash
# tests/integration/test_sync.sh

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

echo "🧪 Tests d'intégration : sync.sh"
echo "================================="
echo ""

# Setup
TEST_REPO=$(mktemp -d)
cd "$TEST_REPO"
git init -q
git config user.name "Test"
git config user.email "test@test.com"
echo "initial" > file.txt
git add file.txt
git commit -q -m "Initial commit"
git branch -M main
echo "✅ Setup OK"
echo ""

# Test 1
echo "Test 1: is_worktree_clean (propre)"
if is_worktree_clean; then
  assert_true "Worktree propre détecté"
else
  assert_false "Worktree devrait être propre"
fi
echo ""

# Test 2
echo "Test 2: is_worktree_clean (modifié)"
echo "modified" >> file.txt
if is_worktree_clean; then
  assert_false "Worktree devrait être sale"
else
  assert_true "Modification détectée"
fi
git checkout -- file.txt 2>/dev/null
echo ""

# Test 3
echo "Test 3: is_worktree_clean (staged)"
echo "staged" >> file.txt
git add file.txt
if is_worktree_clean; then
  assert_false "Worktree devrait être sale"
else
  assert_true "Staging détecté"
fi
git reset HEAD file.txt 2>/dev/null
git checkout -- file.txt 2>/dev/null
echo ""

# Test 4
echo "Test 4: is_worktree_clean (untracked)"
echo "untracked" > untracked.txt
if is_worktree_clean; then
  assert_false "Worktree devrait être sale"
else
  assert_true "Fichier untracked détecté"
fi
rm -f untracked.txt
echo ""

# Cleanup
cd "$PROJECT_DIR"
rm -rf "$TEST_REPO"

TOTAL=$((TESTS_PASSED + TESTS_FAILED))
echo "================================="
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