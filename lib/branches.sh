#!/bin/bash

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
  local base_branch="main"

  if [[ -z "$type" || -z "$name" ]]; then
    echo -e "${YELLOW}⚠️  Type ou nom de branche manquant.${RESET}"
    return 1
  fi

  if git show-ref --verify --quiet "refs/heads/${type}/${name}"; then
    echo -e "${YELLOW}⚠️  La branche '${type}/${name}' existe déjà.${RESET}"
    return 1
  fi

  git checkout "$base_branch" &>/dev/null || {
    echo -e "${YELLOW}⚠️  La branche ${base_branch} est introuvable.${RESET}"
    return 1
  }

  git pull &>/dev/null

  local full_branch="${type}/${name}"
  git checkout -b "$full_branch"

  echo -e "${GREEN}✅ Branche créée : ${full_branch}${RESET}"
}

# Fonction pour analyser l'entrée de branche
# Usage : parse_branch_input <input>
# Exemple : parse_branch_input feature/my-feature
# Analyse l'entrée de branche pour extraire le type et le nom
# Si l'entrée ne contient pas de '/', affiche un message d'erreur
# Si l'entrée est valide, extrait le type et le nom de la branche
# Utilise la syntaxe de substitution de chaîne pour séparer le type et le nom
# Si l'entrée est valide, retourne le type et le nom de la branche
# Si l'entrée est invalide, affiche un message d'erreur et retourne 1
parse_branch_input() {
  local input="$1"
  if [[ "$input" != */* ]]; then
    echo "⛔ Format de branche invalide : '$input'. Attendu : type/nom"
    return 1
  fi
  branch_type="${input%%/*}"
  name="${input#*/}"
}

# Vérifie si une branche locale existe
# Usage : local_branch_exists <branch>
local_branch_exists() {
  git rev-parse --verify "$1" >/dev/null 2>&1
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

# Vérifie la synchro entre la branche locale et origin/<branche>
# Retourne : "synced", "ahead", "behind", "diverged"
get_branch_sync_status() {
  local branch="$1"
  local ahead behind

  ahead=$(git rev-list --left-right --count "$branch"...origin/"$branch" | awk '{print $1}')
  behind=$(git rev-list --left-right --count "$branch"...origin/"$branch" | awk '{print $2}')

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

# Retourne 0 si la branche est synchronisée avec la remote
# Usage : branch_is_sync <branch>
branch_is_sync() {
  [[ "$(get_branch_sync_status "$1")" == "synced" ]]
}


# Synchronise une branche locale avec sa version distante
# Usage : sync_branch_to_remote [--force] <branch>
# Exemple : sync_branch_to_remote feature/my-feature
# Si aucune branche n'est précisée, utilise la branche courante
# Vérifie que la branche actuelle est propre avant de continuer
# Vérifie que la branche cible est propre également
# Vérifie l'état de synchronisation de la branche cible
# Si la branche est déjà synchronisée, affiche un message et quitte
# Si la branche est en avance, affiche un message et quitte
# Si la branche est en retard, propose de forcer un rebase avec l'option --force
# Si --force est spécifié, force un rebase même si la branche locale est en retard
sync_branch_to_remote() {
  local target_branch=""
  local force=false

  # Parsing des arguments
  for arg in "$@"; do
    case "$arg" in
      --force) force=true ;;
      *) target_branch="$arg" ;;
    esac
  done

  # Si aucune branche précisée, on prend la branche courante
  if [[ -z "$target_branch" ]]; then
    target_branch=$(git symbolic-ref --short HEAD)
  fi

  local current_branch
  current_branch=$(git symbolic-ref --short HEAD)

  # Vérifie que la branche actuelle est propre (sinon refuse)
  is_branch_clean "$current_branch" || return $?

  # Vérifie que la branche cible est propre également (sinon refuse)
  if [[ "$current_branch" != "$target_branch" ]]; then
    is_branch_clean "$target_branch" || return $?
  fi

  # Récupère l'état de synchronisation
  local status
  status=$(get_branch_sync_status "$target_branch")

  case "$status" in
    synced)
      echo "✅ La branche '$target_branch' est déjà synchronisée avec origin/$target_branch."
      return 0
      ;;
    ahead)
      echo "📤 La branche '$target_branch' est en avance sur origin/$target_branch. Aucun rebase nécessaire."
      return 0
      ;;
    behind)
      if [[ "$force" == false ]]; then
        echo "⚠️ La branche '$target_branch' est en retard sur origin/$target_branch."
        echo "   Utilisez --force pour forcer un rebase automatique."
        return 1
      fi
      echo "🔁 Rebase forcé de '$target_branch' sur origin/$target_branch..."
      git checkout "$target_branch" --quiet || return 1
      if git rebase "origin/$target_branch"; then
        echo "✅ Rebase réussi de '$target_branch'."
      else
        echo "❌ Échec du rebase de '$target_branch'. Conflits à résoudre manuellement."
        return 1
      fi
      ;;
    diverged)
      echo "❌ La branche '$target_branch' a divergé d'origin/$target_branch."
      echo "   Rebase manuel requis. Aucun rebase automatique n'est tenté même avec --force."
      return 1
      ;;
    *)
      echo "❓ État inconnu pour la branche '$target_branch'."
      return 1
      ;;
  esac
}

is_valid_work_branch() {
  local branch="$1"

  # Conversion chaînes en tableaux
  IFS=',' read -ra protected <<< "$GIT_TBD_PROTECTED_BRANCHES"
  IFS=',' read -ra allowed <<< "$GIT_TBD_ALLOWED_PREFIXES"

  for b in "${protected[@]}"; do
    if [[ "$branch" == "$b" ]]; then
      echo "❌ '$branch' est une branche protégée. Action refusée."
      return 1
    fi
  done

  for prefix in "${allowed[@]}"; do
    # Debug
    if [[ "$branch" == "$prefix"* ]]; then
      return 0
    fi
  done

  echo "❌ '$branch' n'a pas de préfixe reconnu. Attendu : ${allowed[*]}/*"
  return 1
}

is_branch_clean() {
  local target_branch="${1:-$(git symbolic-ref --short HEAD)}"
  local current_branch
  current_branch=$(git symbolic-ref --short HEAD)

  # Si on vérifie une autre branche, il faut être clean avant de switcher
  if [[ "$target_branch" != "$current_branch" ]]; then
    if [[ -n $(git status --porcelain) ]]; then
      echo "⛔️ Impossible de switcher de branche : l'état actuel n'est pas propre."
      return 2
    fi

    # Vérifie que la branche existe localement
    if ! git rev-parse --verify --quiet "$target_branch" > /dev/null; then
      echo "❌ La branche '$target_branch' n'existe pas."
      return 3
    fi

    # Switch temporairement vers la branche cible
    git checkout "$target_branch" --quiet
    local switched=1
  fi

  # Vérifie : index, worktree, untracked, opérations en cours
  if [[ -n $(git diff --cached) ]]; then
    echo "🟠 Des fichiers sont en attente de commit (index)."
    [[ "$switched" == "1" ]] && git checkout "$current_branch" --quiet
    return 1
  fi
  if [[ -n $(git diff) ]]; then
    echo "🟠 Des modifications non committées sont présentes."
    [[ "$switched" == "1" ]] && git checkout "$current_branch" --quiet
    return 1
  fi
  if [[ -n $(git ls-files --others --exclude-standard) ]]; then
    echo "🟠 Des fichiers non suivis (untracked) sont présents."
    [[ "$switched" == "1" ]] && git checkout "$current_branch" --quiet
    return 1
  fi
  if [[ -d .git/rebase-merge || -d .git/rebase-apply || -f .git/MERGE_HEAD ]]; then
    echo "🛑 Une opération Git (rebase ou merge) est en cours."
    [[ "$switched" == "1" ]] && git checkout "$current_branch" --quiet
    return 1
  fi

  # Revenir à la branche initiale si on a switché
  [[ "$switched" == "1" ]] && git checkout "$current_branch" --quiet

  return 0
}

is_valid_branch_name() {
  local name="$1"

  # Refuse les noms vides ou trop courts
  if [[ -z "$name" || ${#name} -lt 3 ]]; then
    return 1
  fi

  # Interdits Git + caractères exotiques
  if [[ "$name" =~ [\ ~^:?*\[\\\]@{}] ]]; then
    return 1
  fi

  # Interdiction des doubles slash, tirets en début ou fin, etc.
  if [[ "$name" =~ (^[-/]|[-/]$|//|--) ]]; then
    return 1
  fi

  return 0
}

normalize_branch_name() {
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
