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

  if [[ "$open_pr" = true ]]; then
    publish "$branch" || {
      echo -e "${RED}❌ Impossible de publier ${branch}, PR annulée.${RESET}"
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

  if remote_branch_exists  "$branch"; then
    git push origin --delete "$branch" 2>/dev/null || true
  fi
  echo -e "${GREEN}✅ Branche ${branch} fusionnée et supprimée.${RESET}"
}

# Commande pour publier une branche
# Publie la branche courante vers origin si elle n'est pas déjà publiée
# Si un argument est passé, il est utilisé comme nom de branche
# Si aucun argument n'est passé, utilise la branche courante
# Si la branche n'existe pas, affiche un message d'erreur
# Si la branche existe déjà sur origin, affiche un message d'information
# Si la branche n'existe pas sur origin, la publie et configure le suivi
# Si la branche est publiée avec succès, affiche un message de succès
publish() {
  local branch="${1:-$(git symbolic-ref --short HEAD)}"

  if ! git rev-parse --verify "$branch" >/dev/null 2>&1; then
    echo "❌ La branche locale '$branch' n'existe pas."
    return 1
  fi

  if remote_branch_exists  "$branch"; then
    echo "✅ La branche '$branch' est déjà publiée sur origin."
  else
    sync_current_branch --force || return 1
    echo "📤 Publication de la branche '$branch' vers origin..."
    git push -u origin "$branch"
  fi
}

# Commande pour ouvrir une Pull Request GitHub
# Ouvre une PR depuis la branche courante vers main
# Si un argument est passé, il est utilisé comme corps de la PR
# Si aucun argument n'est passé, utilise un corps par défaut
# Si la branche courante n'existe pas, affiche un message d'erreur
# Si la branche courante n'est pas publiée, publie la branche avant d'ouvrir la PR
# Si la PR est créée avec succès, affiche un message de succès et le lien
# Si la PR ne peut pas être créée, affiche un message d'erreur
# Utilise GitHub CLI pour créer la PR
# Si GitHub CLI n'est pas installé, affiche un message d'erreur
# Si la branche courante n'est pas de type supporté, affiche un message d'avertissement
# Si la PR est créée, affiche le lien vers la PR
function open_pr() {
  local branch=$(git rev-parse --abbrev-ref HEAD)

  branch_type=$(echo "$branch" | cut -d'/' -f1)
  branch_name=${branch#"$branch_type"/}

  if [[ -z "${BRANCH_ICONS[$branch_type]}" ]]; then
    echo -e "${YELLOW}⚠️  Type de branche non supporté : ${branch_type}${RESET}"
    exit 1
  fi

  local prefix="${BRANCH_ICONS[$branch_type]}"
  local title="${prefix}(${branch_name})"
  local body="${2:-Pull request automatique depuis \`$branch\` vers \`main\`}"

  publish "$branch" || return 1

  # Création de la PR via GitHub CLI
  gh pr create --base main --head "$branch" --title "$title" --body "$body"

  # Récupération du lien vers la PR
  local url=$(gh pr view "$branch" --json url -q ".url")
  echo -e "${GREEN}✅ PR créée depuis $branch vers main${RESET}"
  echo -e "🔗 Lien : ${BOLD}${url}${RESET}"
}