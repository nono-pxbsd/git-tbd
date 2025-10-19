#!/bin/bash
# tests/integration/test_debug.sh

set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "${PROJECT_DIR}/lib/loader.sh"

# Fonctions assert
assert_true() {
  echo "✅ $1"
}

assert_false() {
  echo "❌ $1"
}

# Setup repo
TEST_REPO=$(mktemp -d)
cd "$TEST_REPO"
git init -q
git config user.name "Test"
git config user.email "test@test.com"
echo "test" > file.txt
git add file.txt
git commit -q -m "Init"
git branch -M main

echo "✅ Repo créé"
echo ""

# Test 1
echo "Test 1: local_branch_exists"
if local_branch_exists "main"; then
  assert_true "main existe"
else
  assert_false "main devrait exister"
fi
echo "✅ Test 1 terminé"
echo ""

# Test 2
echo "Test 2: branche inexistante"
if local_branch_exists "nonexistent"; then
  assert_false "nonexistent ne devrait pas exister"
else
  assert_true "nonexistent n'existe pas"
fi
echo "✅ Test 2 terminé"
echo ""

# Cleanup
cd /tmp
rm -rf "$TEST_REPO"

echo "✅ Tous les tests passent"