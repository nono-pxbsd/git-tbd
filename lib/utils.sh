#!/bin/bash

get_commit_count_between_branches_raw() {
  git rev-list --count "$1..$2"
}

get_commit_count_between_branches() {
  local from="$1"
  local to="$2"

  if ! branch_exists "$from"; then
    echo "❌ La branche '$from' n'existe pas localement ni à distance." >&2
    return 1
  fi

  if ! branch_exists "$to"; then
    echo "❌ La branche '$to' n'existe pas localement ni à distance." >&2
    return 1
  fi

  local count
  count=$(get_commit_count_between_branches_raw "$from" "$to")
  echo "$count"
}

print_commit_count_between_branches() {
  local from="$1"
  local to="$2"
  local count

  count=$(get_commit_count_between_branches "$from" "$to") || return 1
  echo -e "${YELLOW}📊 Nombre de commits entre $from et $to : $count${RESET}"
}

squash_commits_to_one() {
  log_debug "squash_commits_to_one() called with arguments: $*"

   # Valeurs par défaut
  local method="rebase"
  local base_branch="$DEFAULT_BASE_BRANCH"

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

generate_commit_title() {
  log_debug "generate_commit_title() called with arguments: $*"

  local branch="" method="" silent="$SILENT_MODE"
  for arg in "$@"; do
    case $arg in
      --branch=*) branch="${arg#*=}" ;;
      --method=*) method="${arg#*=}" ;;
      --silent=*) silent="${arg#*=}" ;;
    esac
  done

  local type="${branch%%/*}"
  local name="${branch##*/}"
  local icon="${ICONS[$type]:-🔀}"
  local default_title="$icon $branch: merge into $DEFAULT_BASE_BRANCH (method: $method)"

  if [[ "$silent" == true ]]; then
    echo "$default_title"
  else
    local last_commit
    last_commit=$(git log -1 --pretty=%s "$branch")

    
    echo -e "${YELLOW}💬 Titre du commit (laisser vide = dernier, 'auto' = par défaut) :${RESET}"
    echo -e "Dernier commit : $last_commit"
    input="test"
    [[ -z "$input" ]] && echo "$last_commit" || [[ "$input" == "auto" ]] && echo "$default_title" || echo "$input"
  fi
}

generate_commit_description() {
  log_debug "generate_commit_description() called with arguments: $*"

  local branch="" method=""

  for arg in "$@"; do
    case "$arg" in
      --branch=*) branch="${arg#*=}" ;;
      --method=*) method="${arg#*=}" ;;
    esac
  done

  git log --pretty=format:"- %s" "$branch" "^$DEFAULT_BASE_BRANCH"
}

build_commit_content() {
  log_debug "build_commit_content() called with arguments: $*"

  local branch="" method="" silent="$SILENT_MODE" title_input=""
  for arg in "$@"; do
    case $arg in
      --branch=*) branch="${arg#*=}" ;;
      --method=*) method="${arg#*=}" ;;
      --silent=*) silent="${arg#*=}" ;;
      --message=*) title_input="${arg#*=}" ;;
    esac
  done

  local title="" body=""
  local commit_count
  commit_count=$(get_commit_count_between_branches_raw "$DEFAULT_BASE_BRANCH" "$branch")

  local should_edit_body=false
  if [[ "$silent" != true && "$commit_count" -gt 1 ]]; then
    case "$method" in
      squash|rebase|local-squash) should_edit_body=true ;;
    esac
  fi

  # Titre = message forcé OU titre généré
  if [[ -n "$title_input" ]]; then
    title="$title_input"
  else
    title=$(generate_commit_title --branch="$branch" --method="$method" --silent="$silent")
    log_debug "${GREEN}💬 Titre du commit auto : $title${RESET}"
  fi

  if ! command -v "${EDITOR:-$DEFAULT_EDITOR}" >/dev/null; then
    echo -e "${RED}❌ Aucun éditeur défini. Définis \$EDITOR ou installe vim/nano.${RESET}" >&2
    return 1
  fi

  # Body
  if [[ "$should_edit_body" == true ]]; then
    # On ouvre un éditeur pour que l’utilisateur écrive ou corrige le body
    local tmpfile
    tmpfile=$(mktemp /tmp/git-commit-msg.XXXXXX)

    {
      echo "$title"
      echo ""
      echo "$(generate_commit_description --branch="$branch" --method="$method")"
    } > "$tmpfile"

    log_debug "${YELLOW}📝 Ouverture de l’éditeur pour modifier le message de commit.${RESET}"
    "${EDITOR:-$DEFAULT_EDITOR}" "$tmpfile"

    title=$(head -n 1 "$tmpfile")
    body=$(tail -n +3 "$tmpfile")
  elif [[ -z "$title_input" && "$commit_count" -gt 1 ]]; then
    # Si pas d’édition et pas de titre imposé, on peut générer un body automatiquement
    body=$(generate_commit_description --branch="$branch" --method="$method")
  fi

  echo "$title"
  echo ""
  [[ -n "$body" ]] && echo "$body"
}

pr_exists() {
  local branch="${1:-$(git symbolic-ref --short HEAD)}"
  log_debug "pr_exists() called for branch: $branch"

  local pr_number
  pr_number=$(gh pr list --head "$branch" --state open --json number --jq '.[0].number' 2>/dev/null)

  [[ -n "$pr_number" ]]
}

prepare_merge_mode() {
  local branch="${1:-$(git symbolic-ref --short HEAD)}"
  local merge_mode="$DEFAULT_MERGE_MODE"
  log_debug "prepare_merge_mode() called for branch: $branch with merge_mode: $merge_mode"

  local commit_count=$(get_commit_count_between_branches "origin/$DEFAULT_BASE_BRANCH" "$current_branch")
  log_debug "Nombre de commits entre origin/$DEFAULT_BASE_BRANCH et $branch : $commit_count"

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

  log_debug "finalize_branch_merge() called with arguments: $*"

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

    commit_message=$(build_commit_message --branch="$branch")
    git merge -m "$commit_message" || return 1

    if git show-ref --verify --quiet "refs/heads/$branch"; then
      git branch -d "$branch"
    fi
    delete_remote_branch "$branch"
    echo -e "${GREEN}✅ Branche fusionnée et supprimée.${RESET}"
  fi
}

log_debug() {
  if [[ "$DEBUG_MODE" == true ]]; then
    echo -e ">>> $*" >&2
  fi
}
