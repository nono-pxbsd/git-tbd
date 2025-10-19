#!/bin/bash
# lib/core/git_wrapper.sh
# shellcheck disable=SC2154

get_platform_term() {
  # Retourne "PR" ou "MR" selon la plateforme
  case "$GIT_PLATFORM" in
    gitlab) echo "MR" ;;
    *) echo "PR" ;;
  esac
}

get_platform_term_long() {
  # Retourne "Pull Request" ou "Merge Request"
  case "$GIT_PLATFORM" in
    gitlab) echo "Merge Request" ;;
    *) echo "Pull Request" ;;
  esac
}

git_safe() {
  # Wrapper sécurisé pour Git avec logging
  local output exit_code
  
  log_debug "Exécution : git $*"
  
  output=$(git "$@" 2>&1)
  exit_code=$?
  
  if [[ $exit_code -ne 0 ]]; then
    log_error "Échec de : git $*"
    [[ -n "$output" && "$DEBUG_MODE" == true ]] && echo "$output" >&2
  else
    log_debug "git $* → OK"
  fi
  
  return $exit_code
}

git_platform_cmd() {
  # Abstraction pour GitHub (gh) et GitLab (glab)
  local action="$1"
  shift
  
  log_debug "git_platform_cmd: $action sur $GIT_PLATFORM"
  
  case "$GIT_PLATFORM" in
    github)
      case "$action" in
        pr-create) gh pr create "$@" ;;
        pr-view) gh pr view "$@" ;;
        pr-merge) gh pr merge "$@" ;;
        pr-list) gh pr list "$@" ;;
        pr-exists)
          local branch="$1"
          gh pr list --head "$branch" --state open --json number --jq '.[0].number' 2>/dev/null
          ;;
      esac
      ;;
    gitlab)
      case "$action" in
        pr-create) glab mr create "$@" ;;
        pr-view) glab mr view "$@" ;;
        pr-merge) glab mr merge "$@" ;;
        pr-list) glab mr list "$@" ;;
        pr-exists)
          local branch="$1"
          glab mr list --source-branch="$branch" --state=opened --per-page=1 2>/dev/null | grep -q "!"
          ;;
      esac
      ;;
    *)
      log_error "Plateforme non supportée : $GIT_PLATFORM"
      log_info "💡 Plateformes disponibles : github, gitlab"
      return 1
      ;;
  esac
}