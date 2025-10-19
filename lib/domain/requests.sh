#!/bin/bash
# lib/domain/requests.sh
# shellcheck disable=SC2154

request_exists() {
  # Vérifie si une PR/MR existe pour cette branche
  local branch="${1:-$(git symbolic-ref --short HEAD 2>/dev/null)}"
  log_debug "request_exists() called for branch: $branch"

  local pr_number
  pr_number=$(git_platform_cmd pr-exists "$branch")

  [[ -n "$pr_number" ]]
}

# Alias pour rétrocompatibilité
pr_exists() {
  request_exists "$@"
}

prepare_merge_mode() {
  # Prépare le mode de merge (avec warnings si squash GitHub)
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
  # Finalise un merge (local-squash si demandé, puis merge)
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

  # Squash local si demandé
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

  # Merge final
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