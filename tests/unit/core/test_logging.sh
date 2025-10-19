#!/bin/bash
# tests/unit/core/test_logging.sh

set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# Charger uniquement le minimum nécessaire
source "${PROJECT_DIR}/lib/config.sh"
source "${PROJECT_DIR}/lib/core/logging.sh"

# Compteurs
TESTS_RUN=0
TESTS_PASSED=0

# Helper
assert_output_contains() {
  local output="$1"
  local expected="$2"
  local test_name="$3"
  
  ((TESTS_RUN++))
  
  if [[ "$output" == *"$expected"* ]]; then
    echo "✅ $test_name"
    ((TESTS_PASSED++))
  else
    echo "❌ $test_name"
    echo "   Attendu: $expected"
    echo "   Reçu: $output"
    return 1
  fi
}

assert_output_empty() {
  local output="$1"
  local test_name="$2"
  
  ((TESTS_RUN++))
  
  if [[ -z "$output" ]]; then
    echo "✅ $test_name"
    ((TESTS_PASSED++))
  else
    echo "❌ $test_name"
    echo "   Attendu: (vide)"
    echo "   Reçu: $output"
    return 1
  fi
}

echo "🧪 Tests unitaires : logging.sh"
echo "================================"
echo ""

# Test 1: log_debug avec DEBUG_MODE=true
echo "Test 1: log_debug avec DEBUG_MODE=true"
DEBUG_MODE=true
SILENT_MODE=false
output=$(log_debug "test debug" 2>&1)
assert_output_contains "$output" "DEBUG" "log_debug affiche [DEBUG]"
assert_output_contains "$output" "test debug" "log_debug affiche le message"
echo ""

# Test 2: log_debug avec DEBUG_MODE=false
echo "Test 2: log_debug avec DEBUG_MODE=false"
DEBUG_MODE=false
output=$(log_debug "should not appear" 2>&1)
assert_output_empty "$output" "log_debug n'affiche rien si DEBUG_MODE=false"
echo ""

# Test 3: log_info avec SILENT_MODE=false
echo "Test 3: log_info avec SILENT_MODE=false"
SILENT_MODE=false
output=$(log_info "test info" 2>&1)
assert_output_contains "$output" "test info" "log_info affiche le message"
echo ""

# Test 4: log_info avec SILENT_MODE=true
echo "Test 4: log_info avec SILENT_MODE=true"
SILENT_MODE=true
output=$(log_info "should not appear" 2>&1)
assert_output_empty "$output" "log_info n'affiche rien si SILENT_MODE=true"
echo ""

# Test 5: log_error (toujours visible)
echo "Test 5: log_error (toujours visible)"
SILENT_MODE=true
output=$(log_error "test error" 2>&1)
assert_output_contains "$output" "❌" "log_error affiche l'emoji"
assert_output_contains "$output" "test error" "log_error affiche le message"
echo ""

# Test 6: log_warn avec SILENT_MODE=false
echo "Test 6: log_warn avec SILENT_MODE=false"
SILENT_MODE=false
output=$(log_warn "test warning" 2>&1)
assert_output_contains "$output" "⚠️" "log_warn affiche l'emoji"
assert_output_contains "$output" "test warning" "log_warn affiche le message"
echo ""

# Test 7: log_success avec SILENT_MODE=false
echo "Test 7: log_success avec SILENT_MODE=false"
SILENT_MODE=false
output=$(log_success "test success" 2>&1)
assert_output_contains "$output" "✅" "log_success affiche l'emoji"
assert_output_contains "$output" "test success" "log_success affiche le message"
echo ""

# Test 8: print_message
echo "Test 8: print_message"
output=$(print_message "test message" 2>&1)
assert_output_contains "$output" "test message" "print_message affiche le message"
echo ""

# Résumé
echo "================================"
echo "Tests: $TESTS_RUN"
echo "Réussis: $TESTS_PASSED"

if [[ $TESTS_RUN -eq $TESTS_PASSED ]]; then
  echo "✅ Tous les tests passent"
  exit 0
else
  echo "❌ Certains tests ont échoué"
  exit 1
fi