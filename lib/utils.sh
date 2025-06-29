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
  GIT_TBD_PROTECTED_BRANCHES=("main" "master" "develop")

  # Préfixes autorisés : utilisés pour valider les noms de branches
  GIT_TBD_ALLOWED_PREFIXES=("feature/" "bugfix/" "hotfix/" "release/" "chore/")
}
