BINARY_NAME = gittbd
BINARY_SILENT = gittbds

# Chemins source (repo de développement)
BIN_SOURCE = $(CURDIR)/bin/$(BINARY_NAME)
BIN_SILENT_SOURCE = $(CURDIR)/bin/$(BINARY_SILENT)
LIB_SOURCE = $(CURDIR)/lib

# Chemins d'installation
INSTALL_DIR_LOCAL = $(HOME)/.local/share/gittbd
INSTALL_DIR_GLOBAL = /usr/local/share/gittbd

INSTALL_BIN_LOCAL = $(HOME)/.local/bin
INSTALL_BIN_GLOBAL = /usr/local/bin

MODE ?= local

# Vérifie que le système est Linux
check-system:
	@uname | grep -qi linux || { echo "❌ Ce script ne fonctionne que sur Linux / WSL."; exit 1; }

# Vérifie les dépendances nécessaires (git, bash/zsh, gh ou glab, fzf)
check-deps: check-system
	@echo "🔍 Vérification des dépendances système..."
	@command -v git >/dev/null 2>&1 || { echo "❌ git est requis. Installez-le via 'sudo apt install git'."; exit 1; }
	@command -v bash >/dev/null 2>&1 || command -v zsh >/dev/null 2>&1 || \
		{ echo "❌ bash ou zsh est requis. Installez-en un via 'sudo apt install bash'."; exit 1; }
	@if ! command -v fzf >/dev/null 2>&1; then \
		echo "⚠️  fzf est FORTEMENT recommandé pour une expérience optimale."; \
		echo "   Sans fzf, l'interface sera fonctionnelle mais moins pratique."; \
		echo ""; \
		read -p "Voulez-vous installer fzf maintenant ? [O/n] " choix; \
		if [ "$$choix" = "O" ] || [ "$$choix" = "o" ] || [ -z "$$choix" ]; then \
			sudo apt update && sudo apt install -y fzf || echo "❌ Échec de l'installation de fzf."; \
		else \
			echo "⭐️  Installation skippée. Un menu classique sera utilisé."; \
		fi \
	else \
		echo "✅ fzf trouvé."; \
	fi
	@if ! command -v gh >/dev/null 2>&1 && ! command -v glab >/dev/null 2>&1; then \
		echo "⚠️  GitHub CLI (gh) ou GitLab CLI (glab) est manquant."; \
		echo "   Pour GitHub : sudo apt install gh"; \
		echo "   Pour GitLab : voir https://gitlab.com/gitlab-org/cli"; \
		read -p "Voulez-vous installer gh (GitHub CLI) ? [O/n] " choix; \
		if [ "$$choix" = "O" ] || [ "$$choix" = "o" ] || [ -z "$$choix" ]; then \
			sudo apt update && sudo apt install -y gh || echo "❌ Échec de l'installation de gh."; \
		else \
			echo "⭐️  Installation skippée. Certaines fonctions seront indisponibles."; \
		fi \
	else \
		if command -v gh >/dev/null 2>&1; then \
			echo "✅ gh (GitHub) trouvé."; \
		fi; \
		if command -v glab >/dev/null 2>&1; then \
			echo "✅ glab (GitLab) trouvé."; \
		fi; \
	fi

# Installation du binaire localement ou globalement
install: check-deps
	@if [ ! -f "$(BIN_SOURCE)" ]; then \
		echo "❌ Binaire introuvable à $(BIN_SOURCE)"; exit 1; \
	fi
	@if [ ! -f "$(BIN_SILENT_SOURCE)" ]; then \
		echo "❌ Binaire silencieux introuvable à $(BIN_SILENT_SOURCE)"; exit 1; \
	fi
	@chmod +x $(BIN_SOURCE)
	@chmod +x $(BIN_SILENT_SOURCE)
	@if [ "$(MODE)" = "local" ]; then \
		echo "📦 Installation en mode local"; \
		mkdir -p $(INSTALL_BIN_LOCAL); \
		ln -sf $(BIN_SOURCE) $(INSTALL_BIN_LOCAL)/$(BINARY_NAME); \
		ln -sf $(BIN_SILENT_SOURCE) $(INSTALL_BIN_LOCAL)/$(BINARY_SILENT); \
		ln -sf $(BIN_SOURCE) $(INSTALL_BIN_LOCAL)/git-tbd; \
		if [ -n "$$ZSH_VERSION" ]; then shellrc="$$HOME/.zshrc"; \
		elif [ -n "$$BASH_VERSION" ]; then shellrc="$$HOME/.bashrc"; \
		else shellrc="$$HOME/.profile"; fi; \
		if ! grep -q 'export PATH.*$(HOME)/.local/bin' $$shellrc 2>/dev/null; then \
			echo 'export PATH="$(HOME)/.local/bin:$$PATH"' >> $$shellrc; \
			echo "✅ PATH local ajouté à $$shellrc"; \
		else \
			echo "ℹ️  PATH local déjà présent dans $$shellrc"; \
		fi; \
		echo "✅ Installé localement : $(INSTALL_BIN_LOCAL)/$(BINARY_NAME)"; \
		echo "🔇 Version silencieuse : $(INSTALL_BIN_LOCAL)/$(BINARY_SILENT)"; \
		echo "🔗 Alias de compatibilité : $(INSTALL_BIN_LOCAL)/git-tbd"; \
		echo ""; \
		echo "💡 Pour configurer le mode silencieux :"; \
		echo "   bash bin/setup-silent-mode.sh"; \
	else \
		echo "🛠️  Installation en mode global"; \
		sudo ln -sf $(BIN_SOURCE) $(INSTALL_BIN_GLOBAL)/$(BINARY_NAME); \
		sudo ln -sf $(BIN_SILENT_SOURCE) $(INSTALL_BIN_GLOBAL)/$(BINARY_SILENT); \
		sudo ln -sf $(BIN_SOURCE) $(INSTALL_BIN_GLOBAL)/git-tbd; \
		echo "✅ Installé globalement : $(INSTALL_BIN_GLOBAL)/$(BINARY_NAME)"; \
		echo "🔇 Version silencieuse : $(INSTALL_BIN_GLOBAL)/$(BINARY_SILENT)"; \
		echo "🔗 Alias de compatibilité : $(INSTALL_BIN_GLOBAL)/git-tbd"; \
		echo ""; \
		echo "💡 Pour configurer le mode silencieux :"; \
		echo "   bash bin/setup-silent-mode.sh"; \
	fi

# Désinstallation
uninstall:
	@rm -f $(INSTALL_BIN_LOCAL)/$(BINARY_NAME) $(INSTALL_BIN_LOCAL)/$(BINARY_SILENT) $(INSTALL_BIN_LOCAL)/git-tbd
	@sudo rm -f $(INSTALL_BIN_GLOBAL)/$(BINARY_NAME) $(INSTALL_BIN_GLOBAL)/$(BINARY_SILENT) $(INSTALL_BIN_GLOBAL)/git-tbd 2>/dev/null || true
	@echo "✅ Symlinks supprimés"

# Publication d'un tag Git
release:
	@read -p "Version (ex: v2.2.0) : " v; \
	git tag $$v -m "Release $$v" && git push origin $$v && echo "✅ Tag $$v publié !"

# Tests (optionnel)
test:
	@echo "🧪 Lancement des tests..."
	@if [ -d "tests" ]; then \
		for test in tests/*.sh; do \
			bash $$test || exit 1; \
		done; \
		echo "✅ Tous les tests passent"; \
	else \
		echo "⚠️  Aucun test trouvé dans ./tests"; \
	fi

.PHONY: check-system check-deps install uninstall release test