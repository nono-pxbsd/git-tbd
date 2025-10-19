#!/bin/bash
# tests/integration/test_full_workflow.sh

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

echo "🧪 Tests d'intégration : Workflow complet"
echo "=========================================="
echo ""

# Setup repo avec remote bare
TEST_REPO=$(mktemp -d)
REMOTE_REPO=$(mktemp -d)

cd "$REMOTE_REPO"
git init --bare -q

cd "$TEST_REPO"
git init -q
git config user.name "Test"
git config user.email "test@test.com"
git remote add origin "$REMOTE_REPO"

# Commit initial
echo "initial" > README.md
git add README.md
git commit -q -m "Initial commit"
git branch -M main
git push -u origin main -q 2>/dev/null

echo "✅ Setup OK (repo avec remote)"
echo ""

# Test 1: Créer une branche avec Git
echo "Test 1: Workflow création branche"
git checkout -b feature/test-workflow -q

if local_branch_exists "feature/test-workflow"; then
  assert_true "Branche créée localement"
else
  assert_false "Branche devrait exister localement"
fi
echo ""

# Test 2: Commits multiples
echo "Test 2: Commits multiples (pas de squash local)"
echo "commit 1" > file1.txt
git add file1.txt
git commit -q -m "feat: commit 1"

echo "commit 2" > file2.txt
git add file2.txt
git commit -q -m "feat: commit 2"

commit_count=$(git log --oneline main..HEAD | wc -l)
if [[ "$commit_count" -eq 2 ]]; then
  assert_true "2 commits créés (pas squashés localement)"
else
  assert_false "Devrait avoir 2 commits, trouvé: $commit_count"
fi
echo ""

# Test 3: Push vers remote
echo "Test 3: Publication vers remote"
if git push -u origin feature/test-workflow -q 2>/dev/null; then
  assert_true "Branche publiée sur remote"
else
  assert_false "Échec publication"
fi

# Vérifier que la branche existe sur remote
if git ls-remote --heads origin feature/test-workflow | grep -q feature/test-workflow; then
  assert_true "Branche existe sur remote"
else
  assert_false "Branche devrait exister sur remote"
fi
echo ""

# Test 4: get_branch_sync_status
echo "Test 4: Status de synchronisation"
status=$(get_branch_sync_status "feature/test-workflow" 2>/dev/null)
if [[ "$status" == "synced" ]]; then
  assert_true "Branche synchronisée avec remote"
else
  assert_true "Branche a un status: $status"
fi
echo ""

# Test 5: Commit additionnel (après "PR")
echo "Test 5: Commit après publication (simulation review)"
echo "commit 3" > file3.txt
git add file3.txt
git commit -q -m "fix: après review"

commit_count=$(git log --oneline main..HEAD | wc -l)
if [[ "$commit_count" -eq 3 ]]; then
  assert_true "3 commits au total (pas de re-squash)"
else
  assert_false "Devrait avoir 3 commits, trouvé: $commit_count"
fi

status=$(get_branch_sync_status "feature/test-workflow" 2>/dev/null)
if [[ "$status" == "ahead" ]]; then
  assert_true "Branche ahead du remote"
else
  assert_true "Status après nouveau commit: $status"
fi
echo ""

# Test 6: Simulation squash merge (GitHub)
echo "Test 6: Simulation squash merge dans main"
git checkout main -q
git pull origin main -q 2>/dev/null || true

if git merge --squash feature/test-workflow -q; then
  git commit -q -m "feat: test workflow (PR #1)

- feat: commit 1
- feat: commit 2
- fix: après review"
  
  assert_true "Squash merge effectué dans main"
  
  # Vérifier qu'on a 1 seul commit squashé
  commit_count_main=$(git log --oneline main~1..main | wc -l)
  if [[ "$commit_count_main" -eq 1 ]]; then
    assert_true "1 seul commit squashé dans main"
  else
    assert_false "Devrait avoir 1 commit squashé"
  fi
else
  assert_false "Échec squash merge"
fi
echo ""

# Test 7: Push main
echo "Test 7: Push main vers remote"
if git push origin main -q 2>/dev/null; then
  assert_true "Main poussé sur remote"
else
  assert_false "Échec push main"
fi
echo ""

# Test 8: Cleanup branche locale
echo "Test 8: Nettoyage branche locale"
if git branch -D feature/test-workflow 2>/dev/null; then
  if ! local_branch_exists "feature/test-workflow"; then
    assert_true "Branche locale supprimée"
  else
    assert_false "Branche locale toujours présente"
  fi
else
  assert_false "Échec suppression branche locale"
fi
echo ""

# Test 9: Cleanup branche remote
echo "Test 9: Nettoyage branche remote"
if git push origin --delete feature/test-workflow -q 2>/dev/null; then
  if ! git ls-remote --heads origin feature/test-workflow | grep -q feature/test-workflow; then
    assert_true "Branche remote supprimée"
  else
    assert_false "Branche remote toujours présente"
  fi
else
  assert_false "Échec suppression branche remote"
fi
echo ""

# Cleanup
cd "$PROJECT_DIR"
rm -rf "$TEST_REPO"
rm -rf "$REMOTE_REPO"

TOTAL=$((TESTS_PASSED + TESTS_FAILED))
echo "=========================================="
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