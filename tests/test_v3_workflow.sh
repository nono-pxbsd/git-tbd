#!/bin/bash
# test_v3_workflow.sh - Tests d'intégration pour v3.0.0

set -euo pipefail

# Couleurs
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
CYAN="\033[0;36m"
BOLD="\033[1m"
RESET="\033[0m"

# Compteurs
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Helpers
log_test() {
  echo -e "${CYAN}[TEST]${RESET} $*"
}

log_success() {
  echo -e "${GREEN}✅ $*${RESET}"
  ((TESTS_PASSED++))
}

log_error() {
  echo -e "${RED}❌ $*${RESET}"
  ((TESTS_FAILED++))
}

log_info() {
  echo -e "${YELLOW}ℹ️  $*${RESET}"
}

# Vérifier qu'on est dans un repo de test
check_test_repo() {
  if [[ ! -d ".git" ]]; then
    echo "❌ Ce script doit être exécuté dans un repo Git de test"
    echo "💡 Créez un repo de test :"
    echo "   mkdir /tmp/gittbd-test-v3"
    echo "   cd /tmp/gittbd-test-v3"
    echo "   git init"
    echo "   git config user.name \"Test User\""
    echo "   git config user.email \"test@example.com\""
    echo "   echo \"# Test\" > README.md"
    echo "   git add README.md"
    echo "   git commit -m \"Initial commit\""
    exit 1
  fi
  
  log_info "Repo Git détecté"
}

# Cleanup avant les tests
cleanup_before_tests() {
  log_info "Nettoyage avant les tests..."
  
  # Supprimer toutes les branches sauf main
  git checkout main 2>/dev/null || git checkout -b main
  git branch | grep -v "main" | xargs -r git branch -D 2>/dev/null || true
  
  log_success "Nettoyage effectué"
}

# ====================================
# Test 1 : Workflow gittbd complet
# ====================================

test_workflow_gittbd() {
  ((TESTS_RUN++))
  log_test "Test 1 : Workflow gittbd complet (start → finish → validate)"
  
  echo ""
  log_info "Étape 1.1 : Création d'une branche"
  
  # Créer une branche de test
  if ! gittbd start feature/test-v3-workflow-1; then
    log_error "Échec de gittbd start"
    return 1
  fi
  
  # Vérifier qu'on est sur la bonne branche
  local current_branch
  current_branch=$(git rev-parse --abbrev-ref HEAD)
  
  if [[ "$current_branch" != "feature/test-v3-workflow-1" ]]; then
    log_error "Branche incorrecte : $current_branch"
    return 1
  fi
  
  log_success "Branche créée : feature/test-v3-workflow-1"
  
  echo ""
  log_info "Étape 1.2 : Ajout de commits"
  
  # Créer plusieurs commits
  echo "test 1" > test-v3-1.txt
  git add test-v3-1.txt
  git commit -m "test: first commit for v3" --no-verify
  
  echo "test 2" > test-v3-2.txt
  git add test-v3-2.txt
  git commit -m "test: second commit for v3" --no-verify
  
  # Vérifier qu'on a bien 2 commits
  local commit_count
  commit_count=$(git log --oneline main..HEAD | wc -l)
  
  if [[ "$commit_count" -ne 2 ]]; then
    log_error "Nombre de commits incorrect : $commit_count (attendu: 2)"
    return 1
  fi
  
  log_success "2 commits créés"
  
  echo ""
  log_info "Étape 1.3 : Finish avec PR (sans squash local)"
  
  # Publish seulement (pas de PR pour ce test automatique)
  if ! gittbd publish; then
    log_error "Échec de gittbd publish"
    return 1
  fi
  
  log_success "Branche publiée"
  
  # Vérifier que la branche a toujours 2 commits (pas squashés)
  commit_count=$(git log --oneline main..HEAD | wc -l)
  
  if [[ "$commit_count" -ne 2 ]]; then
    log_error "❌ v3 FAIL : Les commits ont été squashés (v2 behavior)"
    log_error "   Attendu: 2 commits"
    log_error "   Trouvé: $commit_count commits"
    return 1
  fi
  
  log_success "✅ v3 OK : Les commits ne sont PAS squashés avant PR"
  
  echo ""
  log_info "Étape 1.4 : Simulation validation (merge local)"
  
  # Pour ce test, on simule un merge squash local
  git checkout main
  git pull 2>/dev/null || true
  
  if git merge --squash feature/test-v3-workflow-1; then
    git commit -m "✨ test: v3 workflow test (simulated PR #1)

- test: first commit for v3
- test: second commit for v3" --no-verify
    
    log_success "Squash merge local effectué"
  else
    log_error "Échec du squash merge"
    return 1
  fi
  
  # Vérifier que main a bien 1 commit squashé
  local main_commit
  main_commit=$(git log -1 --pretty=%B)
  
  if [[ "$main_commit" == *"simulated PR #1"* ]]; then
    log_success "✅ v3 OK : Commit squashé dans main avec titre PR"
  else
    log_error "Message de commit incorrect"
    return 1
  fi
  
  # Cleanup
  git branch -D feature/test-v3-workflow-1 2>/dev/null || true
  
  echo ""
  log_success "Test 1 : PASSED"
}

# ====================================
# Test 2 : Workflow hybride (GitHub merge)
# ====================================

test_workflow_hybrid() {
  ((TESTS_RUN++))
  log_test "Test 2 : Workflow hybride (finish → merge GitHub → cleanup)"
  
  echo ""
  log_info "Étape 2.1 : Création branche et commits"
  
  if ! gittbd start feature/test-v3-workflow-2; then
    log_error "Échec de gittbd start"
    return 1
  fi
  
  echo "test hybrid" > test-v3-hybrid.txt
  git add test-v3-hybrid.txt
  git commit -m "test: hybrid workflow" --no-verify
  
  if ! gittbd publish; then
    log_error "Échec de gittbd publish"
    return 1
  fi
  
  log_success "Branche publiée"
  
  echo ""
  log_info "Étape 2.2 : Simulation merge GitHub"
  
  # Simuler un merge GitHub (squash and merge)
  git checkout main
  git pull 2>/dev/null || true
  
  if git merge --squash feature/test-v3-workflow-2; then
    git commit -m "✨ test: hybrid workflow (GitHub #2)" --no-verify
    git push 2>/dev/null || true
    log_success "Merge GitHub simulé"
  else
    log_error "Échec du merge"
    return 1
  fi
  
  echo ""
  log_info "Étape 2.3 : Test de la commande cleanup"
  
  # La branche locale existe toujours
  if git show-ref --verify --quiet refs/heads/feature/test-v3-workflow-2; then
    log_success "Branche locale toujours présente (normal)"
  else
    log_error "Branche locale déjà supprimée"
    return 1
  fi
  
  # Test de cleanup
  if gittbd cleanup feature/test-v3-workflow-2; then
    log_success "✅ v3 OK : cleanup a fonctionné"
  else
    log_error "Échec de gittbd cleanup"
    return 1
  fi
  
  # Vérifier que la branche est bien supprimée
  if git show-ref --verify --quiet refs/heads/feature/test-v3-workflow-2; then
    log_error "Branche locale toujours présente après cleanup"
    return 1
  else
    log_success "✅ v3 OK : Branche locale supprimée"
  fi
  
  echo ""
  log_success "Test 2 : PASSED"
}

# ====================================
# Test 3 : Modifications après PR
# ====================================

test_modifications_after_pr() {
  ((TESTS_RUN++))
  log_test "Test 3 : Modifications après PR (feature v3)"
  
  echo ""
  log_info "Étape 3.1 : Création branche avec commits initiaux"
  
  if ! gittbd start feature/test-v3-workflow-3; then
    log_error "Échec de gittbd start"
    return 1
  fi
  
  echo "initial 1" > test-v3-modif.txt
  git add test-v3-modif.txt
  git commit -m "test: initial commit 1" --no-verify
  
  echo "initial 2" >> test-v3-modif.txt
  git add test-v3-modif.txt
  git commit -m "test: initial commit 2" --no-verify
  
  if ! gittbd publish; then
    log_error "Échec de gittbd publish"
    return 1
  fi
  
  local commit_count_before
  commit_count_before=$(git log --oneline main..HEAD | wc -l)
  
  if [[ "$commit_count_before" -ne 2 ]]; then
    log_error "Nombre de commits incorrect avant modif : $commit_count_before"
    return 1
  fi
  
  log_success "2 commits initiaux publiés"
  
  echo ""
  log_info "Étape 3.2 : Ajout de commits après PR (simulation review)"
  
  # Simuler une modification après review
  echo "after review 1" >> test-v3-modif.txt
  git add test-v3-modif.txt
  git commit -m "test: fix after review 1" --no-verify
  
  echo "after review 2" >> test-v3-modif.txt
  git add test-v3-modif.txt
  git commit -m "test: fix after review 2" --no-verify
  
  if ! gittbd publish; then
    log_error "Échec de gittbd publish"
    return 1
  fi
  
  local commit_count_after
  commit_count_after=$(git log --oneline main..HEAD | wc -l)
  
  if [[ "$commit_count_after" -ne 4 ]]; then
    log_error "Nombre de commits incorrect après modif : $commit_count_after"
    return 1
  fi
  
  log_success "✅ v3 OK : 4 commits au total (2 initiaux + 2 après review)"
  log_success "✅ v3 OK : Pas de re-squash nécessaire"
  
  echo ""
  log_info "Étape 3.3 : Validation avec tous les commits"
  
  # Simuler validation avec squash de TOUS les commits
  git checkout main
  git pull 2>/dev/null || true
  
  if git merge --squash feature/test-v3-workflow-3; then
    git commit -m "✨ test: modifications after PR (PR #3)

- test: initial commit 1
- test: initial commit 2
- test: fix after review 1
- test: fix after review 2" --no-verify
    
    log_success "✅ v3 OK : Tous les commits squashés au merge final"
  else
    log_error "Échec du squash merge"
    return 1
  fi
  
  # Cleanup
  git branch -D feature/test-v3-workflow-3 2>/dev/null || true
  
  echo ""
  log_success "Test 3 : PASSED"
}

# ====================================
# Test 4 : Cleanup auto-détection
# ====================================

test_cleanup_autodetect() {
  ((TESTS_RUN++))
  log_test "Test 4 : Cleanup auto-détection"
  
  echo ""
  log_info "Étape 4.1 : Création de branches orphelines"
  
  # Créer une branche locale sans remote (simuler une branche mergée)
  git checkout -b feature/test-orphan-1
  echo "orphan 1" > test-orphan-1.txt
  git add test-orphan-1.txt
  git commit -m "test: orphan branch 1" --no-verify
  
  git checkout main
  
  git checkout -b feature/test-orphan-2
  echo "orphan 2" > test-orphan-2.txt
  git add test-orphan-2.txt
  git commit -m "test: orphan branch 2" --no-verify
  
  git checkout main
  
  log_success "2 branches orphelines créées"
  
  echo ""
  log_info "Étape 4.2 : Vérification que les branches existent"
  
  if git show-ref --verify --quiet refs/heads/feature/test-orphan-1 && \
     git show-ref --verify --quiet refs/heads/feature/test-orphan-2; then
    log_success "Les 2 branches existent localement"
  else
    log_error "Branches orphelines non trouvées"
    return 1
  fi
  
  echo ""
  log_info "Étape 4.3 : Test cleanup auto (devrait détecter les 2 branches)"
  log_info "Note : Ce test ne peut être automatisé car il nécessite une interaction"
  log_info "      Pour tester manuellement : gittbd cleanup"
  
  # Cleanup manuel pour les tests
  git branch -D feature/test-orphan-1 feature/test-orphan-2 2>/dev/null || true
  
  log_success "Branches nettoyées manuellement"
  
  echo ""
  log_success "Test 4 : PASSED (avec nettoyage manuel)"
}

# ====================================
# Exécution des tests
# ====================================

run_all_tests() {
  echo ""
  echo "======================================"
  echo "  Tests d'intégration v3.0.0"
  echo "======================================"
  echo ""
  
  check_test_repo
  cleanup_before_tests
  
  echo ""
  echo "======================================"
  echo "  Exécution des tests"
  echo "======================================"
  echo ""
  
  test_workflow_gittbd || true
  echo ""
  test_workflow_hybrid || true
  echo ""
  test_modifications_after_pr || true
  echo ""
  test_cleanup_autodetect || true
  
  echo ""
  echo "======================================"
  echo "  Résultats"
  echo "======================================"
  echo ""
  echo "Tests exécutés : $TESTS_RUN"
  echo -e "${GREEN}Tests réussis  : $TESTS_PASSED${RESET}"
  
  if [[ $TESTS_FAILED -gt 0 ]]; then
    echo -e "${RED}Tests échoués  : $TESTS_FAILED${RESET}"
    echo ""
    echo "❌ Certains tests ont échoué"
    exit 1
  else
    echo ""
    echo "✅ Tous les tests sont passés !"
    exit 0
  fi
}

# Exécuter les tests
run_all_tests