# git-tbd

Un outil CLI simple pour gérer un workflow Git en mode Trunk-Based Development.

## ✨ Fonctionnalités

- 📦 Crée automatiquement des branches `feature/xxx`
- ✅ Merge proprement dans `main` et supprime la branche
- 🔄 Rebase ta branche actuelle sur `main`
- 🧠 Aide intégrée

## 🚀 Installation

```bash
git clone https://github.com/nono-pxbsd/git-tbd.git
cd git-tbd
chmod +x bin/git-tbd
sudo ln -s $(pwd)/bin/git-tbd /usr/local/bin/git-tbd
```

## 🧪 Commandes disponibles

```bash
git-tbd start ma-fonctionnalite
# → Crée et bascule sur la branche feature/ma-fonctionnalite

git-tbd sync
# → Rebase la branche courante sur main

git-tbd finish
# → Merge la branche dans main, push, supprime la branche

git-tbd help
# → Affiche l'aide intégrée
```
