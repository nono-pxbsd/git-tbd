#!/bin/bash

# ------------------------
# Configuration Git-TBD
# ------------------------

get_commit_count_between_branches() {
  local from_branch="$1"
  local to_branch="$2"
  git rev-list --count "$from_branch..$to_branch"
}

squash_commits_to_one() {
   # Valeurs par défaut
  local method="rebase"
  local base_branch="main"

  # Parse arguments nommés
  for arg in "$@"; do
    case "$arg" in
      --method=*) method="${arg#*=}" ;;
      --base=*)   base_branch="${arg#*=}" ;;
      *)
        echo "❌ Argument inconnu : $arg"
        return 1
        ;;
    esac
  done

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

generate_merge_label() {
  local branch="$1"
  local method="$2"
  local silent="$3"
  local type="${branch%%/*}"
  local name="${branch##*/}"
  local icon="${ICONS[$type]:-🔀}"

  local default_message="$icon $branch: merge into $DEFAULT_BASE_BRANCH (method: $method)"

  if [[ "$silent" == true ]]; then
    echo "$default_message"
  else
    local last_commit_msg
    last_commit_msg=$(git log -1 --pretty=%B | head -n 1)

    echo -e "${YELLOW}⚠️ Entrez un message pour le squash (laisser vide pour utiliser le dernier ou 'auto' pour le message par défaut):${RESET}"
    echo -e "Dernier commit : $last_commit_msg"
    read -r custom_message

    if [[ -z "$custom_message" ]]; then
      echo "$last_commit_msg"
    elif [[ "$custom_message" == "auto" ]]; then
      echo "$default_message"
    else
      echo "$custom_message"
    fi
  fi
}

pr_exists() {
  local branch="${1:-$(git symbolic-ref --short HEAD)}"
  local pr_number
  pr_number=$(gh pr list --head "$branch" --state open --json number --jq '.[0].number' 2>/dev/null)

  [[ -n "$pr_number" ]]
}

build_commit_message() {
  local branch="$1"
  local method="$2"
  local silent="$3"
  local user_msg="$4"

  local title=""
  local body=""

  if [[ -n "$user_msg" ]]; then
    # Message utilisateur fourni
    title="${user_msg%%$'\n'*}"
    body="${user_msg#"$title"}"
    body="${body#*$'\n'}"
  else
    if [[ "$silent" == true ]]; then
      title="Merge branch '$branch' into $DEFAULT_BASE_BRANCH with method '$method'"
      body=$(git log --pretty=format:"- %s" "$branch" ^"$DEFAULT_BASE_BRANCH")
    else
      local default_title="Merge branch '$branch' into $DEFAULT_BASE_BRANCH"
      local default_body=$(git log --pretty=format:"- %s" "$branch" ^"$DEFAULT_BASE_BRANCH")

      echo -e "✍️  Entrez un titre pour le commit (défaut : '$default_title') :"
      read -r title_input
      title="${title_input:-$default_title}"

      echo -e "📝 Entrez un corps de message (laisser vide pour auto-généré)"
      echo -e "(Entrée vide pour terminer, ou Ctrl+D)"
      body=$(</dev/stdin)
      [[ -z "$body" ]] && body="$default_body"
    fi
  fi

  echo "$title"
  echo "---"
  echo "$body"

  return 0
}

prepare_merge_mode() {
  local branch="${1:-$(git symbolic-ref --short HEAD)}"
  local commit_count=$(get_commit_count_between_branches "origin/$DEFAULT_BASE_BRANCH" "$current_branch")
  local merge_mode="$DEFAULT_MERGE_MODE"

  if [[ "$merge_mode" == "squash" && "$commit_count" -gt 1 ]]; then
    echo -e "${YELLOW}⚠️  Plusieurs commits détectés (${commit_count})."
    echo "   L'utilisation du squash Github entraînera une synchronisation manuelle forcée."
    echo "   Nous vous conseillons l'utilisation du local-squash pour 1 seul commit ou un mode merge classique avec l'ensemble des commits."

    if [[ "$SILENT_MODE" != true ]]; then
      read -r -p "🔁 Souhaitez-vous poursuivre avec un squash Github ? [y/N] " confirm_merge_mode
      if [[ ! "$confirm_merge_mode" =~ ^[Yy]$ ]]; then
        echo "❌ Squash Github annulé."
        return 1
      fi
    fi
  fi

  if [[ "$SILENT_MODE" == true ]]; then
    echo "$merge_mode"
  else
    read -r -p "📦 Quelle méthode souhaitez-vous utiliser ? (laisser vide pour local-squash) : " input_mode
    if [[ "$input_mode" == "merge" ]]; then
      echo "✅ Choix manuel de la méthode merge"
      echo "merge"
    else
      echo "🔁 Utilisation de local-squash par défaut"
      echo "local-squash"
    fi
  fi
}


finalize_branch_merge() {
  local branch=""
  local merge_mode=""
  local via_pr="false"

  for arg in "$@"; do
    case "$arg" in
      --branch=*) branch="${arg#*=}" ;;
      --merge-mode=*) merge_mode="${arg#*=}" ;;
      --via-pr=*) via_pr="${arg#*=}" ;;
      *)
        echo "❌ Argument inconnu : $arg" >&2
        return 1
        ;;
    esac
  done

  # 🧪 Validation minimale
  if [[ -z "$branch" || -z "$merge_mode" ]]; then
    echo "❌ Les paramètres --branch et --merge-mode sont obligatoires" >&2
    return 1
  fi

  if [[ "$merge_mode" == "local-squash" ]]; then
    echo "🧹 Squash local en cours..."
    squash_commits_to_one --method=rebase || return 1
    echo "✅ Squash local effectué."

    echo "🚀 Publication de la branche après squash..."
    publish "$branch" --force-push || return 1
    echo "✅ Publication réussie."
    merge_mode="merge"  # pour compatibilité GitHub CLI
  fi

  if [[ "$via_pr" == true ]]; then
    echo "🔄 Validation via PR avec --$merge_mode..."
    gh pr merge "$branch" --"$merge_mode" --delete-branch || return 1
    echo "🎉 PR validée et branche supprimée."
  else
    echo -e "${GREEN}✅ Fusion de la branche ${branch} dans ${DEFAULT_BASE_BRANCH}...${RESET}"
    git checkout "$DEFAULT_BASE_BRANCH" && git pull || return 1

    git merge --no-ff "$branch" -m "$(build_commit_message "$branch")" || return 1

    if git show-ref --verify --quiet "refs/heads/$branch"; then
      git branch -d "$branch"
    fi
    delete_remote_branch "$branch"
    echo -e "${GREEN}✅ Branche fusionnée et supprimée.${RESET}"
  fi
}