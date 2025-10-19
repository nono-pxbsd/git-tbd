#!/bin/bash
# commands.sh - Commandes principales

# ====================================
# Sélection interactive du type de branche
# ====================================

select_branch_type() {
  local selected_type=""
  
  # Tentative avec fzf si disponible
  if command -v fzf >/dev/null 2>&1; then
    log_debug "Utilisation de fzf pour la sélection"
    
    # Création d'un tableau avec emoji + type
    local options=()
    for type in "${!BRANCH_ICONS[@]}"; do
      options+=("${BRANCH_ICONS[$type]} $type")
    done
    
    # Tri alphabétique
    IFS=$'\n' options=($(sort <<<"${options[*]}"))
    unset IFS
    
    # Sélection fzf
    selected_type=$(printf "%s\n" "${options[@]}" | \
      fzf --prompt="🎯 Type de branche : " \
          --height=40% \
          --border \
          --reverse \
          --ansi | \
      awk '{print $2}')
    
    if [[ -z "$selected_type" ]]; then
      log_warn "Sélection annulée"
      return 1
    fi
    
  # Fallback : menu numéroté classique
  else
    log_debug "fzf non disponible, utilisation du menu classique"
    
    print_message ""
    log_info "🎯 ${BOLD}Sélection du type de branche${RESET}"
    print_message ""
    
    local -a types_sorted
    IFS=$'\n' types_sorted=($(printf "%s\n" "${!BRANCH_ICONS[@]}" | sort))
    unset IFS
    
    local i=1
    for type in "${types_sorted[@]}"; do
      print_message "  $i. ${BRANCH_ICONS[$type]} $type"
      ((i++))
    done
    
    print_message ""
    read -r -p "Choix (1-${#types_sorted[@]}) : " choice < /dev/tty
    
    if [[ ! "$choice" =~ ^[0-9]+$ ]] || [[ "$choice" -lt 1 ]] || [[ "$choice" -gt "${#types_sorted[@]}" ]]; then
      log_error "Choix invalide"
      return 1
    fi
    
    selected_type="${types_sorted[$((choice-1))]}"
  fi
  
  echo "$selected_type"
}

# ====================================
# Commande start
# ====================================

start() {
  log_debug "start() called with arguments: $*"

  local input="${1:-}"
  local type="" name="" full_branch_name=""

  # === CAS 1 : Aucun argument → sélection interactive complète ===
  if [[ -z "$input" ]]; then
    log_info "🎯 Mode interactif activé"
    
    # Sélection du type avec fzf (ou fallback)
    type=$(select_branch_type) || return 1
    
    # Demande du nom
    print_message ""
    read -r -p "📝 Nom de la branche : " name < /dev/tty
    
    if [[ -z "$name" ]]; then
      log_error "Nom de branche requis"
      return 1
    fi
    
    # Normalisation du nom
    name=$(normalize_branch_name "$name")
    full_branch_name="${type}/${name}"
    
  # === CAS 2 : Argument sans slash → sélection du type uniquement ===
  elif [[ "$input" != */* ]]; then
    log_info "🎯 Type de branche non spécifié, sélection interactive"
    
    # Sélection du type
    type=$(select_branch_type) || return 1
    
    # Normalisation du nom fourni
    name=$(normalize_branch_name "$input")
    full_branch_name="${type}/${name}"
    
  # === CAS 3 : Format complet type/nom ===
  else
    if ! parse_branch_input "$input" type name; then
      return 1
    fi
    
    full_branch_name="${type}/${name}"
  fi

  # === Validations finales ===
  if ! is_valid_branch_type "$type"; then
    log_error "Type de branche invalide : $type"
    log_info "💡 Types disponibles : ${!BRANCH_ICONS[*]}"
    return 1
  fi

  if ! is_valid_branch_name "$name"; then
    log_error "Nom de branche invalide : $name"
    return 1
  fi

  if local_branch_exists "$full_branch_name"; then
    log_warn "La branche ${full_branch_name} existe déjà"
    return 1
  fi

  # === Affichage avec emoji ===
  local icon
  icon=$(get_branch_icon "$type")
  print_message ""
  log_success "Création de ${icon} ${CYAN}${full_branch_name}${RESET}"
  
  create_branch "$type" "$name"
}

# ====================================
# Commande finish (v3 - MODIFIÉ)
# ====================================

finish() {
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

  # === CAS 1 : Request existe déjà ===
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

  # === CAS 2 : Pas de request, config force request OU --pr explicite ===
  if [[ "$REQUIRE_REQUEST_ON_FINISH" == true ]] || [[ "$open_pr" == true ]]; then
    # 🆕 v3 : PAS DE SQUASH LOCAL avant la PR
    # On publie directement (push normal)
    log_info "📤 Publication de la branche..."
    publish "$branch" || return 1
    
    # Création de la request
    open_request "$branch" || return 1
    
    print_message ""
    
    if [[ "$current_branch" == "$branch" ]]; then
      log_info "💡 Validation : ${BOLD}${CYAN}gittbd v${RESET}"
    else
      log_info "💡 Validation : ${BOLD}${CYAN}gittbd v $branch${RESET}"
    fi
    return 0
  fi

  # === CAS 3 : Pas de request, config permet merge local ===
  # ✅ On GARDE le squash local pour les merges directs (sans request)
  log_success "Finalisation locale sans $term"
  local merge_mode
  merge_mode=$(prepare_merge_mode) || return 1
  finalize_branch_merge --branch="$branch" --merge-mode="$merge_mode" --via-pr=false
}

# ====================================
# Commande publish
# ====================================

publish() {
  log_debug "publish() called with arguments: $*"
  
  local force=false
  local force_sync=false
  local force_push=false
  local branch="${1:-$(git symbolic-ref --short HEAD 2>/dev/null)}"

  # Parsing des arguments
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

  # Vérification de l'existence de la branche locale
  if ! local_branch_exists "$branch"; then
    log_error "La branche locale '$branch' n'existe pas"
    return 1
  fi

  # Vérification de la propreté
  log_info "🔍 Vérification de la propreté de la branche..."
  
  if is_branch_clean "$branch"; then
    log_success "La branche '$branch' est propre"
  else
    log_error "La branche '$branch' n'est pas propre"
    return 1
  fi

  # Si la branche distante existe déjà
  if remote_branch_exists "$branch"; then
    local status
    status=$(get_branch_sync_status "$branch")
    
    log_debug "Statut de synchronisation : $status"

    # === MODE --force INTELLIGENT ===
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

    # === GESTION DES ÉTATS ===
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
            log_warn "📝 Cas typique : après ${BOLD}git commit --amend${RESET} ou rebase"
            log_info "   → Utilisez ${CYAN}--force${RESET} ou ${CYAN}--force-push${RESET}"
            return 1
          fi
          ;;
      esac
    fi
  fi

  # === PUBLICATION FINALE ===
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

# ====================================
# Commande open_request
# ====================================

open_request() {
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

  # 🆕 Construction du titre depuis les commits
  local title
  local commit_count
  commit_count=$(get_commit_count_between_branches_raw "$DEFAULT_BASE_BRANCH" "$branch")
  
  log_debug "Nombre de commits : $commit_count"
  
  if [[ "$commit_count" -eq 1 ]]; then
    # 1 seul commit : utiliser son message
    title=$(git log -1 --pretty=%s "$branch")
    log_debug "1 commit détecté, titre : $title"
  else
    # Plusieurs commits
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
      # Mode silencieux : prendre le premier commit
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
  
  # 🆕 Construire le body (liste des commits)
  local body
  body=$(git log --pretty=format:"- %s" "$branch" "^$DEFAULT_BASE_BRANCH")
  log_debug "Body généré avec $commit_count commits"
  
  # Ajouter (PR/MR) temporairement
  title="$title ($term)"

  log_info "🔧 Création de la $term via $GIT_PLATFORM..."
  log_debug "Titre temporaire : $title"
  
  git_platform_cmd pr-create --base "$DEFAULT_BASE_BRANCH" --head "$branch" --title "$title" --body "$body" || return 1

  # 🆕 Récupérer le numéro et modifier le titre
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
    # Enlever (PR) et ajouter (PR #XX)
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

# ====================================
# Commande validate_request
# ====================================

validate_request() {
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

  local term=$(get_platform_term)
  local term_long=$(get_platform_term_long)

  log_info "🔍 Validation de la $term sur branche : ${CYAN}$branch${RESET}"

  # === PHASE 1 : Vérifications préalables ===
  if ! local_branch_exists "$branch"; then
    log_error "La branche '$branch' n'existe pas localement"
    return 1
  fi

  if ! is_branch_clean "$branch"; then
    log_error "La branche '$branch' n'est pas propre"
    log_info "💡 Committez ou stashez vos changements"
    return 1
  fi

  # === PHASE 2 : Synchronisation ===
  log_info "🔄 Synchronisation avec le remote..."
  git_safe fetch origin "$branch" || {
    log_error "Échec de la synchronisation avec origin/$branch"
    return 1
  }

  # === PHASE 3 : Vérification de la Request ===
  log_info "🔍 Vérification de l'existence d'une $term..."
  
  local pr_number
  pr_number=$(git_platform_cmd pr-exists "$branch")
  
  if [[ -z "$pr_number" ]]; then
    log_error "Aucune $term_long trouvée pour la branche '$branch'"
    log_info "💡 Créez une $term avec : ${BOLD}gittbd pr $branch${RESET}"
    return 1
  fi
  
  log_success "$term #$pr_number trouvée"

  # === PHASE 4 : Vérification de la synchro ===
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

  # === PHASE 5 : Récupération des infos Request ===
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
  
  # Construire le body (liste des commits)
  pr_body=$(git log --pretty=format:"- %s" "$branch" "^$DEFAULT_BASE_BRANCH")
  
  log_debug "Titre PR : $pr_title"
  log_debug "Body PR : $pr_body"

  # === PHASE 6 : Affichage du résumé ===
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

  # === PHASE 7 : Confirmation utilisateur ===
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

  # === PHASE 8 : Squash merge local ===
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
  
  # Construire le message final
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

  # === PHASE 9 : Fermeture de la Request ===
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

  # === PHASE 10 : Nettoyage des branches ===
  log_info "🧹 Nettoyage des branches..."
  
  # Supprimer la branche distante
  if remote_branch_exists "$branch"; then
    delete_remote_branch "$branch"
  fi
  
  # Supprimer la branche locale
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

# ====================================
# Gestion de versions (bump) - Inchangé
# ====================================

get_latest_version() {
  local version
  version=$(git describe --tags --abbrev=0 2>/dev/null)
  
  if [[ -z "$version" ]]; then
    echo "0.0.0"
  else
    echo "${version#v}"
  fi
}

parse_version() {
  local version="$1"
  local -n out_major=$2
  local -n out_minor=$3
  local -n out_patch=$4
  
  version="${version#v}"
  
  if [[ ! "$version" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
    log_error "Format de version invalide : $version"
    log_info "💡 Format attendu : MAJOR.MINOR.PATCH (ex: 1.2.3)"
    return 1
  fi
  
  out_major="${BASH_REMATCH[1]}"
  out_minor="${BASH_REMATCH[2]}"
  out_patch="${BASH_REMATCH[3]}"
  
  return 0
}

bump_version() {
  local current_version="$1"
  local bump_type="$2"
  local major minor patch
  
  if ! parse_version "$current_version" major minor patch; then
    return 1
  fi
  
  case "$bump_type" in
    major)
      echo "$((major + 1)).0.0"
      ;;
    minor)
      echo "${major}.$((minor + 1)).0"
      ;;
    patch)
      echo "${major}.${minor}.$((patch + 1))"
      ;;
    *)
      log_error "Type de bump invalide : $bump_type"
      log_info "💡 Types disponibles : major, minor, patch"
      return 1
      ;;
  esac
}

generate_changelog() {
  local from_tag="$1"
  local to_ref="${2:-HEAD}"
  
  if [[ "$from_tag" == "0.0.0" ]]; then
    git log --pretty=format:"- %s (%h)" "$to_ref" 2>/dev/null
  else
    git log --pretty=format:"- %s (%h)" "v${from_tag}..${to_ref}" 2>/dev/null
  fi
}

bump() {
  log_debug "bump() called with arguments: $*"
  
  local bump_type="$1"
  local auto_confirm=false
  local skip_push=false
  
  shift 2>/dev/null || true
  for arg in "$@"; do
    case "$arg" in
      -y|--yes) auto_confirm=true ;;
      --no-push) skip_push=true ;;
      *)
        log_warn "Argument inconnu : $arg"
        ;;
    esac
  done
  
  if [[ ! "$bump_type" =~ ^(major|minor|patch)$ ]]; then
    log_error "Type de bump requis : major, minor ou patch"
    print_message ""
    log_info "Usage : ${BOLD}gittbd bump <type>${RESET}"
    print_message ""
    log_info "Types :"
    log_info "  ${CYAN}major${RESET} : Changement cassant (1.0.0 → 2.0.0)"
    log_info "  ${CYAN}minor${RESET} : Nouvelle fonctionnalité (1.0.0 → 1.1.0)"
    log_info "  ${CYAN}patch${RESET} : Correction de bug (1.0.0 → 1.0.1)"
    print_message ""
    log_info "Options :"
    log_info "  -y, --yes    : Pas de confirmation"
    log_info "  --no-push    : Ne pas pusher le tag"
    return 1
  fi
  
  if ! is_worktree_clean; then
    log_error "Le dépôt contient des modifications non committées"
    log_info "💡 Committez ou stashez vos changements avant de bumper"
    return 1
  fi
  
  local current_branch
  current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
  
  if [[ "$current_branch" != "$DEFAULT_BASE_BRANCH" ]]; then
    log_warn "Vous n'êtes pas sur la branche ${CYAN}${DEFAULT_BASE_BRANCH}${RESET}"
    
    if [[ "$auto_confirm" != true ]]; then
      read -r -p "Continuer quand même ? [y/N] " confirm < /dev/tty
      if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        log_warn "Bump annulé"
        return 1
      fi
    fi
  fi
  
  local current_version new_version
  current_version=$(get_latest_version)
  
  log_info "🔍 Version actuelle : ${BOLD}v${current_version}${RESET}"
  
  new_version=$(bump_version "$current_version" "$bump_type") || return 1
  
  log_info "📦 Nouvelle version : ${BOLD}${GREEN}v${new_version}${RESET}"
  print_message ""
  
  log_info "📝 ${BOLD}Changements depuis v${current_version}${RESET}"
  print_message ""
  
  local changelog
  changelog=$(generate_changelog "$current_version")
  
  if [[ -z "$changelog" ]]; then
    log_warn "Aucun changement détecté depuis v${current_version}"
    print_message ""
  else
    echo "$changelog" >&2
    print_message ""
  fi
  
  if [[ "$auto_confirm" != true ]]; then
    read -r -p "✅ Créer le tag v${new_version} ? [y/N] " confirm < /dev/tty
    
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
      log_warn "Bump annulé"
      return 1
    fi
  fi
  
  log_info "🏷️ Création du tag v${new_version}..."
  
  local tag_message
  tag_message="Release v${new_version}

Changements :
${changelog}"
  
  if git tag -a "v${new_version}" -m "$tag_message"; then
    log_success "Tag v${new_version} créé localement"
  else
    log_error "Échec de la création du tag"
    return 1
  fi
  
  if [[ "$skip_push" != true ]]; then
    log_info "📤 Push du tag vers origin..."
    
    if git_safe push origin "v${new_version}"; then
      log_success "Tag v${new_version} publié sur origin"
      
      local remote_url
      remote_url=$(git config --get remote.origin.url 2>/dev/null)
      
      if [[ "$remote_url" =~ github\.com ]]; then
        local repo_path
        repo_path=$(echo "$remote_url" | sed -E 's/.*github\.com[:/](.+)(\.git)?$/\1/')
        repo_path="${repo_path%.git}"
        
        print_message ""
        log_info "🔗 ${BOLD}Liens utiles${RESET}"
        print_message "   Release : https://github.com/${repo_path}/releases/tag/v${new_version}"
        print_message "   Compare : https://github.com/${repo_path}/compare/v${current_version}...v${new_version}"
      elif [[ "$remote_url" =~ gitlab\.com ]]; then
        local repo_path
        repo_path=$(echo "$remote_url" | sed -E 's/.*gitlab\.com[:/](.+)(\.git)?$/\1/')
        repo_path="${repo_path%.git}"
        
        print_message ""
        log_info "🔗 ${BOLD}Liens utiles${RESET}"
        print_message "   Tags    : https://gitlab.com/${repo_path}/-/tags/v${new_version}"
        print_message "   Compare : https://gitlab.com/${repo_path}/-/compare/v${current_version}...v${new_version}"
      fi
    else
      log_error "Échec du push du tag"
      log_info "💡 Le tag existe localement, vous pouvez le pusher plus tard avec :"
      log_info "   git push origin v${new_version}"
      return 1
    fi
  else
    log_info "ℹ️ Tag créé localement uniquement (--no-push activé)"
    log_info "💡 Pour le pusher plus tard :"
    log_info "   git push origin v${new_version}"
  fi
  
  print_message ""
  log_success "🎉 Version ${BOLD}v${new_version}${RESET} publiée avec succès !"
}