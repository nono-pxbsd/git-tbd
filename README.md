# gittbd

Un outil CLI simple et puissant pour gérer un workflow Git en mode **Trunk-Based Development (TBD)**.

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

- 🚀 Crée automatiquement des branches `feature/xxx`, `fix/xxx`, etc.
- 🎯 Sélection interactive du type de branche avec `fzf` (ou menu classique)
- 📝 Rebase la branche actuelle sur `main`
- 🔀 Merge proprement dans `main` avec **local-squash** (évite la désynchronisation)
- 📦 Ouvre automatiquement une Pull Request / Merge Request
- 🏷️ Gestion des versions avec tags SemVer (`bump`)
- 🧭 Aide interactive intégrée
- 🦊 Support **GitHub** et **GitLab**

---

## ⚙️ Installation

### 📦 Méthode recommandée (via `make`)

```bash
# Cloner le projet
git clone https://github.com/votre-user/gittbd.git
cd gittbd

# Installation locale (recommandé)
make install MODE=local

# OU installation globale (nécessite sudo)
make install MODE=global

# Recharger le shell
source ~/.zshrc  # ou ~/.bashrc
```

**Ce qui est installé** :
- ✅ Vérifie automatiquement les dépendances (git, gh/glab, fzf)
- ✅ Installe le binaire `gittbd`
- ✅ Crée un alias `git-tbd` pour rétrocompatibilité
- ✅ Ajoute `~/.local/bin` au `$PATH` si nécessaire

---

## 🔇 Mode Silencieux

Pour réduire la verbosité, exécutez après l'installation :

```bash
bash bin/setup-silent-mode.sh
```

Le script détectera automatiquement votre environnement (shell, système) et vous proposera plusieurs options :

1. **Mode silencieux par défaut** : `gittbd` sera toujours silencieux
2. **Alias `gittbds`** : Garde `gittbd` verbeux, crée `gittbds` silencieux
3. **Les deux** : Maximum de flexibilité

### Configuration manuelle (optionnel)

Si vous préférez configurer manuellement :

```bash
# Mode silencieux par défaut
echo 'export SILENT_MODE=true' >> ~/.zshrc  # ou ~/.bashrc
source ~/.zshrc

# OU créer un alias
echo "alias gittbds='SILENT_MODE=true gittbd'" >> ~/.zshrc
source ~/.zshrc
```

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

Merge la branche actuelle dans `main`, push et supprime la branche.

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
- `--method=<mode>` : Force une méthode (squash/merge/local-squash)

---

### 🚀 `gittbd publish` (alias: `p`)

Push la branche courante sur `origin`.

```bash
gittbd publish

# Avec force (après local-squash)
gittbd publish --force-push

# Raccourci
gittbd p
```

---

### 📦 `gittbd pr` / `gittbd mr`

Ouvre automatiquement une Pull Request (GitHub) ou Merge Request (GitLab).

```bash
# Sur GitHub
gittbd pr

# Sur GitLab (plus naturel)
gittbd mr

# Les deux fonctionnent partout
```

---

### ✅ `gittbd validate` (alias: `v`, `merge`)

Valide une Pull Request / Merge Request.

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

## 📇 Mode Silencieux détaillé

Réduit la verbosité en n'affichant que les erreurs et succès finaux.

### Activation

```bash
# Temporaire (une commande)
SILENT_MODE=true gittbd finish

# Permanent (session)
export SILENT_MODE=true

# Permanent (shell) - voir section installation ci-dessus
bash bin/setup-silent-mode.sh
```

### Fonctions impactées

| Commande | Comportement normal | Mode silencieux |
|----------|---------------------|-----------------|
| `start` | Affiche les étapes (checkout, pull, création) | Erreurs + succès final uniquement |
| `finish` | Demande confirmation, affiche le squash | Pas de confirmation (avec --silent), minimal |
| `publish` | Affiche synchro, vérifications | Erreurs uniquement |
| `validate` | Affiche PR/MR, demande confirmation | Pas de confirmation (avec --yes) |
| `bump` | Affiche changelog, demande confirmation | Erreurs uniquement (avec --yes) |

### Messages toujours affichés

Même en mode silencieux :
- ❌ **Erreurs** : Toujours visibles
- ✅ **Succès finaux** : Message de confirmation

### Combinaisons utiles

```bash
# CI/CD : Tout automatique, silencieux
SILENT_MODE=true gittbd finish --pr --yes

# Debug + Silencieux : Juste les erreurs + logs debug
DEBUG_MODE=true SILENT_MODE=true gittbd validate
```

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
# 📝 Validation de la MR sur branche : feature/test
# ✅ MR trouvée
```

### Différences GitHub vs GitLab

| Aspect | GitHub | GitLab |
|--------|--------|--------|
| CLI | `gh` | `glab` |
| Terminologie | Pull Request (PR) | Merge Request (MR) |
| Commandes | `gittbd pr` | `gittbd mr` |
| **local-squash** | ✅ Fonctionne | ✅ Fonctionne |

**Note** : Le **local-squash** est indépendant de la plateforme (Git local), il fonctionne partout ! 🎉

---

## 🎯 Workflow quotidien recommandé

```bash
# 1. Créer une branche (mode interactif)
gittbd s
# → Choisir le type avec fzf
# → Entrer le nom

# 2. Développer
git add .
git commit -m "feat: description"

# 3. Publier + créer PR/MR
gittbd f --pr

# 4. Après review, valider
gittbd v

# 5. Quand prêt pour release
git checkout main
gittbd bump minor
```

---

## 📚 Documentation avancée

- [VERSIONING.md](docs/VERSIONING.md) - Guide complet du versioning avec tags
- [TUTORIAL.md](docs/TUTORIAL.md) - Tutorial pas-à-pas d'un projet complet

---

## 🛠️ Configuration

Fichier : `lib/config.sh`

```bash
# Branche principale
DEFAULT_BASE_BRANCH="main"

# Mode de merge par défaut
DEFAULT_MERGE_MODE="local-squash"  # squash | merge | local-squash

# Plateforme
GIT_PLATFORM="github"  # github | gitlab

# Émojis dans les commits
USE_EMOJI_IN_COMMIT_TITLE=true  # true | false

# Exiger une PR/MR pour finish
REQUIRE_PR_ON_FINISH=true
```

---

## 🧭 Systèmes supportés

- ✅ **Linux** (testé sous Ubuntu / Debian / WSL)
- ⚠️ **macOS** : Non testé, devrait fonctionner
- ❌ **Windows** : Utiliser WSL

---

## ❌ Désinstallation

```bash
make uninstall
```

Supprime les binaires installés (local et global).

---

## 🎓 Pourquoi Trunk-Based Development ?

Le TBD est un workflow Git qui privilégie :

1. ✅ **Une seule branche principale** (`main`)
2. ✅ **Branches courtes durées** (quelques heures/jours max)
3. ✅ **Intégration continue** (merge fréquent)
4. ✅ **Historique propre** (squash recommandé)
5. ✅ **Code review obligatoire** (PR/MR)

**Idéal pour** :
- Équipes agiles avec sprints courts
- Déploiement continu (prod à chaque merge)
- Petites/moyennes équipes (2-10 devs)
- Projets avec releases fréquentes

**gittbd** automatise ce workflow et force les bonnes pratiques ! 🚀

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