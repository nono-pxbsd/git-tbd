#!/bin/bash
# utils.sh - Fonctions utilitaires

# ====================================
# Système de logs amélioré
# ====================================

log_debug() {
  [[ "$DEBUG_MODE" != true ]] && return
  echo -e "${BLUE}[DEBUG]${RESET} $*" >&2
}

log_info() {
  [[ "$SILENT_MODE" == true ]] && return
  echo -e "$*" >&2
}

log_warn() {
  [[ "$SILENT_MODE" == true ]] && return
  echo -e "${YELLOW}⚠️  $*${RESET}" >&2
}

log_error() {
  echo -e "${RED}❌ $*${RESET}" >&2
}

log_success() {
  [[ "$SILENT_MODE" == true ]] && return
  echo -e "${GREEN}✅ $*${RESET}" >&2
}

# Affiche un message vers stderr (pour ne pas polluer stdout)
print_message() {
  echo -e "$*" >&2
}

# ====================================
# Terminologie plateforme (PR vs MR)
# ====================================

get_platform_term() {
  case "$GIT_PLATFORM" in
    gitlab) echo "MR" ;;
    *) echo "PR" ;;
  esac
}

get_platform_term_long() {
  case "$GIT_PLATFORM" in
    gitlab) echo "Merge Request" ;;
    *) echo "Pull Request" ;;
  esac
}

# ====================================
# Wrapper sécurisé pour Git
# ====================================

git_safe() {
  local output exit_code
  
  log_debug "Exécution : git $*"
  
  # Capture complète avec attente du processus
  output=$(git "$@" 2>&1)
  exit_code=$?
  
  if [[ $exit_code -ne 0 ]]; then
    log_error "Échec de : git $*"
    [[ -n "$output" && "$DEBUG_MODE" == true ]] && echo "$output" >&2
  else
    log_debug "git $* → OK"
  fi
  
  return $exit_code
}

# ====================================
# Abstraction pour plateformes Git
# ====================================

git_platform_cmd() {
  local action="$1"
  shift
  
  log_debug "git_platform_cmd: $action sur $GIT_PLATFORM"
  
  case "$GIT_PLATFORM" in
    github)
      case "$action" in
        pr-create) gh pr create "$@" ;;
        pr-view) gh pr view "$@" ;;
        pr-merge) gh pr merge "$@" ;;
        pr-list) gh pr list "$@" ;;
        pr-exists)
          local branch="$1"
          gh pr list --head "$branch" --state open --json number --jq '.[0].number' 2>/dev/null
          ;;
      esac
      ;;
    gitlab)
      case "$action" in
        pr-create) glab mr create "$@" ;;
        pr-view) glab mr view "$@" ;;
        pr-merge) glab mr merge "$@" ;;
        pr-list) glab mr list "$@" ;;
        pr-exists)
          local branch="$1"
          glab mr list --source-branch="$branch" --state=opened --per-page=1 2>/dev/null | grep -q "!"
          ;;
      esac
      ;;
    *)
      log_error "Plateforme non supportée : $GIT_PLATFORM"
      log_info "💡 Plateformes disponibles : github, gitlab"
      return 1
      ;;
  esac
}

# ====================================
# Gestion des commits
# ====================================

get_commit_count_between_branches_raw() {
  git rev-list --count "$1..$2" 2>/dev/null || echo "0"
}

get_commit_count_between_branches() {
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
  local from="$1"
  local to="$2"
  local count

  count=$(get_commit_count_between_branches "$from" "$to") || return 1
  log_info "📊 Nombre de commits entre $from et $to : ${BOLD}$count${RESET}"
}

squash_commits_to_one() {
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

pr_exists() {
  local branch="${1:-$(git symbolic-ref --short HEAD 2>/dev/null)}"
  log_debug "pr_exists() called for branch: $branch"

  local pr_number
  pr_number=$(git_platform_cmd pr-exists "$branch")

  [[ -n "$pr_number" ]]
}

prepare_merge_mode() {
  local branch="${1:-$(git symbolic-ref --short HEAD 2>/dev/null)}"
  local merge_mode="$DEFAULT_MERGE_MODE"
  
  log_debug "prepare_merge_mode() for branch: $branch with default: $merge_mode"

  local current_branch
  current_branch=$(git symbolic-ref --short HEAD 2>/dev/null)
  
  local commit_count
  commit_count=$(get_commit_count_between_branches "origin/$DEFAULT_BASE_BRANCH" "$current_branch")
  
  log_debug "Nombre de commits : $commit_count"

  if [[ "$merge_mode" == "squash" && "$commit_count" -gt 1 ]]; then
    log_warn "Plusieurs commits détectés (${commit_count})."
    log_info "⚠️  Le squash GitHub entraînera une désynchronisation locale."
    log_info "💡 Nous recommandons le ${BOLD}local-squash${RESET} ou un ${BOLD}merge${RESET} classique."

    if [[ "$SILENT_MODE" != true ]]; then
      print_message ""
      read -r -p "🔧 Poursuivre avec un squash GitHub ? [y/N] " confirm < /dev/tty
      
      if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        log_warn "Squash GitHub annulé"
        return 1
      fi
    fi
  fi

  if [[ "$SILENT_MODE" == true ]]; then
    echo "$merge_mode"
  else
    print_message ""
    log_info "📦 ${BOLD}Méthode de merge disponibles${RESET}"
    print_message "  1. local-squash (recommandé) : Squash local puis merge"
    print_message "  2. merge                      : Merge classique (conserve l'historique)"
    print_message "  3. squash                     : Squash via GitHub/GitLab"
    print_message ""
    read -r -p "Méthode (vide = local-squash) : " input_mode < /dev/tty
    
    case "$input_mode" in
      merge|2) echo "merge" ;;
      squash|3) echo "squash" ;;
      *) echo "local-squash" ;;
    esac
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
        log_error "Argument inconnu : $arg"
        return 1
        ;;
    esac
  done

  if [[ -z "$branch" || -z "$merge_mode" ]]; then
    log_error "Les paramètres --branch et --merge-mode sont obligatoires"
    return 1
  fi

  log_debug "finalize_branch_merge: branch=$branch, merge_mode=$merge_mode, via_pr=$via_pr"

  # === PHASE 1 : Squash local si demandé ===
  if [[ "$merge_mode" == "local-squash" ]]; then
    log_info "🧹 Squash local en cours..."
    squash_commits_to_one --method=rebase || return 1
    log_success "Squash local effectué"

    log_info "🚀 Publication de la branche après squash..."
    publish "$branch" --force-push || return 1
    log_success "Publication réussie"
    
    merge_mode="merge"
  fi

  log_debug "merge_mode après traitement local-squash: '$merge_mode'"

  # === PHASE 2 : Merge final ===
  if [[ "$via_pr" == true ]]; then
    log_info "🔄 Validation via PR avec méthode : $merge_mode"
    git_platform_cmd pr-merge "$branch" --"$merge_mode" --delete-branch || return 1
    log_success "PR validée et branche distante supprimée"
  else
    log_success "Fusion de la branche ${CYAN}$branch${RESET} dans ${CYAN}${DEFAULT_BASE_BRANCH}${RESET}"
    
    git_safe checkout "$DEFAULT_BASE_BRANCH" && git_safe pull || return 1

    local commit_message
    commit_message=$(build_commit_content --branch="$branch" --method="$merge_mode")
    
    git_safe merge --no-ff -m "$commit_message" "$branch" || return 1

    if git show-ref --verify --quiet "refs/heads/$branch"; then
      git branch -d "$branch"
      log_info "🗑️  Branche locale supprimée"
    fi
    
    delete_remote_branch "$branch"
    log_success "Branche fusionnée et nettoyée"
  fi
}