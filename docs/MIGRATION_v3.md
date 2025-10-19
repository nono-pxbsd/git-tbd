# 🚀 Guide de Migration v2 → v3

Ce guide vous accompagne pour migrer de gittbd v2.x vers v3.0.0.

---

## 🎯 Résumé des changements majeurs

### ⚠️ Breaking Changes

| Aspect | Avant (v2.x) | Après (v3.0) | Impact |
|--------|-------------|--------------|--------|
| **finish --pr** | Squash local + push + PR | Push + PR (PAS de squash) | 🔴 Majeur |
| **validate** | Merge via GitHub/GitLab | Squash merge local | 🔴 Majeur |
| **Historique** | 1 commit squashé dans branche | Commits multiples dans branche | 🟡 Moyen |
| **Cleanup** | `git branch -d` échoue parfois | `gittbd cleanup` requis | 🟢 Nouveau |
| **Terminologie interne** | `pr_*` / `mr_*` | `request_*` | 🟢 Interne |

**Verdict** : **C'est une v3.0.0** (changements majeurs dans le workflow)

---

## 📋 Table des matières

   - Pourquoi cette refonte ?
   - Problèmes résolus
   - Workflow v2 vs v3
   - Migration pas à pas
   - Nouvelles commandes
   - Configuration
   - FAQ
   - Rollback

---

## 🤔 Pourquoi cette refonte ?

### Problèmes résolus en v3

#### 1. Gestion des modifications après PR

**v2.x - Problématique :**
```bash
# Workflow v2
gittbd finish --pr
# → Squash local : 3 commits → 1
# → Force push de la branche squashée
# → Création PR

# État de la branche : 1 commit squashé

# Review demande une modification
git commit -m "fix: after review"
git push

# Problème : Branche a maintenant
# - 1 commit squashé (ancien)
# - 1 commit nouveau
# → Historique hybride, besoin de re-squash manuel
```

**v3.0 - Solution :**
```bash
# Workflow v3
gittbd finish --pr
# → Push (pas de squash)
# → Création PR

# État de la branche : 3 commits originaux

# Review demande une modification
git commit -m "fix: after review"
git push

# ✅ Pas de problème : on ajoute juste un commit
# ✅ Squash fait au moment du merge (par validate)
```

---

#### 2. Désynchronisation après merge GitHub

**v2.x - Problématique :**
```bash
# Après merge via GitHub (Squash and merge)
git checkout main
git pull

git branch -d feature/login
# ❌ error: not fully merged

# Pourquoi ?
# - GitHub a squashé en un nouveau commit (SHA différent)
# - Ta branche locale a toujours les commits originaux
# - Git ne voit pas que c'est "merged"
```

**v3.0 - Solution :**
```bash
# Option A : Merge via gittbd validate
gittbd validate feature/login
# ✅ Squash merge local
# ✅ Branche nettoyée automatiquement

# Option B : Merge via GitHub + cleanup
# Clic sur "Squash and merge" dans GitHub
gittbd cleanup feature/login
# ✅ Nettoyage propre
```

---

## 🎯 Philosophie v3

**Principe clé :**
> "Une PR doit pouvoir évoluer naturellement jusqu'au merge final, sans manipulation d'historique prématurée."

**Analogie :**
- **v2 :** Tu compresses un fichier ZIP, puis tu veux y ajouter des fichiers → galère
- **v3 :** Tu ajoutes tous les fichiers que tu veux, et tu compresses seulement à la fin → fluide

---

## 💡 Cas d'usage

### Cas 1 : Feature simple (1 commit)
**v2 et v3 :** Pareil, aucune différence

### Cas 2 : Feature avec review (3 commits + 2 après review)
**v2 :** Historique moche après review  
**v3 :** ✅ Historique propre, tout squashé proprement au merge

### Cas 3 : Merge via GitHub au lieu de gittbd
**v2 :** `git branch -d` échoue, nettoyage manuel galère  
**v3 :** ✅ `gittbd cleanup` gère tout proprement

---

## 🔄 Workflow v2 vs v3

### Workflow complet : Avant / Après

#### v2.x - Workflow actuel

```bash
# 1. Développement
gittbd start feature/login
git commit -m "feat: add form"
git commit -m "feat: add validation"
git commit -m "fix: typo"

# État de la branche : 3 commits

# 2. Finish avec PR
gittbd finish --pr

# Ce qui se passe :
# a) Squash local : 3 commits → 1 commit
# b) Force push de la branche squashée
# c) Création PR

# État de la branche : 1 commit squashé

# 3. Validation via GitHub
# Clic sur "Squash and merge"

# Résultat :
# ✅ Historique propre dans main
# ❌ git branch -d échoue (désynchronisation)
# ❌ Si modifs après PR, besoin de re-squash
```

#### v3.0 - Nouveau workflow

```bash
# 1. Développement
gittbd start feature/login
git commit -m "feat: add form"
git commit -m "feat: add validation"
git commit -m "fix: typo"

# État de la branche : 3 commits

# 2. Finish avec PR
gittbd finish --pr

# Ce qui se passe :
# a) Push normal (PAS de squash)
# b) Création PR avec titre auto-généré
# c) Body PR = liste des 3 commits

# État de la branche : 3 commits (inchangés)

# 3a. Validation via gittbd (recommandé)
gittbd validate feature/login

# Ce qui se passe :
# a) Squash merge local
# b) Commit avec titre PR + liste commits
# c) Push vers main
# d) Fermeture PR
# e) Nettoyage branches

# Résultat :
# ✅ Historique propre dans main
# ✅ Branche nettoyée automatiquement
# ✅ Pas de désynchronisation

# 3b. OU validation via GitHub
# Clic sur "Squash and merge" dans GitHub

# Puis cleanup :
gittbd cleanup feature/login

# Résultat :
# ✅ Historique propre dans main
# ✅ Branche nettoyée proprement
```

---

## 🔧 Migration pas à pas

### Étape 1 : Sauvegarde

```bash
# Sauvegarder votre configuration personnalisée
cp ~/.local/share/gittbd/lib/config.sh ~/gittbd-config-v2-backup.sh

# Vérifier votre version actuelle
gittbd help | grep Version
# Version : 2.x.x
```

---

### Étape 2 : Mise à jour

```bash
# Aller dans le répertoire d'installation
cd ~/.local/share/gittbd

# Mettre à jour
git fetch origin
git checkout main
git pull

# Vérifier la nouvelle version
gittbd help | grep Version
# Version : 3.0.0
```

---

### Étape 3 : Adapter la configuration

```bash
# Éditer la configuration
vim ~/.local/share/gittbd/lib/config.sh
```

**Changements nécessaires :**

#### Variables renommées

```bash
# v2.x
OPEN_PR=true
REQUIRE_PR_ON_FINISH=true

# v3.0
OPEN_REQUEST=true
REQUIRE_REQUEST_ON_FINISH=true
```

#### Valeur simplifiée

```bash
# v2.x
DEFAULT_MERGE_MODE="local-squash"  # ou "squash" ou "merge"

# v3.0
DEFAULT_MERGE_MODE="squash"  # ou "merge"
# Note : "local-squash" n'existe plus
```

---

### Étape 4 : Tester sur une branche test

```bash
# Créer une branche de test
gittbd start feature/test-v3

# Faire quelques commits
git commit -m "test: first" --allow-empty
git commit -m "test: second" --allow-empty

# Vérifier que la branche a bien 2 commits
git log --oneline -2

# Finish avec PR
gittbd finish --pr

# Vérifier :
# - La branche a toujours 2 commits (pas squashés)
# - Une PR a été créée
# - Le titre de la PR est construit depuis les commits

# Valider
gittbd validate feature/test-v3

# Vérifier dans main :
git log main --oneline -1
# → Doit montrer un commit squashé avec le titre de la PR

# Vérifier cleanup :
git branch
# → feature/test-v3 ne doit plus exister
```

---

### Étape 5 : Nettoyer les anciennes branches

Si vous avez des branches mergées via GitHub en v2.x qui n'ont pas été nettoyées :

```bash
# Lister les branches locales
git branch

# Pour chaque branche mergée (vérifier sur GitHub) :
gittbd cleanup feature/old-branch
```

---

## 🆕 Nouvelles commandes

### gittbd cleanup (nouveau !)

Nettoie une branche après un merge via GitHub/GitLab.

```bash
# Nettoyage d'une branche spécifique
gittbd cleanup feature/login

# Auto-détection (si une seule branche)
gittbd cleanup

# Avec sélection interactive (si plusieurs branches)
gittbd clean

# Raccourci
gittbd c
```

**Ce qui est fait :**
- ✅ Mise à jour de main
- ✅ Suppression de la branche locale (force delete)
- ✅ Suppression de la branche distante (si existe)
- ✅ Nettoyage des références Git

**Quand l'utiliser :**
- Après un merge via le bouton GitHub/GitLab
- Pour nettoyer les branches obsolètes

---

### gittbd validate (refactorisé)

Comportement changé en v3 :

**v2.x :**
```bash
gittbd validate feature/login
# → Appelle gh pr merge --squash
# → GitHub fait le merge
```

**v3.0 :**
```bash
gittbd validate feature/login
# → Squash merge LOCAL
# → Commit avec titre PR
# → Push vers main
# → Ferme la PR
# → Nettoie les branches
```

**Avantage :** Contrôle total sur le message de commit.

---

## ⚙️ Configuration

### Fichier lib/config.sh

#### Variables renommées (BREAKING)

| v2.x | v3.0 | Action |
|------|------|--------|
| `OPEN_PR` | `OPEN_REQUEST` | Renommer |
| `REQUIRE_PR_ON_FINISH` | `REQUIRE_REQUEST_ON_FINISH` | Renommer |

#### Valeurs simplifiées (BREAKING)

| Variable | v2.x | v3.0 |
|----------|------|------|
| `DEFAULT_MERGE_MODE` | squash / merge / local-squash | squash / merge |

**Note :** `local-squash` n'existe plus en v3.

#### Nouvelle variable (optionnel)

```bash
# Auto-détecter et proposer le cleanup des branches mergées sur GitHub
# Si true, gittbd vérifie au démarrage si des branches locales ont été mergées
# et propose de les nettoyer
AUTO_CLEANUP_DETECTION="${AUTO_CLEANUP_DETECTION:-false}"
```

**Usage :**
```bash
# Dans lib/config.sh
AUTO_CLEANUP_DETECTION=true

# Au lancement de gittbd
gittbd start feature/test
# 🧹 Branche mergée détectée : feature/old-branch
# Nettoyer maintenant ? [Y/n]
```

---

## ❓ FAQ

### 1. Dois-je changer mes habitudes ?

**Non !** Les commandes restent les mêmes :

```bash
# v2.x
gittbd start feature/login
gittbd finish --pr
gittbd validate

# v3.0 (identique)
gittbd start feature/login
gittbd finish --pr
gittbd validate
```

**Seule différence :** Si vous mergiez via GitHub, ajoutez `gittbd cleanup` après.

---

### 2. Puis-je toujours merger via GitHub ?

**Oui !** Deux workflows possibles :

**Workflow A (recommandé) :**
```bash
gittbd finish --pr
gittbd validate  # Merge local
```

**Workflow B :**
```bash
gittbd finish --pr
# Clic sur "Squash and merge" dans GitHub
gittbd cleanup  # Nettoyage
```

---

### 3. Que faire de mes branches v2.x existantes ?

**Branches pas encore mergées :**
- ✅ Continuez normalement avec v3
- ✅ Elles fonctionneront sans problème

**Branches déjà mergées en v2.x :**
- ✅ Utilisez `gittbd cleanup` pour nettoyer

---

### 4. L'historique de main va-t-il changer ?

**Non !** L'historique de `main` reste identique :

```
# v2.x et v3.0 produisent le même historique
main:
  * ✨ feat: login form (PR #34)
  * 🐛 fix: bug (PR #33)
```

---

### 5. Quid des modifications après PR ?

C'est justement un des avantages de v3 !

```bash
# v3.0
gittbd finish --pr
# Review demande un changement
git commit -m "fix: after review"
git push
# ✅ Pas de problème, pas de re-squash nécessaire

gittbd validate
# → Squashe TOUS les commits (originaux + modifs)
```

---

### 6. Puis-je revenir à v2.x ?

Oui, voir la section [Rollback](#rollback-si-besoin).

---

## 🔙 Rollback si besoin

Si vous rencontrez des problèmes avec v3.0 :

```bash
# 1. Aller dans le répertoire d'installation
cd ~/.local/share/gittbd

# 2. Revenir à la dernière version v2.x
git fetch --tags
git checkout v2.2.2  # Ou la dernière v2.x

# 3. Restaurer votre configuration
cp ~/gittbd-config-v2-backup.sh lib/config.sh

# 4. Vérifier
gittbd help | grep Version
# Version : 2.2.2

# 5. Recharger le shell
source ~/.zshrc  # ou ~/.bashrc
```

**Pour revenir à v3.0 plus tard :**
```bash
cd ~/.local/share/gittbd
git checkout main
git pull
```

---

## 📞 Support

- 💬 Ouvrir une issue sur GitHub : https://github.com/nono-pxbsd/git-tbd/issues
- 📚 Documentation complète : README.md
- 📖 Guide du versioning : VERSIONING.md

---

## 🎉 Bonne migration !

La v3.0 apporte une meilleure gestion des modifications après PR et un cleanup plus propre.

N'hésitez pas à remonter des bugs ou suggestions ! 🚀
