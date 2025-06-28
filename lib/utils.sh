#!/bin/bash

declare -A BRANCH_ICONS=(
  [feature]="✨"
  [fix]="🐛"
  [hotfix]="🚑"
  [chore]="🧹"
  [refactor]="♻️"
  [release]="📦"
  [test]="✅"
  [doc]="📚"
)

# ------------------------
# Configuration Git-TBD
# ------------------------
load_git_tbd_config() {
  # Branches protégées : ne jamais autoriser de modification directe
  PROTECTED_BRANCHES=("main" "master" "develop")

  # Préfixes autorisés : utilisés pour valider les noms de branches
  BRANCH_PREFIXES=("feature/" "bugfix/" "hotfix/" "release/" "chore/")
}
