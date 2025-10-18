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
- 🔄 Rebase la branche actuelle sur `main`
- 🔀 Merge proprement dans `main` avec **local-squash** (évite la désynchronisation)
- 📦 Ouvre automatiquement une Pull Request / Merge Request
- 🏷️ Gestion des versions avec tags SemVer (`bump`)
- 🧭 Aide interactive intégrée
- 🦊 Support **GitHub** et **GitLab**

---

## ⚙️ Installation

### 📍 Méthode recommandée (clone + symlinks)

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

## 📇 Mode Silencieux

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

### Configuration manuelle

```bash
# Mode silencieux par défaut
echo 'export SILENT_MODE=true' >> ~/.zshrc  # ou ~/.bashrc
source ~/.zshrc

# OU créer un alias shell (si vous préférez)
echo "alias gittbds='SILENT_MODE=true gittbd'" >> ~/.zshrc
source ~/.zshrc

# OU utiliser la variable ponctuellement
SILENT_MODE=true gittbd finish
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

## 🎯 Cas d'usage : Configuration de `publish` pour branche divergée

Quand une branche a **divergé** d'origin (après `git commit --amend`, rebase local, ou push concurrent), `gittbd publish --force` doit choisir une stratégie. Voici comment configurer selon votre situation.

---

### 📊 Tableau récapitulatif

| Situation | Configuration recommandée | Comportement |
|-----------|---------------------------|--------------|
| **Travail solo** | `DEFAULT_DIVERGED_STRATEGY="force-push"` | Force push automatique (pas de prompt) |
| **Workflow TBD standard** | `DEFAULT_DIVERGED_STRATEGY="ask"` | Prompt interactif en local |
| **Collaboration sur branches** | `DEFAULT_DIVERGED_STRATEGY="ask"`<br>`SILENT_DIVERGED_FALLBACK="force-sync"` | Prompt en local, sync en CI/CD |
| **Très prudent** | `DEFAULT_DIVERGED_STRATEGY="force-sync"` | Toujours sync (jamais force push auto) |

---

### 🔧 Configuration dans `lib/config.sh`

```bash
# Stratégie par défaut : "ask" | "force-push" | "force-sync"
DEFAULT_DIVERGED_STRATEGY="ask"

# Fallback en mode silencieux (si strategy = "ask")
SILENT_DIVERGED_FALLBACK="force-push"
```

---

### 🎭 Cas d'usage détaillés

#### Cas 1 : Développeur solo / Branches personnelles

**Situation** : Vous travaillez seul sur vos branches feature. Personne d'autre ne push dessus.

**Pourquoi la branche diverge** : Après `git commit --amend`, rebase local, ou squash.

**Configuration recommandée** :
```bash
# lib/config.sh
DEFAULT_DIVERGED_STRATEGY="force-push"
```

**Comportement** :
```bash
# Après un amend
git commit --amend --no-edit

# Publish
gittbd publish --force
# ✅ Force push direct (pas de prompt)
# → Votre local est toujours la vérité
```

**Avantages** :
- ✅ Workflow rapide (pas de prompt inutile)
- ✅ Pas de risque (vous êtes seul sur la branche)

---

#### Cas 2 : Workflow Trunk-Based Development classique

**Situation** : Équipe utilisant TBD avec branches courtes durées (1-3 jours max). Chacun travaille sur SA branche.

**Pourquoi la branche diverge** : 
- 99% : `git commit --amend` ou squash local
- 1% : Erreur de manip (push depuis 2 machines)

**Configuration recommandée** :
```bash
# lib/config.sh
DEFAULT_DIVERGED_STRATEGY="ask"  # Prompt par défaut (sécurité)
SILENT_DIVERGED_FALLBACK="force-push"  # En CI/CD, assume amend
```

**Comportement** :
```bash
# En local (développement)
gittbd publish --force

# ⚠️ Branche divergée détectée
# 
# Quelle stratégie utiliser ?
# 
#   1. Force push (local écrase origin)
#      → Recommandé après amend/rebase/squash local
# 
#   2. Sync puis push (rebase origin dans local)
#      → Recommandé si quelqu'un a pushé pendant que vous travailliez
# 
# Choix [1/2] : 1
# ✅ Force push sélectionné

# En CI/CD (automatisation)
SILENT_MODE=true gittbd publish --force
# ✅ Force push automatique (pas de prompt)
```

**Avantages** :
- ✅ Sécurité : Prompt évite les erreurs
- ✅ Pédagogique : Messages expliquent les choix
- ✅ CI/CD compatible : Fallback automatique

---

#### Cas 3 : Collaboration sur les mêmes branches

**Situation** : Plusieurs développeurs peuvent push sur la même branche feature (pair programming, handoff).

**Pourquoi la branche diverge** :
- 50% : Push concurrent (collègue a pushé pendant que vous travailliez)
- 50% : Amend/rebase local

**Configuration recommandée** :
```bash
# lib/config.sh
DEFAULT_DIVERGED_STRATEGY="ask"
SILENT_DIVERGED_FALLBACK="force-sync"  # En CI/CD, préfère intégrer
```

**Comportement** :
```bash
# En local
gittbd publish --force

# ⚠️ Branche divergée détectée
# 
# Quelle stratégie utiliser ?
# 
#   1. Force push (local écrase origin)
#      → Recommandé après amend/rebase/squash local
# 
#   2. Sync puis push (rebase origin dans local)
#      → Recommandé si quelqu'un a pushé pendant que vous travailliez
# 
# Choix [1/2] : 2
# ✅ Sync puis push sélectionné
# → Intègre les changements du collègue

# En CI/CD
SILENT_MODE=true gittbd publish --force
# ✅ Sync automatique (intègre les changements distants)
```

**Avantages** :
- ✅ Évite d'écraser le travail des autres
- ✅ Prompt permet de choisir selon le contexte
- ✅ CI/CD intègre automatiquement

---

#### Cas 4 : Équipe très prudente (no force push)

**Situation** : Politique stricte "jamais de force push", toujours intégrer les changements distants.

**Configuration recommandée** :
```bash
# lib/config.sh
DEFAULT_DIVERGED_STRATEGY="force-sync"
```

**Comportement** :
```bash
gittbd publish --force
# ✅ Sync automatique (rebase)
# → Jamais de force push, toujours intégration
```

**Avantages** :
- ✅ Politique stricte appliquée automatiquement
- ✅ Pas de risque d'écrasement

**Inconvénient** :
- ⚠️ Si vous VOULEZ force push (après amend volontaire), utilisez explicitement :
  ```bash
  gittbd publish --force-push
  ```

---

### 🚦 Résumé des stratégies

#### `"ask"` (par défaut) - Sécurité maximale

**Quand** : Vous n'êtes pas sûr de la cause de la divergence.

**Comportement** :
- Mode normal : Prompt interactif
- Mode silencieux : Utilise `SILENT_DIVERGED_FALLBACK`

**Cas d'usage** : Workflow collaboratif, équipes mixtes

---

#### `"force-push"` - Workflow solo rapide

**Quand** : Vous travaillez seul, divergence = toujours amend/rebase local.

**Comportement** :
- Force push direct (pas de prompt)
- Assume que le local est toujours la vérité

**Cas d'usage** : Dev solo, branches perso, prototypes

---

#### `"force-sync"` - Politique prudente

**Quand** : Politique "toujours intégrer, jamais écraser".

**Comportement** :
- Sync (rebase) automatique
- Jamais de force push sans flag explicite

**Cas d'usage** : Équipes prudentes, collaboration intense

---

### 💡 Bypass du prompt (flags explicites)

**Même avec `strategy="ask"`, vous pouvez forcer explicitement** :

```bash
# Force push direct (pas de prompt)
gittbd publish --force-push

# Sync direct (pas de prompt)
gittbd publish --force-sync

# Le flag --force utilise la stratégie configurée
gittbd publish --force  # → Peut prompter si strategy="ask"
```

---

### 📋 Aide-mémoire

| Commande | Avec `strategy="ask"` | Avec `strategy="force-push"` | Avec `strategy="force-sync"` |
|----------|----------------------|------------------------------|------------------------------|
| `publish` | ❌ Erreur + suggestions | ❌ Erreur + suggestions | ❌ Erreur + suggestions |
| `publish --force` | 💬 Prompt (choix 1 ou 2) | ✅ Force push | ✅ Sync puis push |
| `publish --force-push` | ✅ Force push | ✅ Force push | ✅ Force push |
| `publish --force-sync` | ✅ Sync puis push | ✅ Sync puis push | ✅ Sync puis push |

---

### 🔍 Diagnostic : Pourquoi ma branche a divergé ?

```bash
# Voir les commits locaux uniquement
git log origin/ma-branch..HEAD --oneline

# Voir les commits distants uniquement
git log HEAD..origin/ma-branch --oneline

# Comparer visuellement
git log --graph --oneline --all
```

**Interprétation** :
- Si commits locaux = versions amendées des commits distants → `force-push`
- Si commits distants = nouveaux commits d'un collègue → `force-sync`

---

### 🎓 Bonne pratique

**Pour éviter les divergences** :
1. Toujours `git pull` avant de travailler
2. Évitez `git commit --amend` après avoir pushé (utilisez plutôt un nouveau commit)
3. Si vous devez amend/rebase après push : `gittbd publish --force-push`

**En cas de doute** : Gardez `strategy="ask"` et lisez les messages du prompt. 🎯

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
bash ~/.local/share/gittbd/bin/setup-silent-mode.sh
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
# 🔍 Validation de la MR sur branche : feature/test
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

Fichier : `~/.local/share/gittbd/lib/config.sh`

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

# Gestion des branches divergées
DEFAULT_DIVERGED_STRATEGY="ask"  # ask | force-push | force-sync
SILENT_DIVERGED_FALLBACK="force-push"
```

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