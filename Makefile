BINARY_NAME = git-tbd
BIN_SOURCE = $(CURDIR)/bin/$(BINARY_NAME)
INSTALL_GLOBAL = /usr/local/bin/$(BINARY_NAME)
INSTALL_LOCAL = $(HOME)/.local/bin/$(BINARY_NAME)
MODE ?= global

# Vérifie que le système est Linux
check-system:
	@uname | grep -qi linux || { echo "❌ Ce script ne fonctionne que sur Linux / WSL."; exit 1; }

# Vérifie les dépendances nécessaires (git, bash/zsh, gh)
check-deps: check-system
	@echo "🔍 Vérification des dépendances système..."
	@command -v git >/dev/null 2>&1 || { echo "❌ git est requis. Installez-le via 'sudo apt install git'."; exit 1; }
	@command -v bash >/dev/null 2>&1 || command -v zsh >/dev/null 2>&1 || \
		{ echo "❌ bash ou zsh est requis. Installez-en un via 'sudo apt install bash'."; exit 1; }
	@if ! command -v gh >/dev/null 2>&1; then \
		echo "⚠️  GitHub CLI (gh) est manquant. Voulez-vous l’installer ? [O/n]"; \
		read choix; \
		if [ "$$choix" = "O" ] || [ "$$choix" = "o" ] || [ -z "$$choix" ]; then \
			sudo apt update && sudo apt install -y gh || echo "❌ Échec de l'installation de gh."; \
		else \
			echo "⏭️  Skipping gh install. Certaines fonctions seront indisponibles."; \
		fi \
	else \
		echo "✅ gh trouvé."; \
	fi

# Installation du binaire localement ou globalement
install: check-deps
	@if [ ! -f "$(BIN_SOURCE)" ]; then \
		echo "❌ Binaire introuvable à $(BIN_SOURCE)"; exit 1; \
	fi
	chmod +x $(BIN_SOURCE)
	@if [ "$(MODE)" = "local" ]; then \
		echo "📦 Installation en mode local (~/.local/bin)"; \
		mkdir -p $(HOME)/.local/bin; \
		ln -sf $(BIN_SOURCE) $(INSTALL_LOCAL); \
		if [ -n "$$ZSH_VERSION" ]; then shellrc="~/.zshrc"; \
		elif [ -n "$$BASH_VERSION" ]; then shellrc="~/.bashrc"; \
		else shellrc="~/.profile"; fi; \
		if ! grep -q 'export PATH.*$(HOME)/.local/bin' $$shellrc 2>/dev/null; then \
			echo 'export PATH="$(HOME)/.local/bin:$$PATH"' >> $$shellrc; \
			echo "✅ PATH local ajouté à $$shellrc"; \
		else \
			echo "ℹ️  PATH local déjà présent dans $$shellrc"; \
		fi; \
		echo "✅ Installé localement : $(INSTALL_LOCAL)"; \
	else \
		echo "🛠️  Installation en mode global (/usr/local/bin)"; \
		sudo ln -sf $(BIN_SOURCE) $(INSTALL_GLOBAL); \
		echo "✅ Installé globalement : $(INSTALL_GLOBAL)"; \
	fi

# Désinstallation
uninstall:
	@rm -f $(INSTALL_GLOBAL) $(INSTALL_LOCAL)
	@echo "❌ Commande supprimée (globale + locale)"

# Publication d'un tag Git
release:
	@read -p "Version (ex: v0.1.1) : " v; \
	git tag $$v -m "Release $$v" && git push origin $$v && echo "✅ Tag $$v publié !"
