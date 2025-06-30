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

get_commit_count_between_branches() {
  local from_branch="$1"
  local to_branch="$2"
  git rev-list --count "$from_branch..$to_branch"
}

squash_commits_to_one() {
  local method="${1:-rebase}" # méthode par défaut : rebase
  local base_branch="${2:-main}"

  local merge_base
  merge_base=$(git merge-base "$base_branch" HEAD)

  if [[ -z "$merge_base" ]]; then
    echo "❌ Impossible de déterminer le point de base entre HEAD et $base_branch"
    return 1
  fi

  case "$method" in
    rebase)
      echo "🔁 Rebase interactif (auto-squash) depuis $base_branch"
      GIT_SEQUENCE_EDITOR="sed -i '2,\$ s/^pick /squash /'" git rebase -i "$merge_base"
      ;;
    reset)
      echo "⚠️ Soft reset + nouveau commit depuis $base_branch"
      git reset --soft "$merge_base"
      git commit -m "feat: squash commit"
      ;;
    *)
      echo "❌ Méthode inconnue : $method (utiliser 'rebase' ou 'reset')"
      return 1
      ;;
  esac
}
