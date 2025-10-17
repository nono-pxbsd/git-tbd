#!/bin/bash
# setup-silent-mode.sh - Configure le mode silencieux automatiquement

set -euo pipefail

BOLD="\e[1m"
GREEN="\e[32m"
YELLOW="\e[33m"
CYAN="\e[36m"
RESET="\e[0m"

echo -e "${BOLD}🔇 Configuration du mode silencieux pour gittbd${RESET}"
echo ""

# Détection du shell
detect_shell() {
  if [[ -n "${ZSH_VERSION:-}" ]]; then
    echo "zsh"
  elif [[ -n "${BASH_VERSION:-}" ]]; then
    echo "bash"
  else
    # Fallback : regarder le shell par défaut
    basename "$SHELL"
  fi
}

# Détection du fichier de config
get_shell_config() {
  local shell="$1"
  
  case "$shell" in
    zsh)
      if [[ -f "$HOME/.zshrc" ]]; then
        echo "$HOME/.zshrc"
      else
        echo "$HOME/.zshrc"
      fi
      ;;
    bash)
      if [[ -f "$HOME/.bashrc" ]]; then
        echo "$HOME/.bashrc"
      elif [[ -f "$HOME/.bash_profile" ]]; then
        echo "$HOME/.bash_profile"
      else
        echo "$HOME/.bashrc"
      fi
      ;;
    *)
      echo "$HOME/.profile"
      ;;
  esac
}

# Détection automatique
DETECTED_SHELL=$(detect_shell)
DETECTED_CONFIG=$(get_shell_config "$DETECTED_SHELL")

echo -e "🔍 Détection automatique :"
echo -e "   Shell : ${CYAN}$DETECTED_SHELL${RESET}"
echo -e "   Config : ${CYAN}$DETECTED_CONFIG${RESET}"
echo ""

# Confirmation avec fzf si disponible, sinon menu classique
if command -v fzf >/dev/null 2>&1; then
  # Menu fzf
  echo "Sélectionnez votre shell (ou validez la détection) :"
  echo ""
  
  SHELL_OPTIONS=(
    "$DETECTED_SHELL (détecté) → $DETECTED_CONFIG"
    "zsh → $HOME/.zshrc"
    "bash → $HOME/.bashrc"
    "fish → $HOME/.config/fish/config.fish"
    "Saisie manuelle"
  )
  
  SELECTED=$(printf "%s\n" "${SHELL_OPTIONS[@]}" | fzf --height=40% --border --prompt="Shell : ")
  
  if [[ -z "$SELECTED" ]]; then
    echo -e "${YELLOW}Sélection annulée${RESET}"
    exit 0
  fi
  
  # Parser la sélection
  if [[ "$SELECTED" == *"Saisie manuelle"* ]]; then
    read -p "Chemin du fichier de config : " CONFIG_FILE
    SHELL_TYPE="custom"
  else
    # Extraire le shell et le chemin
    SHELL_TYPE=$(echo "$SELECTED" | awk '{print $1}')
    CONFIG_FILE=$(echo "$SELECTED" | grep -oP '→ \K.*')
  fi
  
else
  # Menu classique
  echo "Le shell détecté est : ${BOLD}$DETECTED_SHELL${RESET}"
  echo "Fichier de config : ${BOLD}$DETECTED_CONFIG${RESET}"
  echo ""
  read -p "Est-ce correct ? [Y/n] " confirm
  
  if [[ "$confirm" =~ ^[Nn]$ ]]; then
    echo ""
    echo "Choisissez votre shell :"
    echo "  1. zsh"
    echo "  2. bash"
    echo "  3. fish"
    echo "  4. Saisie manuelle"
    echo ""
    read -p "Votre choix [1-4] : " shell_choice
    
    case "$shell_choice" in
      1)
        SHELL_TYPE="zsh"
        CONFIG_FILE="$HOME/.zshrc"
        ;;
      2)
        SHELL_TYPE="bash"
        CONFIG_FILE="$HOME/.bashrc"
        ;;
      3)
        SHELL_TYPE="fish"
        CONFIG_FILE="$HOME/.config/fish/config.fish"
        ;;
      4)
        read -p "Chemin du fichier de config : " CONFIG_FILE
        SHELL_TYPE="custom"
        ;;
      *)
        echo -e "${YELLOW}Choix invalide. Utilisation de la détection automatique.${RESET}"
        SHELL_TYPE="$DETECTED_SHELL"
        CONFIG_FILE="$DETECTED_CONFIG"
        ;;
    esac
  else
    SHELL_TYPE="$DETECTED_SHELL"
    CONFIG_FILE="$DETECTED_CONFIG"
  fi
fi

echo ""
echo -e "✅ Configuration choisie :"
echo -e "   Shell : ${CYAN}$SHELL_TYPE${RESET}"
echo -e "   Fichier : ${CYAN}$CONFIG_FILE${RESET}"
echo ""

# Vérifier si déjà configuré
if grep -q "export SILENT_MODE=true" "$CONFIG_FILE" 2>/dev/null; then
  echo -e "${YELLOW}⚠️  Le mode silencieux est déjà configuré dans $CONFIG_FILE${RESET}"
  echo ""
  read -p "Voulez-vous le désactiver ? [y/N] " response
  
  if [[ "$response" =~ ^[Yy]$ ]]; then
    # Supprimer la ligne
    if [[ "$OSTYPE" == "darwin"* ]]; then
      # macOS
      sed -i '' '/export SILENT_MODE=true/d' "$CONFIG_FILE"
    else
      # Linux
      sed -i '/export SILENT_MODE=true/d' "$CONFIG_FILE"
    fi
    echo -e "${GREEN}✅ Mode silencieux désactivé${RESET}"
    echo -e "Rechargez votre shell : ${BOLD}source $CONFIG_FILE${RESET}"
  else
    echo "Aucun changement effectué"
  fi
  exit 0
fi

# Menu de choix
echo -e "${BOLD}Choisissez votre mode préféré :${RESET}"
echo ""
echo "  1. Mode silencieux PAR DÉFAUT"
echo "     → gittbd finish sera toujours silencieux"
echo "     → Utilisez SILENT_MODE=false pour mode verbeux ponctuel"
echo ""
echo "  2. Alias 'gittbds' (mode silencieux optionnel)"
echo "     → gittbd finish = mode verbeux"
echo "     → gittbds finish = mode silencieux"
echo ""
echo "  3. Les deux (recommandé pour flexibilité)"
echo ""
read -p "Votre choix [1/2/3] : " choice

case "$choice" in
  1)
    # Mode silencieux par défaut
    echo "" >> "$CONFIG_FILE"
    echo "# gittbd - Mode silencieux par défaut" >> "$CONFIG_FILE"
    echo "export SILENT_MODE=true" >> "$CONFIG_FILE"
    
    echo ""
    echo -e "${GREEN}✅ Mode silencieux activé par défaut${RESET}"
    echo ""
    echo "Utilisation :"
    echo "  - ${CYAN}gittbd finish${RESET}              → Silencieux"
    echo "  - ${CYAN}SILENT_MODE=false gittbd finish${RESET} → Verbeux ponctuellement"
    ;;
    
  2)
    # Alias uniquement
    echo "" >> "$CONFIG_FILE"
    echo "# gittbd - Alias mode silencieux" >> "$CONFIG_FILE"
    echo "alias gittbds='SILENT_MODE=true gittbd'" >> "$CONFIG_FILE"
    
    echo ""
    echo -e "${GREEN}✅ Alias 'gittbds' créé${RESET}"
    echo ""
    echo "Utilisation :"
    echo "  - ${CYAN}gittbd finish${RESET}  → Verbeux (normal)"
    echo "  - ${CYAN}gittbds finish${RESET} → Silencieux"
    ;;
    
  3)
    # Les deux
    echo "" >> "$CONFIG_FILE"
    echo "# gittbd - Configuration mode silencieux" >> "$CONFIG_FILE"
    echo "export SILENT_MODE=true" >> "$CONFIG_FILE"
    echo "alias gittbds='SILENT_MODE=true gittbd'  # Alias explicite" >> "$CONFIG_FILE"
    
    echo ""
    echo -e "${GREEN}✅ Configuration complète installée${RESET}"
    echo ""
    echo "Utilisation :"
    echo "  - ${CYAN}gittbd finish${RESET}  → Silencieux (par défaut)"
    echo "  - ${CYAN}gittbds finish${RESET} → Silencieux (explicite, même résultat)"
    echo "  - ${CYAN}SILENT_MODE=false gittbd finish${RESET} → Verbeux ponctuellement"
    ;;
    
  *)
    echo -e "${YELLOW}Choix invalide. Aucun changement effectué.${RESET}"
    exit 1
    ;;
esac

echo ""
echo -e "${BOLD}📝 Pour activer immédiatement :${RESET}"
echo -e "   ${CYAN}source $CONFIG_FILE${RESET}"
echo ""
echo -e "${BOLD}🔄 Ou fermez et rouvrez votre terminal${RESET}"
echo ""

# Proposer de recharger automatiquement
read -p "Voulez-vous recharger maintenant ? [Y/n] " reload

if [[ ! "$reload" =~ ^[Nn]$ ]]; then
  # On ne peut pas vraiment "source" depuis un script qui affecte le shell parent
  # Mais on peut donner les instructions
  echo ""
  echo -e "${YELLOW}⚠️  Pour des raisons techniques, vous devez exécuter :${RESET}"
  echo -e "   ${BOLD}${CYAN}source $CONFIG_FILE${RESET}"
  echo ""
  echo "Ou copiez-collez cette commande :"
  echo ""
  echo -e "${BOLD}source $CONFIG_FILE${RESET}"
fi

echo ""
echo -e "${GREEN}✅ Configuration terminée !${RESET}"