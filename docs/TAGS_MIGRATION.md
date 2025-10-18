# Migration des tags de version v0.x → v2.x

## 🎯 Contexte

Les tags initiaux (v0.1.0, v0.2.0) ne reflétaient pas l'ampleur des changements apportés.
La refonte complète méritait une version majeure v2.0.0.

## 📋 Actions effectuées

### 1. Suppression des anciens tags
```bash
# Localement
git tag -d v0.1.0 v0.2.0

# Sur origin
git push origin --delete v0.1.0 v0.2.0
```

### 2. Création des nouveaux tags

#### v2.0.0 - Refonte majeure (commit: 6fa4dd5)

Fonctionnalités majeures :
- Raccourcis commandes (s, f, v, p, b)
- Support GitLab complet
- Commande bump (versioning)
- Sélection interactive fzf
- Documentation complète

#### v2.1.0 - Gestion branches divergées (commit: bf1bc07)

Fonctionnalités :
- Flag --force intelligent
- Stratégies configurables
- Prompt interactif
- Documentation cas d'usage

## ✅ Vérification
```bash
# Lister les tags
git tag
# v2.0.0
# v2.1.0

# Version actuelle
git describe --tags
# v2.1.0

# Voir un tag spécifique
git show v2.0.0
git show v2.1.0
```

## 🔗 Releases GitHub

- [v2.0.0 - Refonte majeure](https://github.com/nono-pxbsd/git-tbd/releases/tag/v2.0.0)
- [v2.1.0 - Gestion branches divergées](https://github.com/nono-pxbsd/git-tbd/releases/tag/v2.1.0)

## 📅 Chronologie

| Version | Date | Description |
|---------|------|-------------|
| v0.1.0 | (supprimé) | Version initiale |
| v0.2.0 | (supprimé) | Ajout features |
| v2.0.0 | 2025-01-XX | Refonte majeure |
| v2.1.0 | 2025-01-XX | Gestion diverged |

## 🎓 Leçon apprise

Utiliser Semantic Versioning dès le début :
- Breaking changes / Refonte → MAJOR (v2.0.0)
- Nouvelles features → MINOR (v2.1.0)
- Bug fixes → PATCH (v2.1.1)