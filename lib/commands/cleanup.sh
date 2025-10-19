#!/bin/bash
# lib/commands/cleanup.sh
# shellcheck disable=SC2154

cleanup() {
  # Nettoie une branche après merge via GitHub/GitLab (v3)
  log_debug "cleanup() called with arguments: $*"

  local branch_input="$1"
  local branch=""

  if [[ -z "$branch_input" ]]; then
    log_info "🔍 Recherche de branches mergées..."
    
    local branches
    branches=$(git branch --format='%(refname:short)' | grep -v "^${DEFAULT_BASE_BRANCH}$")
    
    if [[ -z "$branches" ]]; then
      log_warn "Aucune branche locale trouvée (hors $DEFAULT_BASE_BRANCH)"
      return 0
    fi
    
    local merged_branches=()
    
    while IFS= read -r b; do
      log_debug "Vérification de $b..."
      
      if ! remote_branch_exists "$b"; then
        log_debug "$b n'existe plus à distance, probablement mergée"
        merged_branches+=("$b")
      fi
    done <<< "$branches"
    
    if [[ ${#merged_branches[@]} -eq 0 ]]; then
      log_info "Aucune branche mergée détectée"
      return 0
    elif [[ ${#merged_branches[@]} -eq 1 ]]; then
      branch="${merged_branches[0]}"
      log_info "🧹 Branche mergée détectée : ${CYAN}$branch${RESET}"
      
      if [[ "$SILENT_MODE" != true ]]; then
        read -r -p "Nettoyer maintenant ? [Y/n] " confirm < /dev/tty
        if [[ "$confirm" =~ ^[Nn]$ ]]; then
          log_warn "Nettoyage annulé"
          return 0
        fi
      fi
    else
      log_info "Plusieurs branches mergées détectées :"
      print_message ""
      
      local i=1
      for b in "${merged_branches[@]}"; do
        print_message "  $i. $b"
        ((i++))
      done
      
      print_message ""
      read -r -p "Numéro de la branche à nettoyer (0 = toutes) : " choice < /dev/tty
      
      if [[ "$choice" == "0" ]]; then
        for b in "${merged_branches[@]}"; do
          cleanup "$b"
        done
        return 0
      elif [[ "$choice" =~ ^[0-9]+$ ]] && [[ "$choice" -ge 1 ]] && [[ "$choice" -le ${#merged_branches[@]} ]]; then
        branch="${merged_branches[$((choice-1))]}"
      else
        log_error "Choix invalide"
        return 1
      fi
    fi
  else
    branch="$branch_input"
  fi

  if [[ "$branch" != */* ]]; then
    log_error "Format de branche invalide : '$branch'"
    log_info "💡 Format attendu : type/nom (ex: feature/login)"
    return 1
  fi

  log_info "🧹 Nettoyage de la branche ${CYAN}$branch${RESET}..."

  local current_branch
  current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
  
  if [[ "$current_branch" == "$branch" ]]; then
    log_info "🔄 Basculement sur $DEFAULT_BASE_BRANCH..."
    git_safe checkout "$DEFAULT_BASE_BRANCH" || {
      log_error "Impossible de basculer sur $DEFAULT_BASE_BRANCH"
      return 1
    }
  fi

  log_info "⬇️ Mise à jour de $DEFAULT_BASE_BRANCH..."
  local current_on_main=false
  if [[ "$current_branch" != "$DEFAULT_BASE_BRANCH" ]]; then
    git_safe checkout "$DEFAULT_BASE_BRANCH" || return 1
    current_on_main=true
  fi
  
  git_safe pull || {
    log_warn "Échec de la mise à jour de $DEFAULT_BASE_BRANCH"
  }

  if git show-ref --verify --quiet "refs/heads/$branch"; then
    log_info "🗑️ Suppression de la branche locale..."
    
    git branch -D "$branch" 2>/dev/null || {
      log_error "Échec de la suppression de la branche locale"
      return 1
    }
    
    log_success "Branche locale ${CYAN}$branch${RESET} supprimée"
  else
    log_debug "Branche locale $branch n'existe pas (déjà supprimée)"
  fi

  if remote_branch_exists "$branch"; then
    log_info "🌐 Suppression de la branche distante..."
    delete_remote_branch "$branch"
  else
    log_debug "Branche distante $branch n'existe pas (déjà supprimée)"
  fi

  log_info "🧼 Nettoyage des références Git..."
  git_safe remote prune origin 2>/dev/null || {
    log_warn "Échec du nettoyage des références"
  }

  if [[ "$current_on_main" == true && "$current_branch" != "$DEFAULT_BASE_BRANCH" ]]; then
    if git show-ref --verify --quiet "refs/heads/$current_branch"; then
      git_safe checkout "$current_branch"
    fi
  fi

  print_message ""
  log_success "✅ Branche ${CYAN}$branch${RESET} nettoyée avec succès"
}