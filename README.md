# gittbd

Un outil CLI simple et puissant pour gérer un workflow Git en mode **Trunk-Based Development (TBD)**.

**Version :** 3.0.0 🎉

---

## 📦 Prérequis

### Obligatoires

- **Git** : Gestion de versions
  ```bash
  sudo apt install git  # Ubuntu/Debian/WSL
  ```

- **Bash ou Zsh** : Shell Unix (généralement déjà installé)

- **GitHub CLI** (`gh`) **OU** **GitLab CLI** (`glab`) : Gestion des PR/MR
  ```bash
  # Pour GitHub
  sudo apt install gh
  gh auth login
  
  # Pour GitLab
  # Voir https://gitlab.com/gitlab-org/cli
  glab auth login
  ```

### Fortement recommandés

#### 🔍 fzf - Fuzzy Finder

**fzf** améliore considérablement l'expérience utilisateur avec des menus interactifs modernes.

**Installation** :

```bash
# Ubuntu / Debian / WSL
sudo apt update && sudo apt install -y fzf

# macOS
brew install fzf

# Arch Linux
sudo pacman -S fzf

# Fedora
sudo dnf install fzf
```

**Sans fzf** : Un menu classique numéroté sera utilisé (fonctionnel mais moins pratique).

---

## ✨ Fonctionnalités

### 🆕 Nouveautés v3.0.0

- 🎯 **Squash au bon moment** : Plus de squash avant la PR, uniquement au merge
- 🧹 **Commande cleanup** : Nettoyage propre après merge GitHub/GitLab
- 📝 **Titre PR auto-généré** : Construit depuis vos commits
- 🔄 **Modifications après PR** : Ajoutez des commits sans re-squash
- 🏷️ **Terminologie unifiée** : `request` en interne, `pr`/`mr` pour vous

### Fonctionnalités principales

- 🚀 Crée automatiquement des branches `feature/xxx`, `fix/xxx`, etc.
- 🎯 Sélection interactive du type de branche avec `fzf` (ou menu classique)
- 🔄 Rebase la branche actuelle sur `main`
- 🔀 Merge proprement dans `main` avec squash au moment du merge
- 📦 Ouvre automatiquement une Pull Request / Merge Request
- 🧹 Nettoie les branches après merge GitHub/GitLab
- 🏷️ Gestion des versions avec tags SemVer (`bump`)
- 🧭 Aide interactive intégrée
- 🦊 Support **GitHub** et **GitLab**

---

## ⚙️ Installation

### 🔍 Méthode recommandée (clone + symlinks)

Cette méthode permet de **mettre à jour facilement** via `git pull` sans réinstaller.

```bash
# 1. Cloner le repo dans ~/.local/share/gittbd/ (AVEC .git/)
git clone https://github.com/nono-pxbsd/git-tbd.git ~/.local/share/gittbd

# 2. Installer (crée des symlinks vers le repo)
cd ~/.local/share/gittbd
make install MODE=local

# 3. Recharger le shell
source ~/.zshrc  # ou ~/.bashrc
```

**Ce qui est installé** :
- ✅ Vérifie automatiquement les dépendances (git, gh/glab, fzf)
- ✅ Crée des **symlinks** dans `~/.local/bin/` vers le repo cloné
- ✅ Crée un alias `git-tbd` pour rétrocompatibilité
- ✅ Ajoute `~/.local/bin` au `$PATH` si nécessaire

**Avantages de cette méthode** :
- 🔄 **Mises à jour faciles** : `cd ~/.local/share/gittbd && git pull`
- 🔗 Les symlinks pointent toujours vers la dernière version
- 📦 Pas besoin de réinstaller après chaque mise à jour
- 🎯 Le repo contient `.git/` pour les futures mises à jour

---

### 🔄 Mettre à jour gittbd

Une fois installé via la méthode recommandée :

```bash
# Se placer dans le répertoire d'installation
cd ~/.local/share/gittbd

# Récupérer les dernières modifications
git pull

# C'est tout ! Les symlinks pointent vers les nouveaux fichiers
# Pas besoin de make install à nouveau
```

**Vérifier la version installée** :
```bash
gittbd help
# Affiche la version et les commandes disponibles
```

---

### 🛠️ Installation globale (optionnel)

Pour une installation système (accessible par tous les utilisateurs) :

```bash
cd ~/.local/share/gittbd
sudo make install MODE=global
```

Les binaires seront installés dans `/usr/local/bin/`.

---

### 🗑️ Désinstallation

```bash
cd ~/.local/share/gittbd
make uninstall

# Pour supprimer complètement le repo
rm -rf ~/.local/share/gittbd
```

---

## 🔇 Mode Silencieux

### 🔇 Commande `gittbds` (recommandé)

Depuis l'installation, vous disposez automatiquement de la commande **`gittbds`** (avec "s" pour silent) :

```bash
# Mode normal (verbeux)
gittbd finish

# Mode silencieux (minimal)
gittbds finish
```

**Avantages** :
- ✅ Pas de configuration nécessaire
- ✅ Fonctionne partout (shell, scripts, CI/CD)
- ✅ Plus simple que `SILENT_MODE=true gittbd ...`

### Configuration avancée (optionnel)

Si vous préférez que `gittbd` soit silencieux **par défaut** :

```bash
# Exécuter le script de configuration
bash ~/.local/share/gittbd/bin/setup-silent-mode.sh
```

Le script vous proposera plusieurs options :

1. **Mode silencieux par défaut** : `gittbd` sera toujours silencieux
2. **Alias `gittbds`** : Garde `gittbd` verbeux, crée un alias shell `gittbds`
3. **Les deux** : Maximum de flexibilité

---

## 🧪 Commandes disponibles

### 🟢 `gittbd start` (alias: `s`)

Crée une nouvelle branche à partir de `main`.

```bash
# Mode complet (type/nom)
gittbd start feature/login-form

# Mode semi-interactif (seulement le nom)
gittbd start login-form
# → fzf s'ouvre pour choisir le type

# Mode full interactif
gittbd start
# → fzf pour le type
# → Demande du nom

# Raccourci
gittbd s
```

**Types disponibles** : `feature`, `fix`, `hotfix`, `chore`, `doc`, `test`, `refactor`, `release`

---

### 🔀 `gittbd finish` (alias: `f`)

Finalise la branche actuelle.

**🆕 v3.0 : Ne squashe plus avant la PR !**

```bash
# Finish simple (local)
gittbd finish

# Finish avec création de PR/MR
gittbd finish --pr

# Mode silencieux
SILENT_MODE=true gittbd finish

# Raccourci
gittbd f --pr
```

**Options** :
- `--pr` / `-p` : Ouvre une PR/MR automatiquement
- `--silent` / `-s` : Mode silencieux
- `--method=<mode>` : Force une méthode (squash/merge)

**Ce qui change en v3 :**
```bash
# v2.x : Squash local avant PR
gittbd finish --pr
# → 3 commits → 1 commit (squash)
# → Force push
# → PR créée

# v3.0 : Push normal, squash au merge
gittbd finish --pr
# → 3 commits restent inchangés
# → Push normal
# → PR créée avec titre auto-généré
```

---

### 🚀 `gittbd publish` (alias: `p`)

Push la branche courante sur `origin`.

```bash
# Publication normale
gittbd publish

# Avec force (mode intelligent)
gittbd publish --force

# Force uniquement le push (après squash local)
gittbd publish --force-push

# Force uniquement la sync (branche en retard)
gittbd publish --force-sync

# Raccourci
gittbd p
```

**Options** :
- `--force` / `-f` : Détection intelligente (selon l'état de la branche)
- `--force-push` : Force push avec `--force-with-lease` (sécurisé)
- `--force-sync` : Force sync (rebase) puis push

---

### 📦 `gittbd pr` / `gittbd mr`

Ouvre automatiquement une Pull Request (GitHub) ou Merge Request (GitLab).

**🆕 v3.0 : Titre auto-généré depuis les commits !**

```bash
# Sur GitHub
gittbd pr

# Sur GitLab (plus naturel)
gittbd mr

# Les deux fonctionnent partout
```

**Nouveautés v3 :**
- ✅ Titre construit depuis vos commits
- ✅ Body avec liste complète des commits
- ✅ Numéro ajouté automatiquement : `(PR #34)` ou `(MR #XX)`

**Exemple :**
```bash
git commit -m "feat: add login form"
git commit -m "feat: add validation"
gittbd pr

# Titre PR : "✨ feat: add login form (PR #34)"
# Body PR :
# - feat: add login form
# - feat: add validation
```

---

### ✅ `gittbd validate` (alias: `v`, `merge`)

Valide une Pull Request / Merge Request.

**🆕 v3.0 : Squash merge LOCAL !**

```bash
# Validation interactive
gittbd validate

# Validation avec la branche spécifiée
gittbd validate feature/login-form

# Mode automatique (CI/CD)
gittbd validate --assume-yes

# Raccourcis
gittbd v
gittbd merge
```

**Ce qui change en v3 :**
```bash
# v2.x : Délègue à GitHub
gittbd validate
# → Appelle gh pr merge --squash
# → GitHub fait le squash

# v3.0 : Squash LOCAL
gittbd validate
# → Récupère titre et commits de la PR
# → git merge --squash (local)
# → Commit avec titre PR + liste commits
# → Push vers main
# → Ferme la PR
# → Nettoie les branches
```

**Avantages v3 :**
- ✅ Contrôle total sur le message de commit
- ✅ Pas de désynchronisation
- ✅ Nettoyage automatique des branches

---

### 🧹 `gittbd cleanup` (alias: `clean`, `c`) 🆕

**NOUVEAU en v3.0 !**

Nettoie une branche après un merge via GitHub/GitLab.

```bash
# Nettoyage d'une branche spécifique
gittbd cleanup feature/login

# Auto-détection
gittbd cleanup

# Raccourcis
gittbd clean
gittbd c
```

**Utilité :**

Si vous avez cliqué sur **"Squash and merge"** dans GitHub au lieu d'utiliser `gittbd validate`, utilisez `cleanup` pour nettoyer proprement :

```bash
# Workflow avec merge GitHub
gittbd finish --pr
# [Clic sur "Squash and merge" dans GitHub]
gittbd cleanup feature/login
# ✅ Nettoyage propre (pas d'erreur "not fully merged")
```

**Actions effectuées :**
- ✅ Mise à jour de main
- ✅ Suppression branche locale (force delete)
- ✅ Suppression branche distante (si existe)
- ✅ Nettoyage références Git (`git remote prune`)

---

### 🔄 `gittbd sync`

Met à jour la branche courante depuis `main`.

```bash
gittbd sync

# Avec force (en cas de retard)
gittbd sync --force
```

---

### 🏷️ `gittbd bump` (alias: `b`)

Crée un tag de version selon Semantic Versioning.

```bash
# Correction de bug (1.0.0 → 1.0.1)
gittbd bump patch

# Nouvelle fonctionnalité (1.0.0 → 1.1.0)
gittbd bump minor

# Breaking change (1.0.0 → 2.0.0)
gittbd bump major

# Mode automatique (CI/CD)
gittbd bump patch --yes

# Raccourci
gittbd b patch
```

---

## 🎯 Workflow quotidien recommandé

### Workflow A : Via gittbd (recommandé)

```bash
# 1. Créer une branche (mode interactif)
gittbd s
# → Choisir le type avec fzf
# → Entrer le nom

# 2. Développer
git add .
git commit -m "feat: description"
git commit -m "fix: correction"

# 3. Publier + créer PR/MR
gittbd f --pr

# 4. Après review, valider
gittbd v

# ✅ Résultat :
# - Commit squashé dans main avec titre PR
# - Branches nettoyées automatiquement
```

### Workflow B : Merge via GitHub

```bash
# 1-3. Pareil que Workflow A
gittbd s
# ... commits ...
gittbd f --pr

# 4. Merger via le bouton GitHub
# [Clic sur "Squash and merge"]

# 5. Nettoyer
gittbd cleanup feature/ma-branche

# ✅ Résultat :
# - Commit squashé dans main
# - Nettoyage propre (pas d'erreur)
```

---

## 🆕 Changements v3.0

### Ce qui a changé

| Aspect | v2.x | v3.0 |
|--------|------|------|
| **finish --pr** | Squash local avant PR | Pas de squash, push normal |
| **validate** | Délègue à GitHub | Squash merge local |
| **Cleanup** | Manuel (`git branch -D`) | `gittbd cleanup` |
| **Modifs après PR** | 💩 Re-squash nécessaire | ✅ Ajout de commits sans problème |

### Pourquoi v3 ?

**Problème v2 résolu :**
```bash
# v2.x
gittbd finish --pr  # Squash 3 commits → 1
# Review demande une modif
git commit -m "fix: after review"
# 💩 Historique hybride (1 squashé + 1 nouveau)

# v3.0
gittbd finish --pr  # 3 commits inchangés
# Review demande une modif
git commit -m "fix: after review"
# ✅ 4 commits propres, squash au validate
```

**Migration v2 → v3 :**
Voir [docs/MIGRATION_v3.md](docs/MIGRATION_v3.md)

---

## 🦊 Support GitLab

`gittbd` fonctionne parfaitement avec GitLab !

### Configuration

```bash
# Installer GitLab CLI
curl -s https://gitlab.com/gitlab-org/cli/-/releases/permalink/latest/downloads/glab_amd64.deb -o glab.deb
sudo dpkg -i glab.deb

# Authentification
glab auth login

# Configurer la plateforme
export GIT_PLATFORM=gitlab
echo 'export GIT_PLATFORM=gitlab' >> ~/.zshrc

# OU dans lib/config.sh
GIT_PLATFORM="gitlab"
```

### Utilisation

```bash
# Les commandes s'adaptent automatiquement
gittbd mr feature/test      # Crée une Merge Request
gittbd validate feature/test  # Valide la MR

# Les messages utilisent "MR" au lieu de "PR"
# 🔍 Validation de la MR sur branche : feature/test
# ✅ MR trouvée
```

### Différences GitHub vs GitLab

| Aspect | GitHub | GitLab |
|--------|--------|--------|
| CLI | `gh` | `glab` |
| Terminologie | Pull Request (PR) | Merge Request (MR) |
| Commandes | `gittbd pr` | `gittbd mr` |
| **Workflow v3** | ✅ Fonctionne | ✅ Fonctionne |

---

## 🛠️ Configuration

Fichier : `~/.local/share/gittbd/lib/config.sh`

```bash
# Branche principale
DEFAULT_BASE_BRANCH="main"

# Mode de merge par défaut
DEFAULT_MERGE_MODE="squash"  # squash | merge

# Plateforme
GIT_PLATFORM="github"  # github | gitlab

# Émojis dans les commits
USE_EMOJI_IN_COMMIT_TITLE=true  # true | false

# Exiger une Request (PR/MR) pour finish
REQUIRE_REQUEST_ON_FINISH=true

# Gestion des branches divergées
DEFAULT_DIVERGED_STRATEGY="ask"  # ask | force-push | force-sync
SILENT_DIVERGED_FALLBACK="force-push"

# Auto-détection cleanup (optionnel)
AUTO_CLEANUP_DETECTION=false
```

**Nouveautés v3 :**
- `OPEN_REQUEST` (anciennement `OPEN_PR`)
- `REQUIRE_REQUEST_ON_FINISH` (anciennement `REQUIRE_PR_ON_FINISH`)
- `AUTO_CLEANUP_DETECTION` (nouveau)

---

## 🧭 Systèmes supportés

- ✅ **Linux** (testé sous Ubuntu / Debian / WSL)
- ⚠️ **macOS** : Non testé, devrait fonctionner
- ❌ **Windows** : Utiliser WSL

---

## 🎓 Pourquoi Trunk-Based Development ?

Le TBD est un workflow Git qui privilégie :

1. ✅ **Une seule branche principale** (`main`)
2. ✅ **Branches courtes durées** (quelques heures/jours max)
3. ✅ **Intégration continue** (merge fréquent)
4. ✅ **Historique propre** (squash au merge)
5. ✅ **Code review obligatoire** (PR/MR)

**Idéal pour** :
- Équipes agiles avec sprints courts
- Déploiement continu (prod à chaque merge)
- Petites/moyennes équipes (2-10 devs)
- Projets avec releases fréquentes

**gittbd v3** automatise ce workflow et force les bonnes pratiques ! 🚀

---

## 📚 Documentation avancée

- [MIGRATION_v3.md](docs/MIGRATION_v3.md) - Guide de migration v2 → v3
- [VERSIONING.md](docs/VERSIONING.md) - Guide complet du versioning avec tags
- [TUTORIAL.md](docs/TUTORIAL.md) - Tutorial pas-à-pas d'un projet complet

---

## 🤝 Contributions

Pull Requests et suggestions bienvenues !

1. Fork le projet
2. Créer une branche : `gittbd start feature/ma-feature`
3. Commit : `git commit -m "feat: description"`
4. Push : `gittbd publish`
5. Ouvrir une PR : `gittbd pr`

---

## 📄 Licence

MIT - Voir [LICENSE](LICENSE)

---

## 🙏 Crédits

Créé par **nono.pxbsd**

Inspiré par les pratiques Trunk-Based Development et les workflows modernes de développement.

---

## 🔗 Liens utiles

- **GitHub** : https://github.com/nono-pxbsd/git-tbd
- **Issues** : https://github.com/nono-pxbsd/git-tbd/issues
- **Releases** : https://github.com/nono-pxbsd/git-tbd/releases