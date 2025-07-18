# config.sh

# Branche principale cible pour les merges
DEFAULT_BASE_BRANCH="main"

# Mode de validation par défaut : squash | merge | local-squash
DEFAULT_MERGE_MODE="local-squash"

# Icônes par type de branche (utile pour les messages de commit)
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

# Mode silencieux par défaut (false = interaction demandée)
SILENT_MODE=false

# Ouvrir une Pull Request automatiquement après le merge
OPEN_PR=true

# Exiger une PR pour finaliser une branche
REQUIRE_PR_ON_FINISH=true
