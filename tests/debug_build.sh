#!/bin/bash

source lib/config.sh
source lib/utils.sh  
source lib/branches.sh

echo "=== Test build_commit_content ==="

# Avec une branche qui existe
output=$(build_commit_content --branch="main" --method="local-squash" --silent=false)
exit_code=$?

echo ""
echo "Exit code: $exit_code"
echo "=== Output ==="
echo "$output"
echo "=== Fin ==="
