#!/bin/bash

set -euo pipefail

source lib/config.sh
source lib/utils.sh
source lib/branches.sh

echo "=== Debug du workflow finish ==="
echo ""

# Simuler ce que fait finish
branch="feature/test-debug"
method="local-squash"
silent=false


echo "Appel de build_commit_content..."
set +e  # Désactive l'arrêt sur erreur
output=$(build_commit_content --branch="$branch" --method="$method" --silent="$silent" 2>&1)
exit_code=$?
set -e

echo ""
echo "=== RÉSULTAT ==="
echo "Exit code: $exit_code"
echo "Output: '$output'"
echo "Longueur output: ${#output}"


