#!/bin/bash
# lib/commands/validate_request.sh
# shellcheck disable=SC2154

validate_request() {
  # Valide une PR/MR (v3 : squash merge LOCAL)
  log_debug "validate_request() called with arguments: $*"

  local branch=""
  local assume_yes=false
  local force_sync=false

  local current_branch
  current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)

  local args=()
  for arg in "$@"; do
    case "$arg" in
      -y|--assume-yes) assume_yes=true ;;
      --force-sync) force_sync=true ;;
      -*) ;;
      *) args+=("$arg") ;;
    esac
  done

  if [[ ${#args[@]} -gt 0 ]]; then
    branch="${args[0]}"
  else
    branch="$current_branch"
  fi

  local term term_long
  term=$(get_platform_term)
  term_long=$(get_platform_term_long)

  log_info "🔍 Validation de la $term sur branche : ${CYAN}$branch${RESET}"

  # PHASE 1 : Vérifications préalables
  if ! local_branch_exists "$branch"; then
    log_error "La branche '$branch' n'existe pas localement"
    return 1
  fi

  if ! is_branch_clean "$branch"; then
    log_error "La branche '$branch' n'est pas propre"
    log_info "💡 Committez ou stashez vos changements"
    return 1
  fi

  # PHASE 2 : Synchronisation
  log_info "🔄 Synchronisation avec le remote..."
  git_safe fetch origin "$branch" || {
    log_error "Échec de la synchronisation avec origin/$branch"
    return 1
  }

  # PHASE 3 : Vérification de la Request
  log_info "🔍 Vérification de l'existence d'une $term..."
  
  local pr_number
  pr_number=$(git_platform_cmd pr-exists "$branch")
  
  if [[ -z "$pr_number" ]]; then
    log_error "Aucune $term_long trouvée pour la branche '$branch'"
    log_info "💡 Créez une $term avec : ${BOLD}gittbd pr $branch${RESET}"
    return 1
  fi
  
  log_success "$term #$pr_number trouvée"

  # PHASE 4 : Vérification de la synchro
  local status
  status=$(get_branch_sync_status "$branch")

  if [[ "$status" != "synced" ]]; then
    log_warn "Branche '$branch' non synchronisée (statut: $status)"
    
    if [[ "$status" == "ahead" ]]; then
      log_info "📤 La branche est en avance (probablement après squash local)"
      log_info "🔧 Force push en cours..."
      git_safe push origin "$branch" --force-with-lease || return 1
      log_success "Branche synchronisée avec force push"
    elif [[ "$force_sync" == true ]]; then
      log_info "🔧 Synchronisation forcée en cours..."
      sync_branch_to_remote --force "$branch" || return 1
    else
      log_info "💡 Synchronisez avec : ${BOLD}gittbd publish $branch${RESET}"
      return 1
    fi
  fi

  # PHASE 5 : Récupération des infos Request
  log_info "📋 Récupération des informations de la $term..."
  
  local pr_title pr_body
  
  case "$GIT_PLATFORM" in
    github)
      pr_title=$(gh pr view "$branch" --json title -q ".title" 2>/dev/null)
      ;;
    gitlab)
      pr_title=$(glab mr view "$branch" 2>/dev/null | grep -oP 'title: \K.*')
      ;;
  esac
  
  if [[ -z "$pr_title" ]]; then
    log_error "Impossible de récupérer le titre de la $term"
    return 1
  fi
  
  pr_body=$(git log --pretty=format:"- %s" "$branch" "^$DEFAULT_BASE_BRANCH")
  
  log_debug "Titre PR : $pr_title"
  log_debug "Body PR : $pr_body"

  # PHASE 6 : Affichage du résumé
  print_message ""
  log_info "📋 ${BOLD}Résumé de la $term${RESET}"
  print_message ""
  print_message "  Titre : ${CYAN}$pr_title${RESET}"
  print_message "  Branche : ${CYAN}$branch${RESET} → ${CYAN}${DEFAULT_BASE_BRANCH}${RESET}"
  print_message ""
  
  git_platform_cmd pr-view "$branch" 2>/dev/null || {
    log_warn "Impossible d'afficher le détail de la $term"
  }
  
  print_message ""

  # PHASE 7 : Confirmation utilisateur
  local confirm="n"
  
  if [[ "$assume_yes" == true ]]; then
    confirm="y"
    log_info "Mode automatique activé (--assume-yes)"
  else
    read -r -p "✅ Souhaitez-vous valider (merger) la $term ? [y/N] " confirm < /dev/tty
  fi

  if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    log_warn "Validation annulée par l'utilisateur"
    return 1
  fi

  # PHASE 8 : Squash merge local
  log_info "🔄 Basculement sur $DEFAULT_BASE_BRANCH..."
  git_safe checkout "$DEFAULT_BASE_BRANCH" || return 1
  
  log_info "⬇️ Mise à jour de $DEFAULT_BASE_BRANCH..."
  git_safe pull || return 1
  
  log_info "🔀 Squash merge de $branch..."
  git_safe merge --squash "$branch" || {
    log_error "Échec du squash merge"
    log_info "💡 Résolvez les conflits puis committez manuellement"
    return 1
  }
  
  local final_message="$pr_title

$pr_body"
  
  log_info "💬 Création du commit de merge..."
  git_safe commit -m "$final_message" || {
    log_error "Échec du commit"
    return 1
  }
  
  log_info "📤 Push vers $DEFAULT_BASE_BRANCH..."
  git_safe push origin "$DEFAULT_BASE_BRANCH" || {
    log_error "Échec du push"
    return 1
  }
  
  log_success "Merge effectué dans $DEFAULT_BASE_BRANCH"

  # PHASE 9 : Fermeture de la Request
  log_info "🔒 Fermeture de la $term #$pr_number..."
  
  case "$GIT_PLATFORM" in
    github)
      gh pr close "$branch" --comment "Merged via gittbd validate" 2>/dev/null || {
        log_warn "Impossible de fermer la PR automatiquement"
      }
      ;;
    gitlab)
      glab mr close "$pr_number" --comment "Merged via gittbd validate" 2>/dev/null || {
        log_warn "Impossible de fermer la MR automatiquement"
      }
      ;;
  esac

  # PHASE 10 : Nettoyage des branches
  log_info "🧹 Nettoyage des branches..."
  
  if remote_branch_exists "$branch"; then
    delete_remote_branch "$branch"
  fi
  
  if git show-ref --verify --quiet "refs/heads/$branch"; then
    git branch -d "$branch" 2>/dev/null || {
      log_warn "Impossible de supprimer la branche locale avec -d, utilisation de -D..."
      git branch -D "$branch"
    }
    log_success "Branche locale $branch supprimée"
  fi
  
  print_message ""
  log_success "🎉 $term #$pr_number validée et mergée avec succès !"
}