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
    
    echo ""
    log_info "🎯 ${BOLD}Sélection du type de branche${RESET}"
    echo ""
    
    local -a types_sorted
    IFS=$'\n' types_sorted=($(printf "%s\n" "${!BRANCH_ICONS[@]}" | sort))
    unset IFS
    
    local i=1
    for type in "${types_sorted[@]}"; do
      echo "  $i. ${BRANCH_ICONS[$type]} $type"
      ((i++))
    done
    
    echo ""
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
    echo ""
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
  log_info ""
  log_success "Création de ${icon} ${CYAN}${full_branch_name}${RESET}"
  
  create_branch "$type" "$name"
}

# ====================================
# Commande finish
# ====================================

finish() {
  log_debug "finish() called with arguments: $*"

  local branch_input="" branch_type="" branch_name="" branch="" current=""
  local method="$DEFAULT_MERGE_METHOD"
  local open_pr="$OPEN_PR"
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

  local output commit_title commit_body
  output=$(build_commit_content --branch="$branch" --method="$method" --silent="$silent" --message="$title_input") || return 1
  commit_title=$(echo "$output" | head -n 1)
  commit_body=$(echo "$output" | tail -n +3)

  local term=$(get_platform_term)

  if [[ "$REQUIRE_PR_ON_FINISH" == true ]] && ! pr_exists "$branch" && [[ "$open_pr" != true ]]; then
    log_error "$term requise pour finaliser cette branche"
    log_info "💡 Créez une $term avec : ${BOLD}gittbd pr $branch${RESET}"
    return 1
  fi

  if pr_exists "$branch"; then
    validate_pr "$branch" ${silent:+--assume-yes} || return 1
  elif [[ "$open_pr" == true ]]; then
    open_pr "$branch" || return 1
    validate_pr "$branch" ${silent:+--assume-yes} || return 1
  else
    log_success "Finalisation locale sans $term"
    local merge_mode
    merge_mode=$(prepare_merge_mode) || return 1
    finalize_branch_merge --branch="$branch" --merge-mode="$merge_mode" --via-pr=false
  fi
}

# ====================================
# Commande publish
# ====================================

publish() {
  log_debug "publish() called with arguments: $*"
  
  local force_sync=false
  local force_push=false
  local branch="${1:-$(git symbolic-ref --short HEAD 2>/dev/null)}"

  for arg in "$@"; do
    case "$arg" in
      --force-sync) force_sync=true ;;
      --force-push) force_push=true ;;
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
    if ! branch_is_sync "$branch"; then
      local status
      status=$(get_branch_sync_status "$branch")

      if [[ "$status" == "behind" && "$force_sync" == true ]]; then
        sync_branch_to_remote --force "$branch" || return 1
      else
        sync_branch_to_remote "$branch" || return 1
      fi
    fi
  fi

  log_info "🚀 Publication de la branche '${CYAN}$branch${RESET}' vers origin..."
  
  if [[ "$force_push" == true ]]; then
    git_safe push -u origin "$branch" --force-with-lease || return 1
  else
    git_safe push -u origin "$branch" || return 1
  fi

  log_success "Branche publiée avec succès"
}

# ====================================
# Commande open_pr
# ====================================

open_pr() {
  log_debug "open_pr() called with arguments: $*"

  local branch_input="$1"
  local branch_type="" branch_name=""

  branch_input="$(get_branch_input_or_current "$1")"
  if ! parse_branch_input "$branch_input" branch_type branch_name; then
    return 1
  fi

  local branch="${branch_type}/${branch_name}"
  local icon="$(get_branch_icon "$branch_type")"
  local title="${icon}${branch_name}"
  local body="${2:-Pull request automatique depuis \`$branch\` vers \`${DEFAULT_BASE_BRANCH}\`}"
  local term=$(get_platform_term)

  log_info "📤 Publication de la branche avant création de la $term..."
  publish "$branch" || return 1

  log_info "🔧 Création de la $term via $GIT_PLATFORM..."
  git_platform_cmd pr-create --base "$DEFAULT_BASE_BRANCH" --head "$branch" --title "$title" --body "$body" || return 1

  local url
  case "$GIT_PLATFORM" in
    github)
      url=$(gh pr view "$branch" --json url -q ".url" 2>/dev/null)
      ;;
    gitlab)
      url=$(glab mr view "$branch" 2>/dev/null | grep -oP 'https://[^\s]+')
      ;;
  esac

  log_success "$term créée depuis ${CYAN}$branch${RESET} vers ${CYAN}${DEFAULT_BASE_BRANCH}${RESET}"
  [[ -n "$url" ]] && echo -e "🔗 Lien : ${BOLD}${url}${RESET}"
}

# ====================================
# Commande validate_pr
# ====================================

validate_pr() {
  log_debug "validate_pr() called with arguments: $*"

  local branch=""
  local merge_mode="squash"
  local assume_yes=false
  local force_sync=false

  local current_branch
  current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)

  local args=()
  for arg in "$@"; do
    case "$arg" in
      --merge-mode=*) merge_mode="${arg#*=}" ;;
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

  # === PHASE 2 : Synchronisation (attente explicite) ===
  log_info "🔄 Synchronisation avec le remote..."
  git_safe fetch origin "$branch" || {
    log_error "Échec de la synchronisation avec origin/$branch"
    return 1
  }

  # === PHASE 3 : Vérification de la PR/MR ===
  log_info "📄 Vérification de l'existence d'une $term..."
  
  local pr_number
  pr_number=$(git_platform_cmd pr-exists "$branch")
  
  if [[ -z "$pr_number" ]]; then
    log_error "Aucune $term_long trouvée pour la branche '$branch'"
    log_info "💡 Créez une $term avec : ${BOLD}gittbd pr $branch${RESET}"
    return 1
  fi
  
  log_success "$term trouvée"

  # === PHASE 4 : Vérification de la synchro ===
  local status
  status=$(get_branch_sync_status "$branch")

  if [[ "$status" != "synced" ]]; then
    log_warn "Branche '$branch' non synchronisée (statut: $status)"
    
    if [[ "$force_sync" == true ]]; then
      log_info "🔧 Synchronisation forcée en cours..."
      sync_branch_to_remote --force "$branch" || return 1
    else
      log_info "💡 Synchronisez avec : ${BOLD}gittbd publish $branch${RESET}"
      return 1
    fi
  fi

  # === PHASE 5 : Affichage du résumé (APRÈS toutes les I/O) ===
  echo ""
  log_info "📋 ${BOLD}Résumé de la $term${RESET}"
  echo ""
  
  git_platform_cmd pr-view "$branch" 2>/dev/null || {
    log_warn "Impossible d'afficher le détail de la $term"
  }
  
  echo ""

  # === PHASE 6 : Confirmation utilisateur ===
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

  # === PHASE 7 : Préparation du merge ===
  log_info "🔧 Préparation du merge..."
  
  local final_merge_mode
  final_merge_mode=$(prepare_merge_mode "$branch") || return 1

  # === PHASE 8 : Exécution finale ===
  finalize_branch_merge \
    --branch="$branch" \
    --merge-mode="$final_merge_mode" \
    --via-pr=true
}

# ====================================
# Gestion de versions (bump)
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
    log_info ""
    log_info "Usage : ${BOLD}gittbd bump <type>${RESET}"
    log_info ""
    log_info "Types :"
    log_info "  ${CYAN}major${RESET} : Changement cassant (1.0.0 → 2.0.0)"
    log_info "  ${CYAN}minor${RESET} : Nouvelle fonctionnalité (1.0.0 → 1.1.0)"
    log_info "  ${CYAN}patch${RESET} : Correction de bug (1.0.0 → 1.0.1)"
    log_info ""
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
  echo ""
  
  log_info "📝 ${BOLD}Changements depuis v${current_version}${RESET}"
  echo ""
  
  local changelog
  changelog=$(generate_changelog "$current_version")
  
  if [[ -z "$changelog" ]]; then
    log_warn "Aucun changement détecté depuis v${current_version}"
    echo ""
  else
    echo "$changelog"
    echo ""
  fi
  
  if [[ "$auto_confirm" != true ]]; then
    read -r -p "✅ Créer le tag v${new_version} ? [y/N] " confirm < /dev/tty
    
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
      log_warn "Bump annulé"
      return 1
    fi
  fi
  
  log_info "🏷️  Création du tag v${new_version}..."
  
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
        
        echo ""
        log_info "🔗 ${BOLD}Liens utiles${RESET}"
        echo "   Release : https://github.com/${repo_path}/releases/tag/v${new_version}"
        echo "   Compare : https://github.com/${repo_path}/compare/v${current_version}...v${new_version}"
      elif [[ "$remote_url" =~ gitlab\.com ]]; then
        local repo_path
        repo_path=$(echo "$remote_url" | sed -E 's/.*gitlab\.com[:/](.+)(\.git)?$/\1/')
        repo_path="${repo_path%.git}"
        
        echo ""
        log_info "🔗 ${BOLD}Liens utiles${RESET}"
        echo "   Tags    : https://gitlab.com/${repo_path}/-/tags/v${new_version}"
        echo "   Compare : https://gitlab.com/${repo_path}/-/compare/v${current_version}...v${new_version}"
      fi
    else
      log_error "Échec du push du tag"
      log_info "💡 Le tag existe localement, vous pouvez le pusher plus tard avec :"
      log_info "   git push origin v${new_version}"
      return 1
    fi
  else
    log_info "ℹ️  Tag créé localement uniquement (--no-push activé)"
    log_info "💡 Pour le pusher plus tard :"
    log_info "   git push origin v${new_version}"
  fi
  
  echo ""
  log_success "🎉 Version ${BOLD}v${new_version}${RESET} publiée avec succès !"
}
