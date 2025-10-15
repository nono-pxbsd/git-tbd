# 🎓 Tutorial complet : De zéro à une release

Ce guide vous montre un workflow complet avec `gittbd`, du premier commit à la première release publique.

---

## 📦 Scénario : Créer une application TODO

### Étape 0 : Installation

```bash
cd ~/projets
git clone https://github.com/votre-user/gittbd.git
cd gittbd
make install MODE=local
source ~/.zshrc
```

---

### Étape 1 : Initialiser le projet

```bash
# Créer un nouveau projet
mkdir mon-app-todo
cd mon-app-todo
git init
git remote add origin git@github.com:user/mon-app-todo.git

# Premier commit
echo "# Mon App TODO" > README.md
git add README.md
git commit -m "Initial commit"
git push -u origin main
```

---

### Étape 2 : Développer des features

#### Feature 1 : Ajouter des tâches

```bash
# Créer une branche (mode interactif)
gittbd start
# 🎯 Mode interactif activé
# [fzf ouvre avec les types]
# → Sélectionner "feature"
# 📝 Nom de la branche : add-task
# ✅ Création de ✨ feature/add-task

# Développer
echo "function addTask() { ... }" > app.js
git add app.js
git commit -m "feat: ajout fonction addTask"

echo "button Add Task" > index.html
git add index.html
git commit -m "feat: UI pour ajouter tâche"

# Publier et créer une PR
gittbd finish --pr
# 🧹 Squash local en cours...
# ✅ Squash réussi
# 📤 Publication...
# 🔧 Création de la PR...
# ✅ PR créée : https://github.com/user/mon-app-todo/pull/1

# Valider la PR (après review)
gittbd validate feature/add-task
# ✅ PR validée et mergée
```

#### Feature 2 : Supprimer des tâches

```bash
# Mode court (type/nom directement)
gittbd start feature/delete-task

echo "function deleteTask() { ... }" >> app.js
git add app.js
git commit -m "feat: ajout fonction deleteTask"

gittbd finish --pr
gittbd validate feature/delete-task
```

#### Feature 3 : Marquer comme fait

```bash
# Mode ultra-court (juste le nom)
gittbd start toggle-done
# 🎯 Type de branche non spécifié, sélection interactive
# [fzf avec les types]
# → feature
# ✅ Création de ✨ feature/toggle-done

echo "function toggleDone() { ... }" >> app.js
git add app.js
git commit -m "feat: toggle état tâche"

gittbd finish --pr
gittbd validate feature/toggle-done
```

---

### Étape 3 : Première version (MVP)

```bash
# On est sur main avec 3 features mergées
git checkout main
git pull

# Créer la version 0.1.0 (premier MVP)
gittbd bump minor

# 🔍 Version actuelle : v0.0.0
# 📦 Nouvelle version : v0.1.0
# 
# 📝 Changements depuis v0.0.0
# 
# - feat: toggle état tâche (a1b2c3d)
# - feat: ajout fonction deleteTask (e4f5g6h)
# - feat: UI pour ajouter tâche (i7j8k9l)
# - feat: ajout fonction addTask (m0n1o2p)
# - Initial commit (q3r4s5t)
# 
# ✅ Créer le tag v0.1.0 ? [y/N] y
# 
# 🏷️  Tag v0.1.0 créé localement
# 📤 Push du tag vers origin...
# ✅ Tag v0.1.0 publié sur origin
# 
# 🔗 Liens utiles
#    Release : https://github.com/user/mon-app-todo/releases/tag/v0.1.0
#    Compare : https://github.com/user/mon-app-todo/compare/v0.0.0...v0.1.0
# 
# 🎉 Version v0.1.0 publiée avec succès !
```

---

### Étape 4 : Bug critique découvert

```bash
# Un utilisateur signale un bug
gittbd start hotfix/crash-empty-list

echo "if (tasks.length === 0) return;" >> app.js
git add app.js
git commit -m "fix: crash quand liste vide"

gittbd finish --pr
gittbd validate hotfix/crash-empty-list

# Bump PATCH (correction de bug)
git checkout main
git pull
gittbd bump patch

# 🔍 Version actuelle : v0.1.0
# 📦 Nouvelle version : v0.1.1
# 
# 📝 Changements depuis v0.1.0
# 
# - fix: crash quand liste vide (u6v7w8x)
# 
# ✅ Créer le tag v0.1.1 ? [y/N] y
# 🎉 Version v0.1.1 publiée avec succès !
```

---

### Étape 5 : Nouvelles features

```bash
# Feature : Filtres
gittbd start feature/filters
echo "function filterTasks() { ... }" >> app.js
git add app.js
git commit -m "feat: filtres all/active/done"
gittbd finish --pr
gittbd validate feature/filters

# Feature : Sauvegarde localStorage
gittbd start feature/localstorage
echo "localStorage.setItem('tasks', ...)" >> app.js
git add app.js
git commit -m "feat: persistence localStorage"
gittbd finish --pr
gittbd validate feature/localstorage

# Bump MINOR (2 nouvelles features)
git checkout main
git pull
gittbd bump minor

# 🔍 Version actuelle : v0.1.1
# 📦 Nouvelle version : v0.2.0
# 
# 📝 Changements depuis v0.1.1
# 
# - feat: persistence localStorage (y9z0a1b)
# - feat: filtres all/active/done (c2d3e4f)
# 
# ✅ Créer le tag v0.2.0 ? [y/N] y
# 🎉 Version v0.2.0 publiée avec succès !
```

---

### Étape 6 : Refonte majeure (Breaking Change)

```bash
# Décision : migration vers React
gittbd start feature/react-rewrite

# ... beaucoup de commits ...
git add .
git commit -m "feat!: migration vers React"
git commit -m "BREAKING CHANGE: l'ancienne API n'est plus supportée"

gittbd finish --pr
gittbd validate feature/react-rewrite

# Bump MAJOR (breaking change)
git checkout main
git pull
gittbd bump major

# 🔍 Version actuelle : v0.2.0
# 📦 Nouvelle version : v1.0.0
# 
# 📝 Changements depuis v0.2.0
# 
# - BREAKING CHANGE: l'ancienne API n'est plus supportée (g5h6i7j)
# - feat!: migration vers React (k8l9m0n)
# 
# ✅ Créer le tag v1.0.0 ? [y/N] y
# 🎉 Version v1.0.0 publiée avec succès !
```

---

## 📊 Historique final

```bash
git tag
# v0.1.0  - MVP initial (3 features)
# v0.1.1  - Hotfix crash
# v0.2.0  - Ajout filtres + localStorage
# v1.0.0  - Migration React (breaking)
```

---

## 🎯 Visualisation sur GitHub

Sur `https://github.com/user/mon-app-todo/releases`, vous verrez :

```
📦 v1.0.0 - Latest
   BREAKING CHANGE: Migration vers React
   [Download Source code (zip)]
   [Download Source code (tar.gz)]

📦 v0.2.0
   Nouvelles features : filtres + localStorage
   
📦 v0.1.1
   Hotfix : crash liste vide
   
📦 v0.1.0
   MVP initial
```

---

## 🔄 Workflow quotidien résumé

```bash
# 1. Créer une branche
gittbd start feature/ma-feature
# ou
gittbd start ma-feature  # Sélection interactive du type

# 2. Développer
git add .
git commit -m "feat: description"

# 3. Publier + PR
gittbd finish --pr

# 4. Valider (après review)
gittbd validate feature/ma-feature

# 5. Bumper (quand prêt pour release)
git checkout main
gittbd bump patch|minor|major
```

---

## 💡 Cas d'usage avancés

### Mode silencieux (CI/CD)

```bash
# Dans un pipeline GitHub Actions
SILENT_MODE=true gittbd bump patch --yes
```

### Test local avant push

```bash
# Créer le tag mais ne pas pusher
gittbd bump minor --no-push

# Vérifier
git tag
# v0.3.0

# Pusher manuellement plus tard
git push origin v0.3.0
```

### Corriger une erreur de version

```bash
# Oups, j'ai créé v0.3.0 par erreur
git tag -d v0.3.0              # Supprimer local
git push origin --delete v0.3.0 # Supprimer remote

# Recréer correctement
gittbd bump patch  # v0.2.1
```

---

## 🎓 Exercice pratique

Essayez ce workflow sur un vrai projet :

1. ✅ Créer 3 branches feature
2. ✅ Merger via PR avec squash local
3. ✅ Créer votre premier tag v0.1.0
4. ✅ Ajouter un hotfix → v0.1.1
5. ✅ Ajouter 2 features → v0.2.0
6. ✅ Consulter les releases sur GitHub

**Temps estimé** : 30 minutes

---

## 📚 Aller plus loin

- Automatiser le bump dans GitHub Actions
- Générer un CHANGELOG.md automatique
- Créer des release notes formatées
- Déployer automatiquement à chaque tag

Consultez `VERSIONING.md` pour plus de détails !
