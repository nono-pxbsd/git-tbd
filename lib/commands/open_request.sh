#!/bin/bash
# lib/commands/open_request.sh
# shellcheck disable=SC2154

open_request() {
  # Ouvre une PR/MR (v3 : titre auto-généré depuis commits)
  log_debug "open_request() called with arguments: $*"

  local branch_input="$1"
  local branch_type="" branch_name=""

  branch_input="$(get_branch_input_or_current "$1")"
  if ! parse_branch_input "$branch_input" branch_type branch_name; then
    return 1
  fi

  local branch="${branch_type}/${branch_name}"
  local term=$(get_platform_term)

  log_info "📤 Publication de la branche avant création de la $term..."
  publish "$branch" || return 1

  # v3 : Construction du titre depuis les commits
  local title
  local commit_count
  commit_count=$(get_commit_count_between_branches_raw "$DEFAULT_BASE_BRANCH" "$branch")
  
  log_debug "Nombre de commits : $commit_count"
  
  if [[ "$commit_count" -eq 1 ]]; then
    title=$(git log -1 --pretty=%s "$branch")
    log_debug "1 commit détecté, titre : $title"
  else
    if [[ "$SILENT_MODE" != true ]]; then
      log_info "💬 ${BOLD}Titre de la $term${RESET}"
      local first_commit
      first_commit=$(git log --reverse --pretty=%s "$branch" "^$DEFAULT_BASE_BRANCH" | head -n1)
      print_message "  • Premier commit : $first_commit"
      print_message "  • Nombre de commits : $commit_count"
      print_message ""
      read -r -p "Titre (vide = premier commit) : " title < /dev/tty
      
      [[ -z "$title" ]] && title="$first_commit"
    else
      title=$(git log --reverse --pretty=%s "$branch" "^$DEFAULT_BASE_BRANCH" | head -n1)
    fi
    
    log_debug "Titre choisi : $title"
  fi
  
  # Ajouter l'icône si pas déjà présente
  local icon=$(get_branch_icon "$branch_type")
  if [[ ! "$title" =~ ^$icon ]]; then
    title="$icon $title"
    log_debug "Icône ajoutée : $title"
  fi
  
  # v3 : Construire le body (liste des commits)
  local body
  body=$(git log --pretty=format:"- %s" "$branch" "^$DEFAULT_BASE_BRANCH")
  log_debug "Body généré avec $commit_count commits"
  
  # Ajouter (PR/MR) temporairement
  title="$title ($term)"

  log_info "🔧 Création de la $term via $GIT_PLATFORM..."
  log_debug "Titre temporaire : $title"
  
  git_platform_cmd pr-create --base "$DEFAULT_BASE_BRANCH" --head "$branch" --title "$title" --body "$body" || return 1

  # v3 : Récupérer le numéro et modifier le titre
  local pr_number
  case "$GIT_PLATFORM" in
    github)
      pr_number=$(gh pr view "$branch" --json number -q ".number" 2>/dev/null)
      ;;
    gitlab)
      pr_number=$(glab mr view "$branch" 2>/dev/null | grep -oP '!\K\d+' | head -n1)
      ;;
  esac
  
  if [[ -n "$pr_number" ]]; then
    local final_title="${title% (*)} ($term #$pr_number)"
    
    log_debug "Modification du titre : $final_title"
    
    case "$GIT_PLATFORM" in
      github)
        gh pr edit "$branch" --title "$final_title" 2>/dev/null
        ;;
      gitlab)
        glab mr update "$pr_number" --title "$final_title" 2>/dev/null
        ;;
    esac
    
    log_success "$term #$pr_number créée avec le titre : $final_title"
  fi

  local url
  case "$GIT_PLATFORM" in
    github)
      url=$(gh pr view "$branch" --json url -q ".url" 2>/dev/null)
      ;;
    gitlab)
      url=$(glab mr view "$branch" 2>/dev/null | grep -oP 'https://[^\s]+' | head -n1)
      ;;
  esac

  log_success "$term créée depuis ${CYAN}$branch${RESET} vers ${CYAN}${DEFAULT_BASE_BRANCH}${RESET}"
  [[ -n "$url" ]] && print_message "🔗 Lien : ${BOLD}${url}${RESET}"
}