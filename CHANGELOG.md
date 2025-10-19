# Changelog

Tous les changements notables de ce projet seront documentés dans ce fichier.

Le format est basé sur [Keep a Changelog](https://keepachangelog.com/fr/1.0.0/),
et ce projet adhère à [Semantic Versioning](https://semver.org/lang/fr/).

---

## [Unreleased] v3.0.0

### 🎯 Refonte majeure : Squash au moment du merge

Date de release prévue : À déterminer

#### ⚠️ BREAKING CHANGES

##### 1. Workflow finish --pr modifié

**Avant (v2.x) :**
```bash
gittbd finish --pr
# → Squash local (3 commits → 1)
# → Force push
# → Création PR
```

**Maintenant (v3.0) :**
```bash
gittbd finish --pr
# → Push normal (pas de squash)
# → Création PR avec titre auto-généré
```

**Impact :** Les branches gardent leurs commits multiples jusqu'au merge final.

**Migration :** Aucune action requise, le workflow reste compatible.

---

##### 2. Workflow validate refactorisé

**Avant (v2.x) :**
```bash
gittbd validate feature/login
# → Appelle gh pr merge --squash
# → GitHub fait le merge
```

**Maintenant (v3.0) :**
```bash
gittbd validate feature/login
# → Squash merge LOCAL
# → Commit avec titre PR
# → Push vers main
# → Ferme la PR automatiquement
# → Nettoie les branches
```

**Impact :** Contrôle total sur le message de commit, pas de désynchronisation.

**Migration :** Aucune action requise, fonctionne mieux qu'avant.

---

##### 3. Variables de configuration renommées

| Ancienne variable (v2.x) | Nouvelle variable (v3.0) |
|--------------------------|--------------------------|
| `OPEN_PR` | `OPEN_REQUEST` |
| `REQUIRE_PR_ON_FINISH` | `REQUIRE_REQUEST_ON_FINISH` |

**Migration :** Éditer `~/.local/share/gittbd/lib/config.sh` et renommer.

---

##### 4. Valeur local-squash supprimée

**Variable :** `DEFAULT_MERGE_MODE`

**Avant (v2.x) :**
```bash
DEFAULT_MERGE_MODE="local-squash"  # ou "squash" ou "merge"
```

**Maintenant (v3.0) :**
```bash
DEFAULT_MERGE_MODE="squash"  # ou "merge"
# Note : "local-squash" n'existe plus
```

**Impact :** Si vous aviez `DEFAULT_MERGE_MODE="local-squash"`, changez pour `"squash"`.

**Migration :**
```bash
# Dans lib/config.sh
# Avant
DEFAULT_MERGE_MODE="local-squash"

# Après
DEFAULT_MERGE_MODE="squash"
```

---

#### ✨ Nouvelles fonctionnalités

##### Commande cleanup

Nouvelle commande pour nettoyer les branches après un merge via GitHub/GitLab.

```bash
# Nettoyage d'une branche spécifique
gittbd cleanup feature/login

# Auto-détection
gittbd cleanup

# Raccourcis
gittbd clean
gittbd c
```

**Utilité :** Après avoir cliqué sur "Squash and merge" dans GitHub, cette commande nettoie proprement la branche locale.

---

##### Titre de PR auto-généré

Lors de la création d'une PR, le titre est maintenant construit automatiquement depuis les commits :

- **1 seul commit :** Utilise son message
- **Plusieurs commits :** Prompt interactif ou utilise le premier commit
- **Ajout automatique :** `(PR #XX)` ou `(MR #XX)` selon la plateforme

**Exemple :**
```bash
git commit -m "feat: add login form"
git commit -m "feat: add validation"
gittbd finish --pr

# Titre PR généré : "✨ feat: add login form (PR #34)"
# Body PR : Liste des 2 commits
```

---

##### Body de PR avec liste des commits

Le body de la PR contient maintenant automatiquement la liste de tous les commits de la branche.

**Exemple :**
```
Titre : ✨ feat: add login form (PR #34)

Body :
- feat: add login form
- feat: add validation
- fix: typo in form
```

---

##### Terminologie unifiée (interne)

Les fonctions internes utilisent maintenant `request` au lieu de `pr`/`mr` :

| Ancien nom (v2.x) | Nouveau nom (v3.0) |
|-------------------|-------------------|
| `open_pr()` | `open_request()` |
| `validate_pr()` | `validate_request()` |
| `pr_exists()` | `request_exists()` |

**Impact utilisateur :** Aucun ! Les commandes CLI restent `gittbd pr` et `gittbd mr`.

---

##### Variable de configuration optionnelle

**Nouvelle variable :** `AUTO_CLEANUP_DETECTION`

```bash
# lib/config.sh
AUTO_CLEANUP_DETECTION=true
```

**Comportement :** Au lancement de gittbd, détecte automatiquement les branches locales qui ont été mergées sur GitHub/GitLab et propose de les nettoyer.

**Par défaut :** `false` (opt-in)

---

#### 🔧 Améliorations

##### Gestion des modifications après PR

**Problème résolu :** En v2.x, ajouter un commit après la création de la PR nécessitait un re-squash manuel.

**Solution v3.0 :**
```bash
gittbd finish --pr
# Review demande un changement
git commit -m "fix: after review"
git push
# ✅ Pas de problème, squash fait au merge final
```

---

##### Pas de désynchronisation après merge GitHub

**Problème résolu :** En v2.x, après un merge via GitHub, `git branch -d` échouait.

**Solution v3.0 :** Utiliser `gittbd cleanup` qui gère proprement la suppression.

---

##### Messages de commit plus clairs

Le message de commit final dans `main` contient maintenant :
- Le titre de la PR (avec le numéro)
- La liste complète des commits originaux dans le body

**Exemple :**
```
commit abc123

    ✨ feat: add login form (PR #34)
    
    - feat: add login form
    - feat: add validation
    - fix: typo in form
```

---

#### 🐛 Corrections

- **Fix :** Squash local avant PR causait des problèmes avec modifications après review  
  **Résolu :** Le squash est maintenant fait au moment du merge, pas avant.

- **Fix :** Désynchronisation après merge GitHub  
  **Résolu :** La commande cleanup gère proprement le cas.

---

#### 📚 Documentation

- **Ajout de docs/MIGRATION_v3.md**  
  Guide complet de migration v2 → v3 avec :
  - Explication des changements
  - Comparaison workflow avant/après
  - Migration pas à pas
  - FAQ complète

- **Mise à jour README.md**
  - Section sur la commande cleanup
  - Mise à jour du workflow recommandé
  - Clarification sur merge local vs GitHub

---

#### 🔄 Changements internes

##### Refactorisation de finish()
- Suppression du squash local avant PR
- Push normal (sans force)
- Garde le squash local pour les merges directs (sans PR)

##### Refactorisation de validate_request()
- Squash merge local au lieu de déléguer à GitHub
- Récupération du titre et body de la PR
- Fermeture automatique de la PR après merge
- Nettoyage automatique des branches

##### Refactorisation de open_request()
- Construction automatique du titre depuis les commits
- Génération du body avec liste des commits
- Ajout du numéro de PR/MR après création

##### Nouvelle fonction cleanup()
- Force delete de la branche locale
- Suppression de la branche distante
- Nettoyage des références Git
- Détection automatique optionnelle

---

#### 🎯 Migration v2 → v3

Voir le guide complet : [docs/MIGRATION_v3.md](docs/MIGRATION_v3.md)

**Actions requises :**
1. Mettre à jour : `cd ~/.local/share/gittbd && git pull`
2. Éditer `lib/config.sh` :
   - Renommer `OPEN_PR` → `OPEN_REQUEST`
   - Renommer `REQUIRE_PR_ON_FINISH` → `REQUIRE_REQUEST_ON_FINISH`
   - Si `DEFAULT_MERGE_MODE="local-squash"`, changer pour `"squash"`
3. Tester sur une branche test
4. Nettoyer les anciennes branches : `gittbd cleanup`

---

#### 🙏 Remerciements

Merci à tous les utilisateurs pour leurs retours qui ont permis d'identifier les problèmes résolus dans cette v3.0 !

---

## [2.2.2] - 2025-10-18

### 🛠️ Corrections

#### CI/CD - Configuration ShellCheck globale

- **Fix** : Ajout du fichier `.shellcheckrc` pour ignorer les warnings non pertinents
- **Problème** : Les annotations `# shellcheck source=` ne fonctionnaient pas en CI/CD car les chemins relatifs ne correspondaient pas
- **Solution** : Configuration globale via `.shellcheckrc`

**Configuration ajoutée** :
```bash
# .shellcheckrc
disable=SC1091  # Source dynamiques non suivis
disable=SC2034  # Variables de couleur définies mais "non utilisées"
```

**Résultat** :
- ✅ CI/CD passe au vert
- ✅ ShellCheck analyse le code sans faux positifs
- ✅ Configuration centralisée et maintenable

---

## [2.2.1] - 2025-10-18

### 🛠️ Corrections

#### CI/CD - ShellCheck annotations

- **Fix** : Ajout des annotations `# shellcheck source=` pour les fichiers lib
- **Problème** : ShellCheck ne pouvait pas suivre les `source` dynamiques (`${LIB_DIR}/...`)
- **Solution** : Annotations explicites pour chaque fichier sourcé

**Fichiers modifiés** :
```bash
# shellcheck source=lib/config.sh
source "${LIB_DIR}/config.sh"
# shellcheck source=lib/utils.sh
source "${LIB_DIR}/utils.sh"
# shellcheck source=lib/branches.sh
source "${LIB_DIR}/branches.sh"
# shellcheck source=lib/commands.sh
source "${LIB_DIR}/commands.sh"
```

**Résultat** :
- ✅ ShellCheck peut analyser le contenu des fichiers lib
- ✅ Détection des variables non définies
- ✅ Vérification des fonctions utilisées
- ✅ CI/CD passe au vert

---

### 🧹 Maintenance

- Nettoyage des fichiers de test temporaires
  - Suppression de `test.txt`, `test-finish-debug.txt`
  - Suppression des scripts `tests/debug_*.sh`
  - Conservation de `tests/test_prompts.sh` (vraie suite de tests)

---

## [2.2.0] - 2025-10-18

### ✨ Nouvelles fonctionnalités

#### Commande `gittbds` pour mode silencieux simplifié

Ajout d'une nouvelle commande **`gittbds`** (avec "s" pour silent) qui force automatiquement le mode silencieux.

**Avant** :
```bash
SILENT_MODE=true gittbd finish
```

**Maintenant** :
```bash
gittbds finish
```

**Avantages** :
- ✅ Plus simple et plus court
- ✅ Fonctionne partout (shell, scripts, CI/CD)
- ✅ Pas de configuration nécessaire
- ✅ Installé automatiquement avec `make install`

**Utilisation** :
```bash
# Mode normal (verbeux)
gittbd start feature/test

# Mode silencieux (minimal)
gittbds start feature/test
```

Le binaire `gittbds` est un wrapper léger qui exporte `SILENT_MODE=true` avant d'appeler `gittbd`.

---

### 🔧 Améliorations

#### Affichage du help amélioré

- **Version affichée** : La version (2.2.0) est maintenant visible dans `gittbd help`
- **Couleurs corrigées** : Tous les codes ANSI s'affichent correctement (utilisation de `echo -e`)
- **Chemin simplifié** : Affichage de `~/.local/share/gittbd/lib/config.sh` au lieu de `bin/../lib/config.sh`
- **Section Documentation** : Ajout de liens vers README, VERSIONING.md et TUTORIAL.md

#### Installation

- **Makefile** : Installation automatique de `gittbds` en plus de `gittbd`
- **Permissions** : Ajout de `chmod +x` pour `gittbds` lors de l'installation
- **Messages** : Affichage de la version silencieuse installée

---

### 🛠️ Corrections

#### Permissions exécutables

- **Fix** : Forcer Git à tracker la permission exécutable avec `git update-index --chmod=+x`
- **Problème** : Avec `core.fileMode=false`, les permissions n'étaient pas conservées
- **Solution** : Utilisation de `git update-index` pour forcer le bit exécutable dans l'index Git

---

### 📚 Documentation

#### README.md

Ajout d'une section complète sur le mode silencieux avec :
- Documentation de la commande `gittbds`
- Comparaison avec les anciennes méthodes
- Configuration avancée optionnelle
- Exemples d'utilisation

---

## [2.1.1] - 2025-10-18

### 📚 Documentation

#### Installation simplifiée avec workflow symlinks

Refonte complète de la section installation du README pour clarifier le workflow recommandé :

**Nouveau workflow** :
```bash
# Clone dans ~/.local/share/gittbd/ (avec .git/)
git clone https://github.com/nono-pxbsd/git-tbd.git ~/.local/share/gittbd

# Installation (crée des symlinks)
cd ~/.local/share/gittbd
make install MODE=local

# Mises à jour futures (pas besoin de réinstaller)
cd ~/.local/share/gittbd
git pull
```

**Avantages** :
- ✅ Mises à jour simplifiées via `git pull`
- ✅ Symlinks pointent toujours vers la dernière version
- ✅ Pas de réinstallation nécessaire après mise à jour
- ✅ Le repo contient `.git/` pour les futures mises à jour

**Documentation ajoutée** :
- Section "Mettre à jour gittbd" dans README.md
- Clarification du chemin de configuration : `~/.local/share/gittbd/lib/config.sh`
- Explication des avantages du workflow avec symlinks

### 🔧 Améliorations

- **Makefile** : Utilise déjà `ln -sf` (symlinks) au lieu de copier les fichiers
- **README.md** : 97 lignes ajoutées pour clarifier l'installation et les mises à jour
- **Setup silencieux** : Chemin corrigé pour pointer vers `~/.local/share/gittbd/bin/setup-silent-mode.sh`

---

## [2.1.0] - 2025-01-XX

### ✨ Nouvelles fonctionnalités

#### `publish` avec gestion intelligente des branches divergées

Ajout d'un système complet pour gérer les branches qui ont divergé d'origin (après `git commit --amend`, rebase local, ou push concurrent).

**Nouvelle configuration dans `lib/config.sh`** :
```bash
# Stratégie par défaut : "ask" | "force-push" | "force-sync"
DEFAULT_DIVERGED_STRATEGY="ask"

# Fallback en mode silencieux
SILENT_DIVERGED_FALLBACK="force-push"
```

**Nouveau flag** :
- `gittbd publish --force` : Détection intelligente selon l'état de la branche
  - `ahead` → Push normal
  - `behind` → Sync automatique
  - `diverged` → Selon `DEFAULT_DIVERGED_STRATEGY`

**Comportements selon la configuration** :

| Configuration | Comportement sur diverged |
|---------------|--------------------------|
| `strategy="ask"` (défaut) | Prompt interactif (sauf mode silencieux) |
| `strategy="force-push"` | Force push automatique |
| `strategy="force-sync"` | Sync (rebase) automatique |

**Prompt interactif** (avec `strategy="ask"`) :
```
⚠️ Branche divergée détectée

Quelle stratégie utiliser ?

  1. Force push (local écrase origin)
     → Recommandé après amend/rebase/squash local

  2. Sync puis push (rebase origin dans local)
     → Recommandé si quelqu'un a pushé pendant que vous travailliez

Choix [1/2] : _
```

**Mode silencieux** :
- Si `strategy="ask"` → Utilise automatiquement `SILENT_DIVERGED_FALLBACK`
- Pas de prompt bloquant en CI/CD

**Documentation** :
- Ajout d'une section complète dans README.md avec cas d'usage
- 4 profils d'équipe documentés (solo, TBD standard, collaboratif, prudent)

---

### 🔧 Améliorations

#### Messages d'erreur enrichis

Quand une branche a divergé sans flag `--force` :
```bash
❌ La branche 'feature/test' a divergé d'origin/feature/test

💡 Options :

  • gittbd publish --force           : Résolution automatique
  • gittbd publish --force-sync      : Force le rebase
  • gittbd publish --force-push      : Force le push (destructif)

📝 Cas typique : après git commit --amend ou rebase
   → Utilisez --force ou --force-push
```

#### Flags explicites prioritaires

Les flags `--force-push` et `--force-sync` bypass toujours le prompt, quelle que soit la configuration.

```bash
# Toujours force push (pas de prompt)
gittbd publish --force-push

# Toujours sync (pas de prompt)
gittbd publish --force-sync
```

---

### 📚 Documentation

- **README.md** : Section "Cas d'usage" avec 4 profils d'équipe
- **README.md** : Tableau récapitulatif des stratégies
- **README.md** : Guide de diagnostic "Pourquoi ma branche a divergé ?"
- **config.sh** : Commentaires enrichis sur les stratégies

---

### 🎯 Migration

**Rétrocompatibilité** : ✅ Totale

- Les commandes existantes fonctionnent sans changement
- `DEFAULT_DIVERGED_STRATEGY="ask"` par défaut (comportement sûr)
- Pour retrouver l'ancien comportement "force tout" : `DEFAULT_DIVERGED_STRATEGY="force-push"`

**Action recommandée** :
1. Lisez la section "Cas d'usage" dans README.md
2. Choisissez la configuration adaptée à votre workflow
3. Ajustez `lib/config.sh` si nécessaire

---

### 🛠️ Corrections

- Résout le problème de `gittbd publish` qui échouait après `git commit --amend`
- Messages d'erreur plus clairs et actionnables sur branche divergée

---

### 📝 Détails techniques

**Fichiers modifiés** :
- `lib/config.sh` : Ajout de 2 variables
- `lib/commands.sh` : Refonte de `publish()`
- `README.md` : Nouvelle section cas d'usage

**Tests manuels validés** :
- ✅ Branche synced → Push normal
- ✅ Branche ahead → Push normal
- ✅ Branche behind → Sync automatique avec `--force`
- ✅ Branche diverged + `strategy="ask"` → Prompt
- ✅ Branche diverged + `strategy="force-push"` → Force push
- ✅ Branche diverged + `strategy="force-sync"` → Sync
- ✅ Mode silencieux → Utilise fallback
- ✅ Flags explicites → Bypass prompt

---

## [2.0.0] - 2025-01-XX

### 🎉 Version majeure avec refonte complète

### ✨ Ajouts

#### Fonctionnalités
- **Raccourcis de commandes** : `s` (start), `f` (finish), `v` (validate), `p` (publish), `b` (bump)
- **Support GitLab complet** : Fonctionne avec GitHub ET GitLab
- **Alias MR** : `gittbd mr` comme alias de `gittbd pr` pour GitLab
- **Commande bump** : Gestion complète des versions avec tags SemVer (major/minor/patch)
- **Sélection interactive améliorée** : Support de `fzf` avec fallback vers menu classique
- **3 modes de création de branche** :
  - Mode complet : `gittbd start feature/name`
  - Mode semi-interactif : `gittbd start name` (fzf pour le type)
  - Mode full interactif : `gittbd start` (fzf + prompt nom)
- **Émojis configurables** : Variable `USE_EMOJI_IN_COMMIT_TITLE` dans config
- **Terminologie adaptative** : Messages utilisent "PR" (GitHub) ou "MR" (GitLab) automatiquement

#### Infrastructure
- **Système de logs structuré** : `log_info()`, `log_error()`, `log_warn()`, `log_success()`, `log_debug()`
- **Wrapper Git sécurisé** : `git_safe()` pour éviter les race conditions
- **Abstraction plateforme** : `git_platform_cmd()` pour supporter GitHub/GitLab
- **Helper terminologie** : `get_platform_term()` pour PR/MR adaptatif
- **Mode silencieux amélioré** : Contrôle fin de la verbosité
- **Mode debug** : `DEBUG_MODE=true` pour tracer l'exécution

#### Documentation
- **README.md complet** : Guide d'utilisation avec exemples
- **VERSIONING.md** : Guide pédagogique sur les tags Git et SemVer
- **TUTORIAL.md** : Tutorial pas-à-pas d'un projet complet
- **MIGRATION.md** : Guide de migration v1 → v2
- **Section mode silencieux** : Documentation des fonctions impactées

#### Tests
- **Suite de tests** : `tests/test_prompts.sh` pour non-régression
- **Tests de validation** : Vérification des fonctions utilitaires
- **Tests d'intégration** : Workflow complet testable

---

### 🔧 Améliorations

#### Performance et fiabilité
- **Prompts sécurisés** : Utilisation de `< /dev/tty` pour éviter les blocages
- **Attente explicite Git** : Fin des race conditions entre Git et prompts
- **Gestion d'erreurs robuste** : Validation à chaque étape critique
- **Encoding UTF-8** : Correction des caractères corrompus

#### Expérience utilisateur
- **Messages clairs** : Émojis contextuels et suggestions d'action
- **Feedback progressif** : Indication de progression pour les opérations longues
- **Aide contextuelle** : Suggestions automatiques en cas d'erreur
- **Workflow guidé** : Questions interactives pour guider l'utilisateur

#### Code
- **Refactorisation complète** : `validate_pr()` en 8 phases clairement séparées
- **Découpage fonctionnel** : Responsabilités mieux séparées
- **Code réutilisable** : Fonctions atomiques et composables
- **Commentaires améliorés** : Documentation inline claire

---

### 🛠️ Corrections

- **Messages dupliqués** : Suppression des logs redondants
- **Prompts bloquants** : Résolution des deadlocks d'affichage
- **Race conditions** : Git et prompts ne s'entremêlent plus
- **Synchronisation** : Gestion correcte des états ahead/behind/diverged
- **Squash GitHub** : Message d'avertissement sur la désynchronisation
- **Validation de branche** : Vérifications plus strictes
- **Gestion des erreurs** : Moins de crashs silencieux

---

### 🗑️ Suppressions

- Aucune fonctionnalité supprimée (rétrocompatible)
- Code mort nettoyé
- Commentaires obsolètes retirés

---

### ⚠️ Breaking Changes

Aucun ! La v2.0 est **rétrocompatible** avec v1.x :
- `git-tbd` reste disponible comme alias
- Toutes les commandes v1 fonctionnent encore
- Configuration v1 compatible (nouvelles options ajoutées)

---

## [1.0.0] - 2024-XX-XX

### 🎉 Version initiale

#### Fonctionnalités
- Commande `start` : Création de branches
- Commande `finish` : Merge dans main
- Commande `publish` : Publication sur origin
- Commande `pr` : Création de Pull Request (GitHub uniquement)
- Commande `validate` : Validation de PR
- Commande `sync` : Synchronisation avec main
- Support du local-squash
- Configuration via `config.sh`
- Installation via Makefile

#### Infrastructure
- Support Linux/WSL
- Dépendances : git, gh, bash/zsh
- Installation locale ou globale

---

## Contributeurs

### v3.0.0
- **nono.pxbsd** : Refonte squash workflow, commande cleanup, terminologie unifiée

### v2.2.2
- **nono.pxbsd** : Fix CI/CD ShellCheck annotations, nettoyage fichiers de test

### v2.2.1
- **nono.pxbsd** : Fix CI/CD ShellCheck config globale

### v2.2.0
- **nono.pxbsd** : Commande gittbds, amélioration help, fix permissions

### v2.1.1
- **nono.pxbsd** : Simplification installation avec workflow symlinks, documentation

### v2.1.0
- **nono.pxbsd** : Gestion intelligente branches divergées, documentation cas d'usage

### v2.0.0
- **nono.pxbsd** : Refonte complète, support GitLab, documentation

### v1.0.0
- **nono.pxbsd** : Création initiale

---

## Remerciements

Merci à tous les contributeurs et utilisateurs qui ont rendu ce projet possible !

Inspirations et références :
- [Trunk Based Development](https://trunkbaseddevelopment.com/)
- [Semantic Versioning](https://semver.org/)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [GitHub CLI](https://cli.github.com/)
- [GitLab CLI](https://gitlab.com/gitlab-org/cli)

---

**Légende des statuts** :
- ✅ Implémenté
- 🔄 En cours
- 📅 Planifié
- ❌ Non implémenté
- ⚠️ Limité/partiel