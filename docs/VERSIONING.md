# 📦 Guide du Versioning avec gittbd

## 🎯 Qu'est-ce qu'un tag Git ?

Un **tag** est un marqueur permanent sur un commit spécifique, utilisé pour identifier les versions de votre projet.

```
main: A -> B -> C -> D -> E (v1.0.0)
                           ↑
                      Version stable
```

---

## 🔢 Semantic Versioning (SemVer)

Format : `MAJOR.MINOR.PATCH`

```
v2.3.5
│ │ │
│ │ └─ PATCH (5) : Corrections de bugs
│ └─── MINOR (3) : Nouvelles fonctionnalités
└───── MAJOR (2) : Changements cassants
```

### Quand utiliser quel type ?

| Type | Quand ? | Exemple |
|------|---------|---------|
| **PATCH** | Bug fix, optimisation | Fix du crash au démarrage |
| **MINOR** | Nouvelle feature (compatible) | Ajout commande `bump` |
| **MAJOR** | Breaking change | Refonte complète de l'API |

---

## 🚀 Utilisation avec gittbd

### Créer votre première version

```bash
# Vous venez de finir votre MVP
git checkout main
gittbd bump minor

# 🔍 Version actuelle : v0.0.0
# 📦 Nouvelle version : v0.1.0
# 
# Changements depuis v0.0.0 :
# - feature: ajout commande start (abc1234)
# - feature: ajout commande finish (def5678)
# - fix: correction bug publish (ghi9012)
# 
# ✅ Créer le tag v0.1.0 ? [y/N] y
# 
# 🏷️  Tag v0.1.0 créé
# 📤 Push du tag vers origin
# ✅ Version v0.1.0 publiée !
```

### Workflow typique

```bash
# 1. Développement de features
gittbd start feature/new-ui
# ... commits ...
gittbd finish

gittbd start feature/api-integration
# ... commits ...
gittbd finish

# 2. Bump MINOR (nouvelles features)
gittbd bump minor
# v0.1.0 → v0.2.0

# 3. Un bug critique est découvert
gittbd start hotfix/critical-bug
# ... commits ...
gittbd finish

# 4. Bump PATCH (correction)
gittbd bump patch
# v0.2.0 → v0.2.1

# 5. Refonte complète de l'architecture
gittbd start feature/refactor-core
# ... commits cassants ...
gittbd finish

# 6. Bump MAJOR (breaking change)
gittbd bump major
# v0.2.1 → v1.0.0
```

---

## 📊 Exemples de progression

### Cas 1 : Projet en développement
```
v0.1.0  → MVP initial
v0.1.1  → Fix bugs
v0.2.0  → Ajout authentification
v0.2.1  → Fix sécurité
v0.3.0  → Ajout API REST
v1.0.0  → Release stable publique
```

### Cas 2 : Projet mature
```
v2.5.0  → Version courante
v2.5.1  → Patch de sécurité
v2.5.2  → Optimisations
v2.6.0  → Nouvelle feature dashboard
v3.0.0  → Migration vers nouvelle architecture
```

---

## 🔧 Options avancées

### Mode automatique (CI/CD)
```bash
# Pas de confirmation
gittbd bump patch --yes

# Créer le tag mais ne pas pusher
gittbd bump minor --no-push
# (utile pour tester localement)
```

### Voir l'historique des versions
```bash
# Lister tous les tags
git tag
# v0.1.0
# v0.2.0
# v1.0.0

# Voir les détails d'un tag
git show v1.0.0

# Comparer deux versions
git log v0.2.0..v1.0.0 --oneline
```

---

## 🌐 Intégration GitHub/GitLab

### Sur GitHub

Quand vous pushez un tag, GitHub crée automatiquement une **Release** :

1. Allez sur `https://github.com/user/repo/releases`
2. Vous verrez votre version `v1.0.0`
3. GitHub génère un changelog automatique
4. Vous pouvez télécharger le code à cette version

#### Créer une release manuellement
```bash
# Via GitHub CLI
gh release create v1.0.0 --generate-notes
```

### Sur GitLab

Pareil, mais avec GitLab CI :

```yaml
# .gitlab-ci.yml
release:
  stage: deploy
  only:
    - tags
  script:
    - echo "Deploying $CI_COMMIT_TAG"
    - ./deploy.sh
```

---

## 🎓 Bonnes pratiques

### ✅ À faire

1. **Toujours bumper depuis `main`**
   ```bash
   git checkout main
   git pull
   gittbd bump patch
   ```

2. **Un tag = un état stable**
   - Ne jamais taguer du code non testé
   - Toujours merger les PR avant de bump

3. **Respecter SemVer strictement**
   - MAJOR = breaking change (toujours)
   - MINOR = feature (backward compatible)
   - PATCH = fix uniquement

4. **Documenter les breaking changes**
   ```bash
   # Dans votre CHANGELOG.md
   ## v2.0.0 - Breaking Changes
   - ❌ Removed deprecated `old_function()`
   - ⚠️  API endpoints now use `/v2/` prefix
   ```

### ❌ À éviter

1. **Ne pas modifier un tag existant**
   ```bash
   # ❌ Mauvais
   git tag -d v1.0.0
   git tag v1.0.0
   
   # ✅ Bon
   gittbd bump patch  # Crée v1.0.1 à la place
   ```

2. **Ne pas bumper sans commits**
   ```bash
   # Si rien n'a changé, pas besoin de tag
   ```

3. **Ne pas skipper de versions**
   ```bash
   # ❌ Mauvais : v1.0.0 → v1.2.0
   # ✅ Bon     : v1.0.0 → v1.1.0 → v1.2.0
   ```

---

## 🐛 Dépannage

### "Aucun tag trouvé"

```bash
# Première utilisation, pas encore de tag
gittbd bump minor
# Crée automatiquement v0.1.0
```

### "Le tag existe déjà"

```bash
# Quelqu'un a déjà créé ce tag
git tag
# v1.0.0  ← Existe déjà

# Solution : bump à nouveau
gittbd bump patch  # Crée v1.0.1
```

### "Rollback sur une ancienne version"

```bash
# Revenir temporairement à v1.0.0
git checkout v1.0.0

# Créer une branche de maintenance
git checkout -b maintenance/v1.0
```

---

## 📚 Ressources

- [Semantic Versioning](https://semver.org/)
- [Git Tagging](https://git-scm.com/book/en/v2/Git-Basics-Tagging)
- [GitHub Releases](https://docs.github.com/en/repositories/releasing-projects-on-github)
- [GitLab Releases](https://docs.gitlab.com/ee/user/project/releases/)

---

## 💡 Astuces

### Générer un CHANGELOG automatique

```bash
# Entre deux versions
git log v1.0.0..v2.0.0 --pretty=format:"- %s (%h)" > CHANGELOG_v2.md
```

### Automatiser avec un hook

```bash
# .git/hooks/pre-push
#!/bin/bash
if [[ $(git describe --tags 2>/dev/null) ]]; then
  echo "✅ Version : $(git describe --tags)"
fi
```

### Version dans votre code

```bash
# Dans votre README.md ou --version
VERSION=$(git describe --tags --always)
echo "gittbd version $VERSION"
```
