#!/bin/bash
# lib/domain/commits.sh
# shellcheck disable=SC2154

get_commit_count_between_branches_raw() {
  # Compte les commits entre deux branches
  git rev-list --count "$1..$2" 2>/dev/null || echo "0"
}

get_commit_count_between_branches() {
  # Version avec validation des branches
  local from="$1"
  local to="$2"

  if ! branch_exists "$from"; then
    log_error "La branche '$from' n'existe pas."
    return 1
  fi

  if ! branch_exists "$to"; then
    log_error "La branche '$to' n'existe pas."
    return 1
  fi

  get_commit_count_between_branches_raw "$from" "$to"
}

print_commit_count_between_branches() {
  # Affiche le nombre de commits entre deux branches
  local from="$1"
  local to="$2"
  local count

  count=$(get_commit_count_between_branches "$from" "$to") || return 1
  log_info "📊 Nombre de commits entre $from et $to : ${BOLD}$count${RESET}"
}

squash_commits_to_one() {
  # Squash tous les commits depuis DEFAULT_BASE_BRANCH en 1 seul
  log_debug "squash_commits_to_one() called with arguments: $*"

  local method="rebase"
  local base_branch="$DEFAULT_BASE_BRANCH"

  for arg in "$@"; do
    case "$arg" in
      --method=*) method="${arg#*=}" ;;
      --base=*) base_branch="${arg#*=}" ;;
      *)
        log_error "Argument inconnu : $arg"
        return 1
        ;;
    esac
  done

  local merge_base
  merge_base=$(git merge-base "$base_branch" HEAD 2>/dev/null)

  if [[ -z "$merge_base" ]]; then
    log_error "Impossible de déterminer le point de base entre HEAD et $base_branch"
    return 1
  fi

  local commit_count
  commit_count=$(get_commit_count_between_branches_raw "$merge_base" "HEAD")
  
  log_info "📊 $commit_count commit(s) vont être squashés en 1 seul"

  case "$method" in
    rebase)
      log_info "🔄 Squash interactif en cours..."
      if GIT_SEQUENCE_EDITOR="sed -i '2,\$ s/^pick /squash /'" git rebase -i "$merge_base"; then
        log_success "Squash réussi : $(git log -1 --oneline)"
      else
        log_error "Échec du squash. Résolvez les conflits puis relancez."
        return 1
      fi
      ;;
    reset)
      log_warn "Soft reset + nouveau commit depuis $base_branch"
      git reset --soft "$merge_base"
      git commit -m "feat: squash commit"
      ;;
    *)
      log_error "Méthode inconnue : $method (utiliser 'rebase' ou 'reset')"
      return 1
      ;;
  esac
}

generate_commit_title() {
  # Génère un titre de commit pour un merge
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
  local icon="${BRANCH_ICONS[$type]:-🔀}"
  local default_title="$icon $name: merge into $DEFAULT_BASE_BRANCH"

  if [[ "$silent" == true ]]; then
    echo "$default_title"
  else
    local last_commit
    last_commit=$(git log -1 --pretty=%s "$branch" 2>/dev/null)

    print_message ""
    log_info "💬 ${BOLD}Titre du commit${RESET}"
    print_message "  • Dernier commit : $last_commit"
    print_message "  • Par défaut     : $default_title"
    print_message ""
    read -r -p "Titre (vide = dernier commit, 'auto' = défaut) : " input < /dev/tty
    
    [[ -z "$input" ]] && echo "$last_commit" && return
    [[ "$input" == "auto" ]] && echo "$default_title" && return
    echo "$input"
  fi
}

generate_commit_description() {
  # Génère la description (liste des commits)
  log_debug "generate_commit_description() called with arguments: $*"

  local branch="" method=""

  for arg in "$@"; do
    case "$arg" in
      --branch=*) branch="${arg#*=}" ;;
      --method=*) method="${arg#*=}" ;;
    esac
  done

  git log --pretty=format:"- %s" "$branch" "^$DEFAULT_BASE_BRANCH" 2>/dev/null
}

build_commit_content() {
  # Construit le contenu complet du commit (titre + body)
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

  if [[ -n "$title_input" ]]; then
    title="$title_input"
  else
    title=$(generate_commit_title --branch="$branch" --method="$method" --silent="$silent")
    log_debug "Titre généré : $title"
  fi

  if ! command -v "${EDITOR:-$DEFAULT_EDITOR}" >/dev/null 2>&1; then
    log_error "Aucun éditeur défini. Définissez \$EDITOR ou installez vim/nano."
    return 1
  fi

  if [[ "$should_edit_body" == true ]]; then
    local tmpfile
    tmpfile=$(mktemp /tmp/git-commit-msg.XXXXXX)

    {
      echo "$title"
      echo ""
      generate_commit_description --branch="$branch" --method="$method"
    } > "$tmpfile"

    log_info "📝 Ouverture de l'éditeur pour modifier le message de commit"
    "${EDITOR:-$DEFAULT_EDITOR}" "$tmpfile"

    title=$(head -n 1 "$tmpfile")
    body=$(tail -n +3 "$tmpfile")
    
    rm -f "$tmpfile"
  elif [[ -z "$title_input" && "$commit_count" -gt 1 ]]; then
    body=$(generate_commit_description --branch="$branch" --method="$method")
  fi

  echo "$title"
  echo ""
  [[ -n "$body" ]] && echo "$body"
}