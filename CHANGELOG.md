# Changelog

Tous les changements notables de ce projet seront documentés dans ce fichier.

Le format est basé sur [Keep a Changelog](https://keepachangelog.com/fr/1.0.0/),
et ce projet adhère à [Semantic Versioning](https://semver.org/lang/fr/).

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

### 📋 Commits inclus

- Merge PR #28 : Simplification installation et upgrade ([7c1137c](https://github.com/nono-pxbsd/git-tbd/commit/7c1137c))
- Merge PR #27 : Configuration installation séparée ([588d32f](https://github.com/nono-pxbsd/git-tbd/commit/588d32f))
- Fix : Installation séparée du répertoire de développement ([61e2950](https://github.com/nono-pxbsd/git-tbd/commit/61e2950))
- Merge PR #26 : Correction tags de version ([284621e](https://github.com/nono-pxbsd/git-tbd/commit/284621e))
- Docs : Migration tags v0.x → v2.x ([71fa99a](https://github.com/nono-pxbsd/git-tbd/commit/71fa99a))
- Merge PR #25 : Correction tags de version ([978afe2](https://github.com/nono-pxbsd/git-tbd/commit/978afe2))
- Merge PR #23 : Amélioration message force push ([ed27180](https://github.com/nono-pxbsd/git-tbd/commit/ed27180))

### 🎯 Migration

**Aucune action requise** pour les utilisateurs existants.

Si vous avez déjà installé gittbd via l'ancienne méthode et souhaitez profiter du nouveau workflow :

```bash
# 1. Désinstaller l'ancienne version
make uninstall

# 2. Supprimer l'ancien répertoire (si existant)
rm -rf ~/.local/share/gittbd

# 3. Réinstaller avec le nouveau workflow
git clone https://github.com/nono-pxbsd/git-tbd.git ~/.local/share/gittbd
cd ~/.local/share/gittbd
make install MODE=local
source ~/.zshrc  # ou ~/.bashrc
```

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

🔍 Cas typique : après git commit --amend ou rebase
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

### 🔍 Détails techniques

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

### 🛠️ Corrections

- **Messages dupliqués** : Suppression des logs redondants
- **Prompts bloquants** : Résolution des deadlocks d'affichage
- **Race conditions** : Git et prompts ne s'entremêlent plus
- **Synchronisation** : Gestion correcte des états ahead/behind/diverged
- **Squash GitHub** : Message d'avertissement sur la désynchronisation
- **Validation de branche** : Vérifications plus strictes
- **Gestion des erreurs** : Moins de crashs silencieux

### 🗑️ Suppressions

- Aucune fonctionnalité supprimée (rétrocompatible)
- Code mort nettoyé
- Commentaires obsolètes retirés

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