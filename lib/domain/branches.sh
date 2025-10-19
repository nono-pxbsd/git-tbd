#!/bin/bash
# lib/domain/branches.sh
# shellcheck disable=SC2154

create_branch() {
  # Crée une nouvelle branche depuis DEFAULT_BASE_BRANCH
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

local_branch_exists() {
  # Vérifie si une branche existe localement
  git rev-parse --verify "$1" >/dev/null 2>&1
}

remote_branch_exists() {
  # Vérifie si une branche existe sur origin
  local branch="$1"
  git ls-remote --heads origin "$branch" 2>/dev/null | grep -q "$branch"
}

branch_exists() {
  # Vérifie si une branche existe (local ou remote)
  local branch="$1"
  local_branch_exists "$branch" || remote_branch_exists "$branch"
}

delete_remote_branch() {
  # Supprime une branche sur origin
  local branch="$1"
  
  if remote_branch_exists "$branch"; then
    git_safe push origin --delete "$branch" || log_warn "Impossible de supprimer la branche distante"
    log_info "🗑️  Branche distante ${CYAN}$branch${RESET} supprimée"
  fi
}