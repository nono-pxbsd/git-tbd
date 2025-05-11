BINARY_NAME = git-tbd
BIN_SOURCE = $(CURDIR)/bin/$(BINARY_NAME)
INSTALL_GLOBAL = /usr/local/bin/$(BINARY_NAME)
INSTALL_LOCAL = $(HOME)/.local/bin/$(BINARY_NAME)
MODE ?= global

install:
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
		if ! grep -q 'export PATH="$${HOME}/.local/bin' $$shellrc 2>/dev/null; then \
			echo 'export PATH="$$HOME/.local/bin:$$PATH"' >> $$shellrc; \
			echo "✅ PATH local ajouté à $$shellrc"; \
		else \
			echo "ℹ️  PATH local déjà présent dans $$shellrc"; \
		fi; \
		echo "✅ Installé localement : $(INSTALL_LOCAL)"; \
	else \
		echo "🛠️ Installation en mode global (/usr/local/bin)"; \
		sudo ln -sf $(BIN_SOURCE) $(INSTALL_GLOBAL); \
		echo "✅ Installé globalement : $(INSTALL_GLOBAL)"; \
	fi

uninstall:
	@rm -f $(INSTALL_GLOBAL) $(INSTALL_LOCAL)
	@echo "❌ Commande supprimée (globale + locale)"

release:
	@read -p "Version (ex: v0.1.1) : " v; \
	git tag $$v -m "Release $$v" && git push origin $$v && echo "✅ Tag $$v publié !"
