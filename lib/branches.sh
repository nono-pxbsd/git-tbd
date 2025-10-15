#!/bin/bash
# branches.sh - Gestion des branches

create_branch() {
  local type="$1"
  local name="$2"
  local base_branch="$DEFAULT_BASE_BRANCH"

  if [[ -z "$type" || -z "$name" ]]; then
    log_error "Type ou nom de branche manquant"
    return 1
  fi

  local full_branch="${type}/${name}"

  if git show-ref --verify --quiet "refs/heads/$full_branch"; then
    log_warn "La branche '$full_branch' existe déjà"
    return 1
  fi

  log_info "🔄 Basculement sur ${CYAN}$base_branch${RESET}"
  git_safe checkout "$base_branch" || {
    log_error "La branche $base_branch est introuvable"
    return 1
  }

  log_info "⬇️  Mise à jour de $base_branch"
  git_safe pull || return 1

  log_info "🌱 Création de la branche ${CYAN}$full_branch${RESET}"
  git_safe checkout -b "$full_branch" || return 1

  log_success "Branche créée : ${BOLD}$full_branch${RESET}"
}

parse_branch_input() {
  local input="$1"
  local -n out_type=$2
  local -n out_name=$3

  if [[ "$input" != */* ]]; then
    log_error "Format de branche invalide : '$input'. Attendu : type/nom"
    return 1
  fi

  local type="${input%%/*}"
  local name="${input#*/}"

  log_debug "parse_branch_input() → type: $type, name: $name"

  if [[ -z "${BRANCH_ICONS[$type]}" ]]; then
    log_warn "Type de branche non reconnu : '$type'"
    log_info "💡 Types disponibles : ${!BRANCH_ICONS[*]}"
    return 1
  fi
  
  out_type="$type"
  out_name="$name"
  return 0
}

get_branch_input_or_current() {
  local input="$1"

  if [[ -n "$input" ]]; then
    echo "$input"
  else
    local current_branch
    current_branch=$(git symbolic-ref --quiet --short HEAD 2>/dev/null)

    if [[ -z "$current_branch" ]]; then
      log_error "Impossible de déterminer la branche courante (HEAD détaché ?)"
      return 1
    fi

    echo "$current_branch"
  fi
}

is_valid_branch_type() {
  local type="$1"
  [[ -n "${BRANCH_ICONS[$type]}" ]]
}

is_current_branch() {
  local input="$1"
  local current
  current="$(git branch --show-current 2>/dev/null)"

  [[ "$input" == "$current" ]]
}

get_branch_icon() {
  local type="$1"
  local icon="${BRANCH_ICONS[$type]}"
  [[ -n "$icon" ]] && echo "$icon"
}

local_branch_exists() {
  git rev-parse --verify "$1" >/dev/null 2>&1
}

remote_branch_exists() {
  local branch="$1"
  git ls-remote --heads origin "$branch" 2>/dev/null | grep -q "$branch"
}

branch_exists() {
  local branch="$1"
  local_branch_exists "$branch" || remote_branch_exists "$branch"
}

delete_remote_branch() {
  local branch="$1"
  
  if remote_branch_exists "$branch"; then
    git_safe push origin --delete "$branch" || log_warn "Impossible de supprimer la branche distante"
    log_info "🗑️  Branche distante ${CYAN}$branch${RESET} supprimée"
  fi
}

get_branch_sync_status() {
  local branch="$1"
  local ahead behind

  ahead=$(git rev-list --left-right --count "$branch"...origin/"$branch" 2>/dev/null | awk '{print $1}')
  behind=$(git rev-list --left-right --count "$branch"...origin/"$branch" 2>/dev/null | awk '{print $2}')

  if [[ "$ahead" -gt 0 && "$behind" -gt 0 ]]; then
    echo "diverged"
  elif [[ "$ahead" -gt 0 ]]; then
    echo "ahead"
  elif [[ "$behind" -gt 0 ]]; then
    echo "behind"
  else
    echo "synced"
  fi
}

branch_is_sync() {
  [[ "$(get_branch_sync_status "$1")" == "synced" ]]
}

sync_branch_to_remote() {
  local target_branch=""
  local force=false

  for arg in "$@"; do
    case "$arg" in
      --force) force=true ;;
      *) target_branch="$arg" ;;
    esac
  done

  if [[ -z "$target_branch" ]]; then
    target_branch=$(git symbolic-ref --short HEAD 2>/dev/null)
  fi

  local current_branch
  current_branch=$(git symbolic-ref --short HEAD 2>/dev/null)

  is_branch_clean "$current_branch" || return $?

  if [[ "$current_branch" != "$target_branch" ]]; then
    is_branch_clean "$target_branch" || return $?
  fi

  local status
  status=$(get_branch_sync_status "$target_branch")

  case "$status" in
    synced)
      log_success "La branche '$target_branch' est déjà synchronisée"
      return 0
      ;;
    ahead)
      log_info "📤 La branche '$target_branch' est en avance sur origin"
      return 0
      ;;
    behind)
      if [[ "$force" == false ]]; then
        log_warn "La branche '$target_branch' est en retard sur origin"
        log_info "💡 Utilisez --force pour forcer un rebase automatique"
        return 1
      fi
      
      log_info "🔄 Rebase forcé de '$target_branch' sur origin/$target_branch"
      git_safe checkout "$target_branch" || return 1
      
      if git_safe rebase "origin/$target_branch"; then
        log_success "Rebase réussi"
      else
        log_error "Échec du rebase. Résolvez les conflits manuellement"
        return 1
      fi
      ;;
    diverged)
      log_error "La branche '$target_branch' a divergé d'origin/$target_branch"
      log_info "💡 Rebase manuel requis. Aucun rebase automatique possible"
      return 1
      ;;
    *)
      log_error "État inconnu pour la branche '$target_branch'"
      return 1
      ;;
  esac
}

is_branch_clean() {
  local target_branch="$1"
  local current_branch
  current_branch="$(git symbolic-ref --short HEAD 2>/dev/null)"

  if is_current_branch "$target_branch"; then
    is_worktree_clean
    return $?
  fi

  if ! is_worktree_clean; then
    log_error "La branche courante '${current_branch}' n'est pas propre"
    return 2
  fi

  if ! git rev-parse --verify --quiet "$target_branch" >/dev/null 2>&1; then
    log_error "La branche cible '${target_branch}' n'existe pas"
    return 3
  fi

  if ! git_safe checkout "$target_branch"; then
    log_error "Échec du checkout vers '${target_branch}'"
    return 4
  fi

  local result=0
  if ! is_worktree_clean; then
    result=1
  fi

  git_safe checkout "$current_branch"

  return "$result"
}

is_worktree_clean() {
  if [[ -n $(git diff --cached 2>/dev/null) ]]; then
    log_debug "Des fichiers sont en attente de commit (index)"
    return 1
  fi

  if [[ -n $(git diff 2>/dev/null) ]]; then
    log_debug "Des modifications non committées sont présentes"
    return 1
  fi

  if [[ -n $(git ls-files --others --exclude-standard 2>/dev/null) ]]; then
    log_debug "Des fichiers non suivis (untracked) sont présents"
    return 1
  fi

  if [[ -d .git/rebase-merge || -d .git/rebase-apply || -f .git/MERGE_HEAD ]]; then
    log_debug "Une opération Git (rebase ou merge) est en cours"
    return 1
  fi

  return 0
}

is_valid_branch_name() {
  local name="$1"

  if [[ -z "$name" || ${#name} -lt 3 ]]; then
    return 1
  fi

  if [[ "$name" =~ [\ ~^:?*\[\\\]@{}] ]]; then
    return 1
  fi

  if [[ "$name" =~ (^[-/]|[-/]$|//|--) ]]; then
    return 1
  fi

  return 0
}

normalize_branch_name() {
  local raw="$1"
  local slug

  slug=$(echo "$raw" \
    | iconv -f utf-8 -t ascii//TRANSLIT 2>/dev/null \
    | tr '[:upper:]' '[:lower:]' \
    | sed -E 's/[^a-z0-9]+/-/g' \
    | sed -E 's/^-+|-+$//g' \
    | sed -E 's/--+/-/g')

  [[ -z "$slug" ]] && slug="branch-$(date +%s)"

  echo "$slug"
}
