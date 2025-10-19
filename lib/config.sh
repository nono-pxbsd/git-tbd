#!/bin/bash
# config.sh - Configuration centrale de gittbd v3.0.0

# ====================================
# Configuration de base
# ====================================

# Branche principale cible pour les merges
DEFAULT_BASE_BRANCH="${DEFAULT_BASE_BRANCH:-main}"

# Mode de merge par défaut
# - squash : Squash tous les commits en 1 (recommandé pour historique propre)
# - merge  : Merge commit avec --no-ff (garde tous les commits)
DEFAULT_MERGE_MODE="${DEFAULT_MERGE_MODE:-squash}"

# Éditeur de texte par défaut pour les messages de commit
DEFAULT_EDITOR="${EDITOR:-vim}"

# Plateforme Git (github | gitlab)
GIT_PLATFORM="${GIT_PLATFORM:-github}"

# ====================================
# Apparence
# ====================================

# Utiliser des émojis dans les titres de commit (true | false)
USE_EMOJI_IN_COMMIT_TITLE="${USE_EMOJI_IN_COMMIT_TITLE:-true}"

# Icônes par type de branche
declare -A BRANCH_ICONS
BRANCH_ICONS=(
  [chore]="🧹"
  [doc]="📚"
  [feature]="✨"
  [fix]="🐛"
  [hotfix]="🚑"
  [refactor]="♻️"
  [release]="📦"
  [test]="🧪"
)

# Couleurs (utilisables dans toutes les fonctions)
RESET="\033[0m"
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
CYAN="\033[0;36m"
BOLD="\033[1m"

# ====================================
# Modes de fonctionnement
# ====================================

# Mode silencieux (false = verbeux, true = minimal)
# Active avec : SILENT_MODE=true gittbd <commande>
# Ou utilisez : gittbds <commande>
SILENT_MODE="${SILENT_MODE:-false}"

# Mode debug (affiche les appels de fonction et commandes internes)
# Mettre à true uniquement pour le développement
DEBUG_MODE="${DEBUG_MODE:-false}"

# ====================================
# Workflow Request (PR/MR)
# ====================================

# Ouvrir une Request (PR/MR) automatiquement après finish
# Si false, finish fait juste publish (sans créer de request)
OPEN_REQUEST="${OPEN_REQUEST:-true}"

# Exiger une Request (PR/MR) pour finaliser une branche
# Si true, finish --pr est obligatoire
# Si false, finish peut merger directement en local
REQUIRE_REQUEST_ON_FINISH="${REQUIRE_REQUEST_ON_FINISH:-true}"

# ====================================
# Gestion des branches divergées
# ====================================

# Stratégie par défaut quand une branche a divergé avec origin
# (après git commit --amend, rebase, ou push concurrent)
#
# Options :
#   - "ask"         : Demande à l'utilisateur quelle action prendre (défaut)
#                     Le prompt n'apparaît QUE sur branche divergée avec --force
#   - "force-push"  : Force push direct (assume réécriture locale intentionnelle)
#   - "force-sync"  : Sync (rebase) puis push (assume push concurrent)
#
# Cas d'usage :
#   - Travail solo / branche perso     → "force-push" (pas de prompt)
#   - Workflow TBD classique           → "ask" (sécurité)
#   - Collaboration sur même branche   → "force-sync" (intègre les changements)
DEFAULT_DIVERGED_STRATEGY="${DEFAULT_DIVERGED_STRATEGY:-ask}"

# En mode silencieux (CI/CD), si strategy = "ask", utiliser ce fallback
# Le mode silencieux évite les prompts bloquants tout en permettant l'automatisation
SILENT_DIVERGED_FALLBACK="${SILENT_DIVERGED_FALLBACK:-force-push}"

# ====================================
# Gestion du cleanup après merge GitHub/GitLab
# ====================================

# Auto-détecter et proposer le cleanup des branches mergées sur GitHub/GitLab
# Si true, gittbd vérifie au démarrage si des branches locales ont été mergées
# sur la plateforme distante et propose de les nettoyer
#
# Note : Cela effectue un appel API à chaque commande gittbd
# Recommandation : laisser à false et utiliser gittbd cleanup manuellement
AUTO_CLEANUP_DETECTION="${AUTO_CLEANUP_DETECTION:-false}"