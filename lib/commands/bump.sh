#!/bin/bash
# lib/commands/bump.sh
# shellcheck disable=SC2154

get_latest_version() {
  # Récupère la dernière version (tag)
  local version
  version=$(git describe --tags --abbrev=0 2>/dev/null)
  
  if [[ -z "$version" ]]; then
    echo "0.0.0"
  else
    echo "${version#v}"
  fi
}

parse_version() {
  # Parse une version SemVer
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
  # Incrémente une version selon le type
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
  # Génère le changelog entre deux tags
  local from_tag="$1"
  local to_ref="${2:-HEAD}"
  
  if [[ "$from_tag" == "0.0.0" ]]; then
    git log --pretty=format:"- %s (%h)" "$to_ref" 2>/dev/null
  else
    git log --pretty=format:"- %s (%h)" "v${from_tag}..${to_ref}" 2>/dev/null
  fi
}

bump() {
  # Crée un tag de version (major/minor/patch)
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