#!/bin/bash
# lib/domain/sync.sh
# shellcheck disable=SC2154

get_branch_sync_status() {
  # Retourne : synced | ahead | behind | diverged
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
  # Vérifie si une branche est synced
  [[ "$(get_branch_sync_status "$1")" == "synced" ]]
}

sync_branch_to_remote() {
  # Synchronise une branche avec origin (rebase)
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
  # Vérifie si une branche est propre (pas de modifs non committées)
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
  # Vérifie si le worktree est propre
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