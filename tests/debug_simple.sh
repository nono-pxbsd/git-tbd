#!/bin/bash

source lib/config.sh
source lib/utils.sh
source lib/branches.sh

echo "=== Test 1 : generate_commit_title seule ==="

title=$(generate_commit_title --branch="feature/test" --method="local-squash" --silent=false)

echo "Titre obtenu : '$title'"
