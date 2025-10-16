#!/bin/bash

set -euo pipefail

source lib/config.sh
source lib/utils.sh
source lib/branches.sh
source lib/commands.sh

echo "=== Test de finish() ==="
echo ""

# Créer une fausse branche pour tester
git checkout -b feature/test-finish-debug 2>/dev/null || git checkout feature/test-finish-debug

# Créer un commit de test
echo "test" > test-finish-debug.txt
git add test-finish-debug.txt
git commit -m "feat: test finish debug" 2>/dev/null || echo "Commit déjà fait"

echo ""
echo "Appel de finish()..."
echo ""

# Appeler finish directement
finish

echo ""
echo "=== Résultat ==="
git branch
