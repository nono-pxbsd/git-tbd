#!/bin/bash
# lib/core/validation.sh
# shellcheck disable=SC2154

is_valid_branch_type() {
  # Vérifie si le type de branche existe dans BRANCH_ICONS
  local type="$1"
  [[ -n "${BRANCH_ICONS[$type]}" ]]
}

is_valid_branch_name() {
  # Vérifie si le nom de branche est valide
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
  # Normalise un nom de branche (slug)
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

parse_branch_input() {
  # Parse une entrée type "feature/login" en type + name
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
  # Retourne l'input ou la branche courante
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

get_branch_icon() {
  # Retourne l'icône d'un type de branche
  local type="$1"
  local icon="${BRANCH_ICONS[$type]}"
  [[ -n "$icon" ]] && echo "$icon"
}

is_current_branch() {
  # Vérifie si l'input est la branche courante
  local input="$1"
  local current
  current="$(git branch --show-current 2>/dev/null)"

  [[ "$input" == "$current" ]]
}