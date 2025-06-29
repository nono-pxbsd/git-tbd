# git-tbd

Un outil CLI simple pour gérer un workflow Git en mode **Trunk-Based Development (TBD)**.

---

## ✨ Fonctionnalités

- 🚀 Crée automatiquement des branches `feature/xxx`, `fix/xxx`, etc.
- 🔁 Rebase la branche actuelle sur `main`
- 🔀 Merge proprement dans `main` et supprime la branche
- 📦 Ouvre automatiquement une Pull Request avec `gh`
- 🧭 Aide interactive intégrée
- 🏷️ Gestion des versions (bientôt !)

---

## ⚙️ Installation

### 📦 Méthode recommandée (via `make`)

```bash
make install MODE=local     # Pour une installation locale (~/.local/bin)
make install MODE=global    # Pour une installation globale (/usr/local/bin)
```

- Ajoute automatiquement `~/.local/bin` au `$PATH` si besoin
- Installe le binaire `git-tbd`
- Vérifie que `git`, `bash/zsh` et `gh` sont disponibles (ou propose d’installer `gh`)

> 🛡️ Le mode global nécessite `sudo`.

---

## 🧪 Commandes disponibles

### 🟢 `git-tbd start`

Crée une nouvelle branche à partir de `main`.

```bash
git-tbd start feature login-form
# => feature/login-form
```

Types possibles : `feature`, `fix`, `hotfix`, `chore`, `test`, etc.

---

### 🔁 `git-tbd sync`

Rebase la branche actuelle sur `main`.

```bash
git-tbd sync
# => git fetch + git rebase origin/main
```

---

### 🔀 `git-tbd finish`

Merge la branche actuelle dans `main`, push et supprime la branche locale.

```bash
git-tbd finish
# => git checkout main + git merge + git push + git branch -d
```

---

### 📦 `git-tbd pr`

Ouvre automatiquement une Pull Request via GitHub CLI (`gh`).

```bash
git-tbd pr
# => gh pr create --base main --fill
```

---

### 🚀 `git-tbd publish`

Push la branche courante sur `origin`.

```bash
git-tbd publish
# => git push --set-upstream origin <current-branch>
```

---

### 🏷️ `git-tbd bump <type>`

_Bientôt disponible_  
Permettra de bump la version (`major`, `minor`, `patch`) et de taguer proprement.

---

### 🧭 `git-tbd help`

Affiche l’aide intégrée.

```bash
git-tbd help
```

---

## ❌ Désinstallation

```bash
make uninstall
```

Supprime les binaires installés (local et global).

---

## 🐧 Systèmes supportés

- ✅ Linux (testé sous Ubuntu / WSL)
- ❌ macOS / Windows : non testés, non supportés actuellement

---

## 📘 Aide / Contributions

Pull Requests et suggestions bienvenues !
