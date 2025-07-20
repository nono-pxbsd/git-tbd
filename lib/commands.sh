#!/bin/bash

# Commande pour démarrer une nouvelle branche
# Utilise fzf pour sélectionner le type de branche et demande le nom
# Si un argument est passé, il est utilisé pour déterminer le type et le nom
# Si aucun argument n'est passé, demande interactive avec fzf
start() {
  local input="$1"
  local branch_type=""
  local name=""

  # 🔹 Si un nom est passé directement sous forme "prefix/nom"
  if [[ -n "$input" && "$input" == */* ]]; then
    branch_type="${input%%/*}"
    name="${input#*/}"
  fi

  # 🔸 Vérifie que l’état Git est propre
  if ! is_branch_clean; then
    echo -e "${YELLOW}⚠️  Tu dois d’abord nettoyer ton état Git avant de créer une nouvelle branche.${RESET}"
    return 1
  fi

  # 🔹 Si aucun type ou nom, propose via fzf
  if [[ -z "$branch_type" || -z "$name" ]]; then
    if ! command -v fzf >/dev/null; then
      echo -e "${YELLOW}⚠️  La commande 'fzf' est requise si aucun argument n’est passé.${RESET}"
      return 1
    fi

    branch_type=$(printf "%s\n" "${!BRANCH_TYPES[@]}" | fzf --prompt="🌟 Type de branche ? > " --height=10%)
    [[ -z "$branch_type" ]] && echo -e "${YELLOW}⚠️  Aucun type sélectionné.${RESET}" && return 1

    read -rp "📝 Nom de la branche : " name
    [[ -z "$name" ]] && echo -e "${YELLOW}⚠️  Nom requis.${RESET}" && return 1
  fi

  # 🔸 Nettoyage et validation du nom
  if ! is_valid_branch_name "$name"; then
    local original="$name"
    name=$(normalize_branch_name "$name")
    echo -e "${YELLOW}⚠️  Nom de branche invalide : '${original}' → corrigé en '${name}'.${RESET}"
  fi

  # ✅ Création
  create_branch "$branch_type" "$name"
}


finish() {
  local branch_input="" branch_type="" branch_name="" branch="" current=""
  local method="$DEFAULT_MERGE_METHOD"
  local open_pr="$OPEN_PR"
  local silent="$SILENT_MODE"
  local commit_msg=""

  current=$(git rev-parse --abbrev-ref HEAD)

  # -- Extraction des arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --pr|-p) open_pr=true ;;
      --silent|-s) silent=true ;;
      --method=*) method="${1#*=}" ;;
      --message=*) commit_msg="${1#*=}" ;;
      *)  # Premier argument positionnel = branche
          if [[ -z "$branch_input" ]]; then
            branch_input="$1"
          else
            echo -e "${YELLOW}⚠️  Trop d'arguments. Usage : finish [type/name] [--pr] [--silent] [--method=...] [--message=...]${RESET}"
            return 1
          fi
          ;;
    esac
    shift
  done

  # Récupère le nom et le type de branche depuis l'argument ou la branche courante
  branch_input="$(get_branch_input_or_current "$branch_input")"
  if ! parse_branch_input "$branch_input" branch_type branch_name; then
    return 1
  fi

  local branch="${branch_type}/${branch_name}"

  echo -e "${BLUE}📍Finalisation de la branche ${branch}.${RESET}"
  echo -e "Rappel : la branche par défaut est ${DEFAULT_BASE_BRANCH} et la branche courante est ${current} et la branche cible est ${branch}.${RESET}"

  if is_current_branch "$branch" && ! is_branch_clean "$branch"; then
    echo -e "${YELLOW}⚠️  La branche courante n'est pas propre : ${branch}. Tu dois d'abord la nettoyer.${RESET}"
    return 1
  fi

  if ! is_current_branch "$branch" && ! is_branch_clean "$branch"; then
    echo -e "${YELLOW}⚠️  La branche ${branch} n'est pas propre. Tu dois d'abord de positionner dessus et la nettoyer.${RESET}"
    return 1
  fi

  # Génère le titre et le body à partir du message ou par défaut
  build_commit_message "$branch" --merge-method="${method:-}" --silent="${silent:-}" --user-msg="${msg:-}"

  if pr_exists "$branch"; then
    # PR déjà ouverte → on valide
    validate_pr "$branch" ${silent:+--assume-yes} || return 1

  elif [[ "$open_pr" == true ]]; then
    # PR demandée → on ouvre si pas déjà présente, puis on valide
    open_pr "$branch" || return 1
    validate_pr "$branch" ${silent:+--assume-yes} || return 1

  elif [[ "$REQUIRE_PR_ON_FINISH" == true ]]; then
  # Politique globale : PR obligatoire
    echo -e "${YELLOW}⚠️  Aucune pull request détectée pour ${branch}.${RESET}"
    echo -e "${YELLOW}❌ La configuration actuelle impose une PR pour finaliser une branche.${RESET}"
  return 1

  else
    # Pas de PR, pas d’exigence → on merge directement
    $silent || echo -e "${GREEN}✅ Aucun PR détecté ou requis. Finalisation directe.${RESET}"
    merge_mode=$(prepare_merge_mode)
    [[ $? -ne 0 ]] && return 1
    finalize_branch_merge --branch="$branch" --merge-mode="$merge_mode" --via-pr=false
  fi
}

# Commande pour publier une branche
# Publie la branche courante vers l'origin
# Si un argument est passé, il est utilisé comme nom de branche
# Si aucun argument n'est passé, utilise la branche courante
# Si la branche n'existe pas, affiche un message d'erreur
# Si la branche est propre, publie la branche
# Si la branche n'est pas propre, affiche un message d'erreur
# Si la branche est déjà synchronisée avec l'origin, affiche un message d'information
# Si la branche n'est pas synchronisée, synchronise la branche avec l'origin
# Si la synchronisation échoue, affiche un message d'erreur
# Si la branche est publiée avec succès, affiche un message de succès
# Si la branche n'est pas publiée, affiche un message d'erreur
publish() {
  local force=false
  local branch="${1:-$(git symbolic-ref --short HEAD)}"

  # Gère les arguments comme --force
  for arg in "$@"; do
    case "$arg" in
      --force-sync) force_sync=true ;;
      --force-push) force_push=true ;;
    esac
  done

  if ! local_branch_exists "$branch"; then
    echo -e "${RED}✘ La branche locale '$branch' n'existe pas.${RESET}"
    return 1
  fi

  if is_branch_clean "$branch"; then
    echo "✅ La branche "$branch" est propre."
  else
    echo "❌ La branche "$branch" n’est pas propre ou impossible à vérifier."
    exit 1
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
  

  echo -e "${BLUE}🚀 Publication de la branche '$branch' vers origin...${RESET}"
  if [ "$force_push" == true ]; then
    git push -u origin "$branch" --force-with-lease || return 1
  else
    git push -u origin "$branch" || return 1
  fi

  echo -e "${GREEN}✅ Branche publiée avec succès.${RESET}"
}

# Commande pour ouvrir une Pull Request sur Github
# Ouvre une PR depuis la branche courante vers main
# Si un argument est passé, il est utilisé comme nom de branche
# Si aucun argument n'est passé, utilise la branche courante
# Si la branche n'est pas une branche de travail valide, affiche un message d'avertissement
# Si la branche est valide, publie la branche et ouvre une PR
# Si la PR est créée avec succès, affiche un message de succès avec le lien vers la PR
# Si la PR échoue, affiche un message d'erreur
# Utilise gh pr create pour créer la PR
# Utilise gh pr view pour obtenir l'URL de la PR créée
# Si gh pr create échoue, affiche un message d'erreur
# Si gh pr view échoue, affiche un message d'erreur
# Si la PR est créée, affiche un message de succès avec le lien vers la PR
open_pr() {
  local branch_input="$1"
  local branch_type="" branch_name=""

  # Récupère le nom et le type de branche depuis l'argument ou la branche courante
  branch_input="$(get_branch_input_or_current "$1")"
  if ! parse_branch_input "$branch_input" branch_type branch_name; then
    return 1
  fi

  local branch="${branch_type}/${branch_name}"
  local title="$(get_branch_icon "$branch_type")${branch_name}"
  local body="${2:-Pull request automatique depuis \`$branch\` vers \`${DEFAULT_BASE_BRANCH}\`}"

  publish "$branch" || return 1

  echo -e "🔁 Création de la PR via GitHub CLI..."
  gh pr create --base "$DEFAULT_BASE_BRANCH" --head "$branch" --title "$title" --body "$body"

  local url
  url=$(gh pr view "$branch" --json url -q ".url")

  echo -e "${GREEN}✅ PR créée depuis ${CYAN}$branch${GREEN} vers ${DEFAULT_BASE_BRANCH}.${RESET}"
  echo -e "🔗 Lien : ${BOLD}${url}${RESET}"
}

# Commande pour valider une Pull Request
# Valide une PR en vérifiant la propreté de la branche, son existence et sa synchronisation
# Si un argument est passé, il est utilisé comme nom de branche
# Si aucun argument n'est passé, utilise la branche courante
# Si la branche n'existe pas, affiche un message d'erreur
# Si la branche n'est pas propre, affiche un message d'erreur
# Si la PR n'existe pas, affiche un message d'erreur
# Si la branche n'est pas synchronisée avec l'origin, affiche un message d'avertissement
# Si la branche est synchronisée, affiche un résumé de la PR
# Si l'utilisateur confirme, valide la PR avec le mode de fusion spécifié (local-squash, squash, merge)
# Si l'utilisateur refuse, annule la validation
validate_pr() {
  local branch=""
  local merge_mode="squash"
  local assume_yes=false
  local force_sync=false

  local current_branch
  current_branch=$(git rev-parse --abbrev-ref HEAD)

  # -- Parsing des arguments
  local args=()
  for arg in "$@"; do
    case "$arg" in
      --merge-mode=*) merge_mode="${arg#*=}" ;;
      -y|--assume-yes) assume_yes=true ;;
      --force-sync) force_sync=true ;;
      -*) ;;  # ignore les options inconnues
      *) args+=("$arg") ;;  # arguments restants (ex. : nom de branche)
    esac
  done

  # Détection de la branche cible
  if [[ ${#args[@]} -gt 0 ]]; then
    branch="${args[0]}"
  else
    branch="$current_branch"
  fi

  echo "🔍 Validation de la PR sur branche : $branch"

  # Vérifie existence de branche
  if ! local_branch_exists "$branch"; then
    echo -e "${RED}❌ La branche '$branch' n'existe pas.${RESET}"
    return 1
  fi

  # Vérifie propreté de la branche
  if ! is_branch_clean "$branch"; then
    echo -e "${RED}❌ La branche '$branch' n’est pas propre.${RESET}"
    return 1
  fi

  # Vérifie si une PR existe
  echo "🔄 Vérification de l'existence d'une PR..."
  if ! gh pr view "$branch" &>/dev/null; then
    echo "❌ Aucune Pull Request trouvée pour la branche '$branch'."
    echo "💡 Créez une PR avec : git-tbd open_pr $branch"
    return 1
  fi

  # Vérifie que la branche locale est bien synchronisée avec l'origin
  echo "🔄 Vérification de la synchronisation avec la remote..."
  git fetch origin "$branch" &>/dev/null

  # -- Synchronisation éventuelle
  local status
  status=$(get_branch_sync_status "$branch")

  if [[ "$status" != "synced" ]]; then
    echo "⚠️  Branche '$branch' non synchronisée (statut: $status)."
    if [[ "$force" == true ]]; then
      echo "🔧 Tentative de synchronisation forcée..."
      sync_branch_to_remote --force "$branch" || return 1
    else
      echo "💡 Corrigez cela avec : git-tbd publish $branch"
      return 1
    fi
  fi

  # -- Affichage du résumé de PR
  echo ""
  echo "📋 Résumé de la PR :"
  gh pr view "$branch" --web

  # -- Confirmation ou mode automatique
  if ! $assume_yes; then
    read -r -p "✅ Souhaitez-vous valider (merger) la PR ? (détection du mode ensuite) [y/N] " confirm
  else
    confirm="y"
  fi

  if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "❌ Validation annulée."
    return 1
  fi

  local commit_count
  commit_count=$(get_commit_count_between_branches "origin/main" "$current_branch")

  finalize_branch_merge --branch="$branch" --merge-mode="$merge_mode" --via-pr=true
}