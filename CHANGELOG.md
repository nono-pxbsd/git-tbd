# Changelog

Tous les changements notables de ce projet seront documentés dans ce fichier.

Le format est basé sur [Keep a Changelog](https://keepachangelog.com/fr/1.0.0/),
et ce projet adhère à [Semantic Versioning](https://semver.org/lang/fr/).

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
- **Émojis configurables** : Variable `USE_EMOJI_IN_COMMIT_TITLE` pour activer/désactiver
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

### 🐛 Corrections

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

### 📦 Migration

Voir [MIGRATION.md](MIGRATION.md) pour le guide complet.

**Étapes résumées** :
1. Backup de l'ancienne version
2. Téléchargement des nouveaux fichiers
3. Désinstallation de v1
4. Installation de v2
5. Tests de validation

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

## [Unreleased]

### 🔮 Prévu pour les prochaines versions

#### v2.1.0 (minor)
- [ ] Commande `gittbd config` pour éditer la config interactivement
- [ ] Hooks pre-commit automatiques
- [ ] Template de message de commit personnalisable
- [ ] Support de Gitea/Forgejo

#### v2.2.0 (minor)
- [ ] Commande `gittbd status` : Vue d'ensemble du repo
- [ ] Commande `gittbd list` : Liste des branches en cours
- [ ] Intégration avec `gh` pour review automatique
- [ ] Statistiques de workflow (temps moyen, nombre de branches, etc.)

#### v2.3.0 (minor)
- [ ] Support de feature flags
- [ ] Intégration CI/CD (templates GitHub Actions / GitLab CI)
- [ ] Génération automatique de CHANGELOG.md
- [ ] Export de métriques pour dashboards

#### v3.0.0 (major)
- [ ] Refonte en Rust pour meilleures performances
- [ ] Support Windows natif (sans WSL)
- [ ] Interface TUI (Terminal User Interface)
- [ ] Plugin VSCode / JetBrains

---

## Historique des versions

### Légende des symboles

- ✨ Nouvelle fonctionnalité
- 🔧 Amélioration
- 🐛 Correction de bug
- 🗑️ Suppression
- ⚠️ Breaking change
- 📚 Documentation
- 🧪 Tests

---

## Comparaison des versions

| Fonctionnalité | v1.0 | v2.0 |
|----------------|------|------|
| **Plateformes** |
| GitHub | ✅ | ✅ |
| GitLab | ❌ | ✅ |
| **Commandes** |
| start | ✅ | ✅ (+ fzf) |
| finish | ✅ | ✅ (+ amélioré) |
| publish | ✅ | ✅ |
| pr | ✅ | ✅ (+ alias mr) |
| validate | ✅ | ✅ (+ phases claires) |
| sync | ✅ | ✅ |
| bump | ❌ | ✅ (nouveau) |
| **Raccourcis** |
| Alias courts | ❌ | ✅ (s, f, v, p, b) |
| **UX** |
| fzf | ❌ | ✅ |
| Mode silencieux | ⚠️ Basique | ✅ Complet |
| Messages adaptés | ❌ | ✅ (PR/MR) |
| Suggestions | ⚠️ Limité | ✅ Contextuel |
| **Fiabilité** |
| Race conditions | ❌ | ✅ Corrigé |
| Prompts bloquants | ❌ | ✅ Corrigé |
| Gestion d'erreurs | ⚠️ Basique | ✅ Robuste |
| **Documentation** |
| README | ⚠️ Basique | ✅ Complet |
| Guides | ❌ | ✅ (3 guides) |
| Tests | ❌ | ✅ |

---

## Notes de migration

### De v1.0 à v2.0

**Compatibilité** : ✅ Rétrocompatible à 100%

**Action requise** : Aucune, mais recommandé :
1. Mettre à jour les scripts utilisant `git-tbd` → `gittbd`
2. Configurer `GIT_PLATFORM` si vous utilisez GitLab
3. Tester le mode silencieux pour CI/CD
4. Profiter des raccourcis (`s`, `f`, etc.)

**Nouvelles variables de config** :
```bash
USE_EMOJI_IN_COMMIT_TITLE=true  # Nouveau
GIT_PLATFORM="github"           # Nouveau
```

---

## Roadmap

### Court terme (3 mois)
- ✅ v2.0.0 : Refonte complète + support GitLab
- 🔄 v2.1.0 : Configuration interactive + hooks
- 📅 v2.2.0 : Statistiques + dashboard

### Moyen terme (6-12 mois)
- 📅 v2.3.0 : Feature flags + CI/CD templates
- 📅 v2.4.0 : Multi-repo support
- 📅 v2.5.0 : Plugins system

### Long terme (12+ mois)
- 📅 v3.0.0 : Réécriture en Rust
- 📅 v3.1.0 : Support Windows natif
- 📅 v3.2.0 : Interface graphique (TUI)

---

## Contributeurs

### v2.0.0
- **nono.pxbsd** : Refonte complète, support GitLab, documentation

### v1.0.0
- **nono.pxbsd** : Création initiale

---

## Feedback et contributions

Nous encourageons les contributions ! Voici comment aider :

### Signaler un bug
1. Vérifier que le bug n'existe pas déjà dans les issues
2. Ouvrir une issue avec :
   - Version de gittbd (`gittbd help`)
   - Système d'exploitation
   - Commande exécutée
   - Erreur rencontrée
   - Logs en mode debug (`DEBUG_MODE=true gittbd ...`)

### Proposer une fonctionnalité
1. Ouvrir une issue "Feature Request"
2. Décrire le cas d'usage
3. Proposer une implémentation si possible

### Contribuer du code
1. Fork le projet
2. Créer une branche : `gittbd start feature/ma-feature`
3. Coder avec les conventions du projet
4. Ajouter des tests si applicable
5. Documenter dans le README si nécessaire
6. Ouvrir une PR : `gittbd pr`

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
