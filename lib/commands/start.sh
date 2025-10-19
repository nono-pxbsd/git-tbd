#!/bin/bash
# lib/commands/start.sh
# shellcheck disable=SC2154

select_branch_type() {
  # Sélection interactive du type de branche (fzf ou menu classique)
  local selected_type=""
  
  if command -v fzf >/dev/null 2>&1; then
    log_debug "Utilisation de fzf pour la sélection"
    
    local options=()
    for type in "${!BRANCH_ICONS[@]}"; do
      options+=("${BRANCH_ICONS[$type]} $type")
    done
    
    IFS=$'\n' options=($(sort <<<"${options[*]}"))
    unset IFS
    
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

start() {
  # Crée une nouvelle branche (3 modes : complet, semi-interactif, full interactif)
  log_debug "start() called with arguments: $*"

  local input="${1:-}"
  local type="" name="" full_branch_name=""

  # CAS 1 : Aucun argument → sélection interactive complète
  if [[ -z "$input" ]]; then
    log_info "🎯 Mode interactif activé"
    
    type=$(select_branch_type) || return 1
    
    print_message ""
    read -r -p "📝 Nom de la branche : " name < /dev/tty
    
    if [[ -z "$name" ]]; then
      log_error "Nom de branche requis"
      return 1
    fi
    
    name=$(normalize_branch_name "$name")
    full_branch_name="${type}/${name}"
    
  # CAS 2 : Argument sans slash → sélection du type uniquement
  elif [[ "$input" != */* ]]; then
    log_info "🎯 Type de branche non spécifié, sélection interactive"
    
    type=$(select_branch_type) || return 1
    
    name=$(normalize_branch_name "$input")
    full_branch_name="${type}/${name}"
    
  # CAS 3 : Format complet type/nom
  else
    if ! parse_branch_input "$input" type name; then
      return 1
    fi
    
    full_branch_name="${type}/${name}"
  fi

  # Validations finales
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

  # Affichage avec emoji
  local icon
  icon=$(get_branch_icon "$type")
  print_message ""
  log_success "Création de ${icon} ${CYAN}${full_branch_name}${RESET}"
  
  create_branch "$type" "$name"
}