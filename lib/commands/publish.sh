#!/bin/bash
# lib/commands/publish.sh
# shellcheck disable=SC2154

publish() {
  # Publie une branche sur origin
  log_debug "publish() called with arguments: $*"
  
  local force=false
  local force_sync=false
  local force_push=false
  local branch="${1:-$(git symbolic-ref --short HEAD 2>/dev/null)}"

  for arg in "$@"; do
    case "$arg" in
      --force|-f)
        force=true
        log_debug "Flag --force détecté (mode intelligent)"
        ;;
      --force-sync)
        force_sync=true
        log_debug "Flag --force-sync détecté"
        ;;
      --force-push)
        force_push=true
        log_debug "Flag --force-push détecté"
        ;;
    esac
  done

  if ! local_branch_exists "$branch"; then
    log_error "La branche locale '$branch' n'existe pas"
    return 1
  fi

  log_info "🔍 Vérification de la propreté de la branche..."
  
  if is_branch_clean "$branch"; then
    log_success "La branche '$branch' est propre"
  else
    log_error "La branche '$branch' n'est pas propre"
    return 1
  fi

  if remote_branch_exists "$branch"; then
    local status
    status=$(get_branch_sync_status "$branch")
    
    log_debug "Statut de synchronisation : $status"

    if [[ "$force" == true ]]; then
      log_info "⚡ Mode --force activé : détection automatique de l'action nécessaire"
      
      case "$status" in
        ahead)
          log_info "📊 Branche en avance → push standard"
          ;;
        behind)
          log_info "📊 Branche en retard → activation de --force-sync"
          force_sync=true
          ;;
        diverged)
          local strategy="$DEFAULT_DIVERGED_STRATEGY"
          
          if [[ "$SILENT_MODE" == true && "$strategy" == "ask" ]]; then
            strategy="$SILENT_DIVERGED_FALLBACK"
            log_debug "Mode silencieux : utilisation du fallback $strategy"
          fi
          
          case "$strategy" in
            force-push)
              log_warn "⚠️ Branche divergée → activation de --force-push"
              log_info "💡 Stratégie : force push (local écrase origin)"
              force_push=true
              ;;
            force-sync)
              log_warn "⚠️ Branche divergée → activation de --force-sync"
              log_info "💡 Stratégie : sync (rebase) puis push"
              force_sync=true
              ;;
            ask)
              log_warn "⚠️ Branche divergée détectée"
              print_message ""
              log_info "${BOLD}Quelle stratégie utiliser ?${RESET}"
              print_message ""
              print_message "  ${BOLD}1.${RESET} Force push (local écrase origin)"
              print_message "     → Recommandé après amend/rebase/squash local"
              print_message ""
              print_message "  ${BOLD}2.${RESET} Sync puis push (rebase origin dans local)"
              print_message "     → Recommandé si quelqu'un a pushé pendant que vous travailliez"
              print_message ""
              read -r -p "Choix [1/2] : " choice < /dev/tty
              
              case "$choice" in
                1)
                  log_info "✅ Force push sélectionné"
                  force_push=true
                  ;;
                2)
                  log_info "✅ Sync puis push sélectionné"
                  force_sync=true
                  ;;
                *)
                  log_error "Choix invalide"
                  return 1
                  ;;
              esac
              ;;
          esac
          ;;
        synced)
          log_success "✅ Branche déjà synchronisée"
          ;;
      esac
    fi

    if [[ "$status" != "synced" ]]; then
      case "$status" in
        behind)
          if [[ "$force_sync" == true ]]; then
            log_info "🔄 Synchronisation forcée en cours..."
            sync_branch_to_remote --force "$branch" || return 1
          else
            log_error "La branche '$branch' est en retard sur origin"
            print_message ""
            log_info "💡 ${BOLD}Options :${RESET}"
            log_info "   • ${CYAN}gittbd publish --force-sync${RESET} : Force la synchronisation (rebase)"
            log_info "   • ${CYAN}gittbd publish --force${RESET}      : Détection automatique"
            return 1
          fi
          ;;
        ahead)
          log_info "📤 La branche '$branch' est en avance sur origin"
          if [[ "$force_push" == false ]]; then
            log_info "💡 Push standard sera tenté. Si échec (après amend/rebase) :"
            log_info "   • ${CYAN}gittbd publish --force-push${RESET}"
            log_info "   • ${CYAN}gittbd publish --force${RESET}"
          fi
          ;;
        diverged)
          if [[ "$force_sync" == true ]]; then
            log_warn "⚠️ Divergence détectée : tentative de synchronisation..."
            sync_branch_to_remote --force "$branch" || return 1
          else
            log_error "La branche '$branch' a divergé d'origin/$branch"
            print_message ""
            log_info "💡 ${BOLD}Options :${RESET}"
            log_info "   • ${CYAN}gittbd publish --force${RESET}           : Résolution automatique"
            log_info "   • ${CYAN}gittbd publish --force-sync${RESET}      : Force le rebase"
            log_info "   • ${CYAN}gittbd publish --force-push${RESET}      : Force le push (destructif)"
            print_message ""
            log_warn "🔍 Cas typique : après ${BOLD}git commit --amend${RESET} ou rebase"
            log_info "   → Utilisez ${CYAN}--force${RESET} ou ${CYAN}--force-push${RESET}"
            return 1
          fi
          ;;
      esac
    fi
  fi

  log_info "🚀 Publication de la branche '${CYAN}$branch${RESET}' vers origin..."
  
  if [[ "$force_push" == true ]]; then
    log_info "🔧 Force push sécurisé (après modification d'historique local)"
    git_safe push -u origin "$branch" --force-with-lease || {
      local exit_code=$?
      log_error "Échec du force push"
      return $exit_code
    }
  else
    git_safe push -u origin "$branch" || {
      local exit_code=$?
      if [[ $exit_code -ne 0 ]]; then
        log_error "Échec du push standard"
        print_message ""
        log_info "💡 ${BOLD}Si vous avez modifié l'historique${RESET} (amend/rebase) :"
        log_info "   • ${CYAN}gittbd publish --force-push${RESET}"
        log_info "   • ${CYAN}gittbd publish --force${RESET} (détection automatique)"
        return $exit_code
      fi
    }
  fi

  log_success "Branche publiée avec succès"
}