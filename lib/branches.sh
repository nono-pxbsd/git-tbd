#!/bin/bash

# Définition des types et icônes de branches
# Types de branches supportés : feature, fix, hotfix, chore, refactor, test, doc
# Icônes associées pour une meilleure lisibilité
BRANCH_TYPES=("feature" "fix" "hotfix" "chore")
declare -A BRANCH_ICONS=(
  [feature]="✨"
  [fix]="🐛"
  [chore]="🧹"
  [refactor]="🔨"
  [test]="✅"
  [doc]="📚"
)

# Crée une branche à partir du type et du nom
# Usage : create_branch <type> <name>
# Exemple : create_branch feature my-feature
# Si le type ou le nom est manquant, affiche un message d'erreur
# Si la branche main n'existe pas, affiche un message d'erreur
# Si la branche est créée avec succès, affiche un message de succès
# Si la branche existe déjà, affiche un message d'avertissement
# Si la branche est créée, bascule sur cette branche
# Si la branche est créée, affiche un message de succès
create_branch() {
  local type="$1"
  local name="$2"

  if [[ -z "$type" || -z "$name" ]]; then
    echo -e "${YELLOW}⚠️  Type ou nom de branche manquant.${RESET}"
    return 1
  fi

  # Bascule sur main à jour
  git checkout main &>/dev/null || {
    echo -e "${YELLOW}⚠️  La branche main est introuvable.${RESET}"
    return 1
  }
  git pull &>/dev/null

  local full_branch="${type}/${name}"
  git checkout -b "$full_branch"
  echo -e "${GREEN}✅ Branche créée : ${full_branch}${RESET}"
}

# Génération des fonctions de démarrage pour chaque type de branche
# Usage : start_feature my-feature
# Exemple : start_feature my-feature
generate_start_functions() {
    for type in "${!BRANCH_TYPES[@]}"; do
    eval "
    start_${type}() {
        local name=\"\$1\"
        if [[ -z \"\$name\" ]]; then
        echo -e \"\${YELLOW}⚠️  Tu dois spécifier un nom de ${type}.\${RESET}\"
        exit 1
        fi
        create_branch \"${type}\" \"\$name\"
    }
    "
    done
}

# Fonction pour obtenir l'icône associée à un type de branche
# Usage : get_branch_icon <type>
# Exemple : get_branch_icon feature
# Retourne l'icône associée ou un message d'erreur si le type n'est pas supporté
# Si le type n'existe pas, retourne une icône par défaut
get_branch_icon() {
  local type="$1"
  echo "${BRANCH_ICONS[$type]}"
}

# Vérifie si une branche existe sur le dépôt distant
# Usage : remote_branch_exists <branch>
# Exemple : remote_branch_exists feature/my-feature
# Retourne 0 si la branche existe, 1 sinon
# Utilise git ls-remote pour vérifier l'existence de la branche
# Si la branche existe, retourne 0, sinon retourne 1
remote_branch_exists () {
  local branch="$1"
  git ls-remote --heads origin "$branch" | grep -q "$branch"
}

# Supprime une branche distante si elle existe
# Usage : delete_remote_branch <branch>
# Exemple : delete_remote_branch feature/my-feature
# Vérifie si la branche existe sur le dépôt distant
# Si la branche existe, utilise git push origin --delete pour la supprimer
# Redirige les erreurs vers /dev/null pour éviter les messages inutiles
# Affiche un message de succès ou d'avertissement selon le résultat
delete_remote_branch() {
  local branch="$1"
  if remote_branch_exists "$branch"; then
    git push origin --delete "$branch" 2>/dev/null || true
    echo -e "${YELLOW}🗑️  Branche distante ${branch} supprimée.${RESET}"
  fi
}

# Synchronise la branche courante avec la branche de base (par défaut main)
# Usage : sync_current_branch [--base=<branch>] [--force]
# Exemple : sync_current_branch --base=develop --force
# Vérifie si la branche courante est à jour avec la branche de base
# Si la branche courante est en avance et que --force n'est pas utilisé, affiche un avertissement
# Si la branche courante est en avance et que --force est utilisé, effectue un rebase
# Affiche un message de succès ou d'échec selon le résultat du rebase

sync_current_branch() {
  local force=false
  local base_branch="main"

  for arg in "$@"; do
    case "$arg" in
      --base=*) base_branch="${arg#*=}" ;;
      --force) force=true ;;
    esac
  done

  local current_branch=$(git symbolic-ref --short HEAD)
  echo -e "${BLUE}🔄 Synchronisation de ${current_branch} avec ${base_branch}...${RESET}"

  git fetch origin &>/dev/null

  # Vérifie les commits en avance et en retard
  local ahead=$(git rev-list --left-only --count "$current_branch"..."origin/${base_branch}")
  local behind=$(git rev-list --right-only --count "$current_branch"..."origin/${base_branch}")

  if [[ "$ahead" -eq 0 && "$behind" -eq 0 ]]; then
    echo -e "${GREEN}✅ ${current_branch} est déjà synchronisée avec ${base_branch}.${RESET}"
    return 0
  fi

  if [[ "$behind" -gt 0 ]]; then
    if [[ "$force" = false ]]; then
      echo -e "${YELLOW}⚠️  Des commits sont présents sur ${base_branch} mais pas sur ${current_branch}. Utilise --force pour forcer le rebase.${RESET}"
      return 1
    else
      echo -e "${YELLOW}⚠️  Rebase forcé malgré des commits en retard sur ${current_branch}.${RESET}"
    fi
  fi

  git rebase "origin/${base_branch}" &&
    echo -e "${GREEN}✅ ${current_branch} synchronisée avec ${base_branch}.${RESET}" ||
    echo -e "${RED}❌ Échec de la synchronisation avec ${base_branch}.${RESET}"
}
