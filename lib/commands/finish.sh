#!/bin/bash
# lib/commands/finish.sh
# shellcheck disable=SC2154

finish() {
  # Finalise une branche (v3 : pas de squash avant PR)
  log_debug "finish() called with arguments: $*"

  local branch_input="" branch_type="" branch_name="" branch="" current=""
  local method="$DEFAULT_MERGE_MODE"
  local open_pr="$OPEN_REQUEST"
  local silent="$SILENT_MODE"
  local title_input=""

  current=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --pr|-p) open_pr=true ;;
      --silent|-s) silent=true ;;
      --method=*) method="${1#*=}" ;;
      --message=*) title_input="${1#*=}" ;;
      *)
        if [[ -z "$branch_input" ]]; then
          branch_input="$1"
        else
          log_warn "Trop d'arguments. Usage : finish [type/name] [--pr] [--silent] [--method=...] [--message=...]"
          return 1
        fi
        ;;
    esac
    shift
  done

  branch_input="$(get_branch_input_or_current "$branch_input")"
  if ! parse_branch_input "$branch_input" branch_type branch_name; then
    return 1
  fi
  
  branch="${branch_type}/${branch_name}"

  log_info "🏁 Finalisation de la branche ${CYAN}${branch}${RESET}"

  if is_current_branch "$branch" && ! is_branch_clean "$branch"; then
    log_error "Branche courante sale : ${branch}"
    return 1
  fi
  
  if ! is_current_branch "$branch" && ! is_branch_clean "$branch"; then
    log_error "Branche cible sale. Positionnez-vous dessus et nettoyez-la"
    return 1
  fi

  local term=$(get_platform_term)
  local current_branch
  current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)

  # CAS 1 : Request existe déjà
  if request_exists "$branch"; then
    log_info "📤 Synchronisation de la branche avec la $term..."
    publish "$branch" --force-sync || return 1
    
    local pr_url
    case "$GIT_PLATFORM" in
      github)
        pr_url=$(gh pr view "$branch" --json url -q ".url" 2>/dev/null)
        ;;
      gitlab)
        pr_url=$(glab mr view "$branch" 2>/dev/null | grep -oP 'https://[^\s]+' | head -n1)
        ;;
    esac
    
    print_message ""
    log_success "Une $term existe déjà pour cette branche"
    [[ -n "$pr_url" ]] && print_message "🔗 $pr_url"
    print_message ""
    
    if [[ "$current_branch" == "$branch" ]]; then
      log_info "💡 Validation : ${BOLD}${CYAN}gittbd v${RESET}"
    else
      log_info "💡 Validation : ${BOLD}${CYAN}gittbd v $branch${RESET}"
    fi
    return 0
  fi

  # CAS 2 : Pas de request, config force request OU --pr explicite
  if [[ "$REQUIRE_REQUEST_ON_FINISH" == true ]] || [[ "$open_pr" == true ]]; then
    # v3 : PAS DE SQUASH LOCAL avant la PR
    log_info "📤 Publication de la branche..."
    publish "$branch" || return 1
    
    open_request "$branch" || return 1
    
    print_message ""
    
    if [[ "$current_branch" == "$branch" ]]; then
      log_info "💡 Validation : ${BOLD}${CYAN}gittbd v${RESET}"
    else
      log_info "💡 Validation : ${BOLD}${CYAN}gittbd v $branch${RESET}"
    fi
    return 0
  fi

  # CAS 3 : Pas de request, config permet merge local
  log_success "Finalisation locale sans $term"
  local merge_mode
  merge_mode=$(prepare_merge_mode) || return 1
  finalize_branch_merge --branch="$branch" --merge-mode="$merge_mode" --via-pr=false
}