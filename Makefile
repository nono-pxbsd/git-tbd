# Makefile - pour git-tbd

install:
	chmod +x bin/git-tbd
	sudo ln -sf $(PWD)/bin/git-tbd /usr/local/bin/git-tbd
	@echo "✅ Installé comme commande globale : git-tbd"

release:
	@read -p "Version (ex: v0.1.1) : " v; \
	git tag $$v -m "Release $$v" && git push origin $$v && echo "✅ Tag $$v publié !"

uninstall:
	sudo rm -f /usr/local/bin/git-tbd
	@echo "❌ Supprimé : git-tbd"
