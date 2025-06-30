#!/bin/bash

# Commande pour démarrer une nouvelle branche
# Utilise fzf pour sélectionner le type de branche et demande le nom
# Si un argument est passé, il est utilisé pour déterminer le type et le nom
# Si aucun argument n'est passé, demande interactive avec fzf
start() {
  local input="$1"
  local branch_type=""
  local name=""

  if [[ -n "$input" && "$input" == */* ]]; then
    branch_type="${input%%/*}"
    name="${input#*/}"
  fi

  # Si aucun type fourni, demande interactive avec fzf
  if [[ -z "$branch_type" || -z "$name" ]]; then
    if ! command -v fzf >/dev/null; then
      echo -e "${YELLOW}⚠️  La commande 'fzf' est requise si aucun argument n'est passé.${RESET}"
      return 1
    fi
    branch_type=$(printf "%s\n" "${BRANCH_TYPES[@]}" | fzf --prompt="🧭 Type de branche ? > " --height=10%)
    [[ -z "$branch_type" ]] && { echo -e "${YELLOW}⚠️  Aucun type sélectionné.${RESET}"; return 1; }
    echo -ne "📝 Nom de la branche : "
    read name
    [[ -z "$name" ]] && { echo -e "${YELLOW}⚠️  Nom requis.${RESET}"; return 1; }
  fi

  create_branch "$branch_type" "$name"
}

# Commande pour terminer une branche
# Fusionne la branche dans main et la supprime
# Si --pr est passé, ouvre une PR sur GitHub
# Si aucun argument n'est passé, déduit le type et le nom depuis la branche courante
# Si un argument est passé, il peut être de la forme type/name ou juste type
# Si deux arguments sont passés, ils sont considérés comme type et nom
# Si la branche courante est de type feature, fix, hotfix ou chore, elle est utilisée pour déduire le type et le nom
# Si la branche courante n'est pas de type supporté, affiche un message d'erreur
# Si la branche courante est de type supporté, fusionne et supprime la branche
# Si --pr est passé, ouvre une PR sur GitHub après avoir publié la branche
# Si la branche courante n'existe pas, affiche un message d'erreur
# Si la branche courante existe mais n'est pas publiée, publie la branche avant de fusionner
# Si la branche courante est déjà fusionnée, affiche un message d'information
# Si la branche courante est fusionnée avec succès, affiche un message de succès
# Si la branche courante est fusionnée mais ne peut pas être supprimée, affiche un message d'avertissement
# Si la branche courante est fusionnée mais ne peut pas être supprimée à distance, affiche un message d'avertissement
# Si la branche courante est fusionnée et supprimée avec succès, affiche un message de succès
finish() {
  local type=""
  local name=""
  local branch=""
  local current=""
  local open_pr=false

  # Récupération du HEAD
  current=$(git rev-parse --abbrev-ref HEAD)

  # Vérification présence de --pr
  for arg in "$@"; do
    if [[ "$arg" == "--pr" ]]; then
      open_pr=true
      set -- "${@/--pr/}" # suppression de l'argument de la liste
      break
    fi
  done

  # Déduction des arguments restants
  if [[ $# -eq 0 ]]; then
    # Déduire depuis la branche courante
    if [[ "$current" == */* ]]; then
      type="${current%%/*}"
      name="${current##*/}"
    else
      echo -e "${YELLOW}⚠️ Impossible de déterminer type/nom depuis la branche actuelle ($current).${RESET}"
      return 1
    fi
  elif [[ $# -eq 1 ]]; then
    if [[ "$1" == */* ]]; then
      type="${1%%/*}"
      name="${1##*/}"
    else
      type="$1"
      name="${current##*/}"
    fi
  elif [[ $# -eq 2 ]]; then
    type="$1"
    name="$2"
  else
    echo -e "${YELLOW}⚠️ Trop d'arguments. Usage : finish [type[/name]] | type name [--pr]${RESET}"
    return 1
  fi

  # Validation du type
  if [[ ! "$type" =~ ^(feature|fix|hotfix|chore)$ ]]; then
    echo -e "${YELLOW}⚠️ Type non supporté : ${type}.${RESET}"
    return 1
  fi

  branch="${type}/${name}"
  label="${type}(${name})"

  if [[ "$open_pr" == true ]]; then
    validate_pr "$branch" || {
      echo -e "${RED}❌ Échec de validation de la branche ${branch}, PR annulée.${RESET}"
      return 1
    }
    open_pr "$branch"
    return 0
  fi

  # Merge et suppression
  echo -e "${GREEN}🔀 Fusion de la branche ${branch} dans main...${RESET}"
  git checkout main && git pull || return 1
  git merge --no-ff "$branch" -m "$label: merge ${type} into main" || return 1

  if git show-ref --verify --quiet "refs/heads/${branch}"; then
    git branch -d "$branch"
  fi
  
  delete_remote_branch "$branch"

  echo -e "${GREEN}✅ Branche ${branch} fusionnée et supprimée.${RESET}"
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

  if ! branch_is_sync "$branch"; then
    local status
    status=$(get_branch_sync_status "$branch")

    if [[ "$status" == "behind" && "$force_sync" == true ]]; then
      sync_branch_to_remote --force "$branch" || return 1
    else
      sync_branch_to_remote "$branch" || return 1
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
  local input="$1"
  local branch=""
  local type=""
  local name=""

  if [[ -n "$input" ]]; then
    parse_branch_input "$input"
    type="$PARSED_TYPE"
    name="$PARSED_NAME"
    branch="$type/$name"
  else
    branch="$(git branch --show-current)"
    type="${branch%%/*}"
    name="${branch#*/}"
  fi

  if ! is_valid_work_branch "$branch"; then
    echo -e "${YELLOW}⚠️  La branche '$branch' n'est pas une branche de travail valide.${RESET}"
    return 1
  fi

  local prefix="${BRANCH_ICONS[$type]}"
  local title="${prefix}${name}"
  local body="${2:-Pull request automatique depuis \`$branch\` vers \`main\`}"

  publish "$branch" || return 1

  echo -e "🔁 Création de la PR via GitHub CLI..."
  gh pr create --base main --head "$branch" --title "$title" --body "$body"

  local url
  url=$(gh pr view "$branch" --json url -q ".url")

  echo -e "${GREEN}✅ PR créée depuis ${CYAN}$branch${GREEN} vers main.${RESET}"
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
  local merge_mode="merge"
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

  if [[ "$merge_mode" == "squash" && "$commit_count" -gt 1 ]]; then
    echo "🔄 Plusieurs commits détectés ($commit_count)."
    echo "☣️ L'utilisation du mode 'squash' de Github entraina une synchronisation manuelle forcée."
    echo "💡 Nous vous conseillons l'utilisation du local-squash pour 1 seul commit ou un mode merge classique avec l'ensemble des commits."
    echo ""
    if ! $assume_yes; then
      read -r -p "✅ Souhaitez-vous poursuivre avec un squash Github ? [y/N] " confirm_merge_mode
      if [[ "$confirm_merge_mode" =~ ^[Nn]$ ]]; then
        echo "❌ Squash Github annulé."
        return 1
      else
        echo "🔄 Choix du mode de merge : [ local-squash (rebase) | merge ]"
        read -r -p "✅ Quelle méthode souhaitez vous utiliser ? (laisser vide pour local-squash) : " merge_mode
        if [[ "$merge_mode" == "merge" ]]; then
          echo "👉 Choix manuel de la méthode merge"
        else
          echo "ℹ️ Utilisation de local-squash par défaut"
          merge_mode="local-squash"
        fi
      fi 
    else
      echo "🔄 Choix automatique de la méthode local-squash"
      merge_mode="local-squash"
    fi
  fi

  if [[ "$merge_mode" == "local-squash" ]]; then
    echo "🔄 Squash local en cours..."
    squash_commits_to_one "--method=rebase" || return 1
    echo "✅ Squash local effectué."
    echo "🔄 Publication de la branche après squash..."
    publish "$branch" --force-push || return 1
    echo "✅ Publication de la branche après squash réussie."
    $merge_mode="merge"
  fi

  echo "🚀 Validation en cours avec --$merge_mode..."
  gh pr merge "$branch" --"$merge_mode" --delete-branch
  echo "🎉 PR validée et branche supprimée."
}



