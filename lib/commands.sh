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
      --force) force=true ;;
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

    if [[ "$status" == "behind" && "$force" == true ]]; then
      sync_branch_to_remote --force "$branch" || return 1
    else
      sync_branch_to_remote "$branch" || return 1
    fi
  fi

  echo -e "${BLUE}🚀 Publication de la branche '$branch' vers origin...${RESET}"
  git push -u origin "$branch" || return 1

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


validate_pr() {
  local branch="$1"
  local current_branch
  current_branch=$(git rev-parse --abbrev-ref HEAD)

  # Détection de la branche cible
  if [[ -z "$branch" ]]; then
    branch="$current_branch"
  fi

  echo "🔍 Validation de la PR pour la branche : $branch"

  # Extraire le type et le nom via parse_branch_input
  local branch_type name
  if ! parse_branch_input "$branch"; then
    echo -e "${YELLOW}⚠️ Format de branche invalide. Attendu : type/nom${RESET}"
    return 1
  fi

  # On utilise les variables globales définies dans parse_branch_input
  branch_type="$branch_type"
  name="$name"

  # Vérification de la branche
  if ! is_valid_work_branch "$branch"; then
    return 1
  fi

  # Vérifier si une PR existe
  echo "🔄 Vérification de l'existence d'une PR..."
  if ! gh pr view "$branch" &>/dev/null; then
    echo "❌ Aucune Pull Request trouvée pour la branche '$branch'."
    echo "💡 Créez une PR avec : git-tbd open_pr $branch"
    return 1
  fi

  # Vérifier que la branche locale est bien synchronisée avec l'origin
  echo "🔄 Vérification de la synchronisation avec la remote..."
  git fetch origin "$branch" &>/dev/null

  local ahead behind
  ahead=$(git rev-list --left-right --count "$branch"...origin/"$branch" | awk '{print $1}')
  behind=$(git rev-list --left-right --count "$branch"...origin/"$branch" | awk '{print $2}')

  if [[ "$ahead" -gt 0 && "$behind" -gt 0 ]]; then
    echo "⚠️  La branche '$branch' est désynchronisée (en avance ET en retard)."
    echo "💡 Résolvez les conflits avec un rebase ou un merge :"
    echo "    git fetch origin && git rebase origin/$branch"
    return 1
  elif [[ "$ahead" -gt 0 ]]; then
    echo "⚠️  La branche '$branch' est en avance sur origin/$branch."
    echo "💡 Faites un publish : git-tbd publish $branch"
    return 1
  elif [[ "$behind" -gt 0 ]]; then
    echo "⚠️  La branche '$branch' est en retard sur origin/$branch."
    echo "💡 Mettez à jour avec : git pull ou git fetch && git rebase origin/$branch"
    return 1
  fi

  echo "✅ La branche est synchronisée avec la remote."

  # Afficher les détails et proposer la validation
  echo "📋 Résumé de la PR :"
  gh pr view "$branch" --web

  echo
  read -r -p "🚀 Souhaitez-vous valider (merger) la PR ? [y/N] " confirm
  if [[ "$confirm" =~ ^[Yy]$ ]]; then
    echo "🔧 Validation en cours..."
    gh pr merge "$branch" --squash --delete-branch
    echo "✅ PR validée et branche supprimée."
  else
    echo "❌ Validation annulée par l'utilisateur."
  fi
}



