# 🚀 Guide de Migration v1 → v2

Ce guide vous accompagne pour migrer de votre version actuelle de `git-tbd` vers la nouvelle version `gittbd` v2.0.

---

## 📋 Résumé des changements

### ✨ Nouveautés v2.0

1. **Renommage** : `git-tbd` → `gittbd` (alias conservé pour compatibilité)
2. **Raccourcis** : `s`, `f`, `v`, `p`, `mr`, `b` pour aller plus vite
3. **Support GitLab** : Fonctionne avec GitHub ET GitLab
4. **Terminologie adaptative** : "PR" sur GitHub, "MR" sur GitLab
5. **Mode silencieux amélioré** : `SILENT_MODE=true` pour CI/CD
6. **Émojis configurables** : `USE_EMOJI_IN_COMMIT_TITLE` dans config
7. **Bump versioning** : Gestion complète des tags SemVer
8. **Logs structurés** : Plus de race conditions, messages clairs
9. **fzf intégré** : Sélection interactive des types de branche
10. **Documentation complète** : README, VERSIONING.md, TUTORIAL.md

### 🔧 Corrections de bugs

- ✅ Race conditions entre Git et prompts résolues
- ✅ Messages dupliqués supprimés
- ✅ Prompts qui bloquent corrigés
- ✅ Gestion d'erreurs améliorée partout
- ✅ Encoding UTF-8 corrigé

---

## 📦 Étape 1 : Sauvegarde

```bash
# Sauvegarder l'ancienne version
cd ~/git-tbd
cp -r . ../git-tbd-v1-backup

# Vérifier
ls -la ../git-tbd-v1-backup
```

---

## 📥 Étape 2 : Récupérer les nouveaux fichiers

Vous avez deux options :

### Option A : Depuis cette conversation

Téléchargez tous les artifacts de cette conversation et remplacez les fichiers :

```
Structure attendue :
gittbd/
├── bin/
│   └── gittbd                  ← Artifact "gittbd (binaire principal)"
├── lib/
│   ├── config.sh               ← Artifact "config.sh (final)"
│   ├── utils.sh                ← Artifact "utils.sh (final)"
│   ├── branches.sh             ← Artifact "branches.sh (refactoré)"
│   └── commands.sh             ← Artifact "commands.sh (final)"
├── tests/
│   └── test_prompts.sh         ← Artifact "tests/test_prompts.sh"
├── docs/
│   ├── VERSIONING.md           ← Artifact "VERSIONING.md"
│   ├── TUTORIAL.md             ← Artifact "TUTORIAL.md"
│   └── MIGRATION.md            ← Ce fichier
├── Makefile                    ← Artifact "Makefile (refactoré)"
└── README.md                   ← Artifact "README.md (final)"
```

### Option B : Depuis un repo Git (si vous avez pushé)

```bash
cd ~/git-tbd
git pull origin main
```

---

## 🔧 Étape 3 : Renommer et rendre exécutable

```bash
cd ~/git-tbd

# Renommer le binaire (si nécessaire)
mv bin/git-tbd bin/gittbd 2>/dev/null || true

# Permissions
chmod +x bin/gittbd
chmod +x tests/test_prompts.sh
```

---

## 🗑️ Étape 4 : Désinstaller l'ancienne version

```bash
cd ~/git-tbd
make uninstall

# Vérifier
which git-tbd
# → devrait retourner "not found"
```

---

## 📦 Étape 5 : Réinstaller

```bash
# Installation locale (recommandé)
make install MODE=local

# OU installation globale
make install MODE=global

# Recharger le shell
source ~/.zshrc  # ou ~/.bashrc
```

**Vérifications** :

```bash
# Vérifier l'installation
which gittbd
# → ~/.local/bin/gittbd ou /usr/local/bin/gittbd

which git-tbd
# → Devrait pointer vers gittbd (alias)

# Vérifier la version
gittbd help
# → Devrait afficher l'aide v2.0
```

---

## 🧪 Étape 6 : Tests

### Test 1 : Commande de base

```bash
gittbd help
# ✅ Devrait afficher l'aide avec les nouveaux raccourcis
```

### Test 2 : Raccourcis

```bash
gittbd s
# ✅ Devrait ouvrir fzf (ou menu) pour créer une branche
# Annuler avec Ctrl+C
```

### Test 3 : Suite de tests

```bash
cd ~/git-tbd
bash tests/test_prompts.sh
# ✅ Tous les tests doivent passer
```

### Test 4 : Workflow complet

```bash
# Dans un projet de test
cd ~/un-projet-test

# 1. Créer une branche
gittbd s
# → Choisir "feature"
# → Entrer "test-v2"

# 2. Faire un commit
echo "test" > test.txt
git add test.txt
git commit -m "test: validation v2"

# 3. Publier
gittbd p

# 4. Tester finish (sans --pr pour ne pas créer de PR)
gittbd f
# ✅ Devrait merger localement
```

---

## 🔄 Étape 7 : Migration de la config

Si vous aviez personnalisé `lib/config.sh`, migrez vos changements :

```bash
# Comparer l'ancienne et la nouvelle config
diff ../git-tbd-v1-backup/lib/config.sh lib/config.sh

# Nouvelle options à considérer :
# - USE_EMOJI_IN_COMMIT_TITLE=true
# - GIT_PLATFORM="github"  # ou "gitlab"
```

**Nouvelles variables disponibles** :

```bash
# lib/config.sh

# Désactiver les émojis dans les commits
USE_EMOJI_IN_COMMIT_TITLE=false

# Utiliser GitLab
GIT_PLATFORM="gitlab"

# Mode silencieux par défaut
SILENT_MODE=true

# Pas de PR/MR obligatoire
REQUIRE_PR_ON_FINISH=false
```

---

## 📱 Étape 8 : Mettre à jour vos scripts/alias

Si vous aviez des scripts ou alias utilisant `git-tbd`, mettez-les à jour :

### Anciens alias

```bash
# ~/.zshrc (ancien)
alias gs="git-tbd start"
alias gf="git-tbd finish"
```

### Nouveaux alias (optionnel, car raccourcis intégrés)

```bash
# ~/.zshrc (nouveau - optionnel)
alias gt="gittbd"
# → gt s    = gittbd start
# → gt f    = gittbd finish
```

**Note** : Les raccourcis sont maintenant intégrés, donc moins besoin d'alias personnalisés !

---

## 🦊 Étape 9 : Configuration GitLab (si applicable)

Si vous utilisez GitLab :

```bash
# 1. Installer glab
curl -s https://gitlab.com/gitlab-org/cli/-/releases/permalink/latest/downloads/glab_amd64.deb -o glab.deb
sudo dpkg -i glab.deb

# 2. Authentification
glab auth login

# 3. Configurer la plateforme
export GIT_PLATFORM=gitlab
echo 'export GIT_PLATFORM=gitlab' >> ~/.zshrc

# OU dans lib/config.sh
# GIT_PLATFORM="gitlab"

# 4. Tester
gittbd mr
# ✅ Devrait utiliser "MR" dans les messages
```

---

## ✅ Étape 10 : Vérification finale

### Checklist de migration

- [ ] Backup effectué
- [ ] Nouveaux fichiers installés
- [ ] Permissions exécutables appliquées
- [ ] Ancienne version désinstallée
- [ ] Nouvelle version installée
- [ ] Shell rechargé
- [ ] `gittbd help` fonctionne
- [ ] Raccourcis (`s`, `f`, etc.) fonctionnent
- [ ] Tests passent (`tests/test_prompts.sh`)
- [ ] Workflow complet testé
- [ ] Config personnalisée migrée
- [ ] Scripts/alias mis à jour (si applicable)
- [ ] GitLab configuré (si applicable)

---

## 🎉 Migration terminée !

Vous pouvez maintenant utiliser la v2.0 avec toutes les nouvelles fonctionnalités !

### Nouveaux workflows disponibles

```bash
# Workflow ultra-rapide
gittbd s                        # Mode interactif
git add . && git commit -m "..."
gittbd f --pr                   # Finish + PR
gittbd v                        # Valider

# Versioning
git checkout main
gittbd b patch                  # Bump version

# GitLab
GIT_PLATFORM=gitlab gittbd mr   # Merge Request
```

### Prochaines étapes

1. ✅ Lire [VERSIONING.md](docs/VERSIONING.md) pour comprendre le bump
2. ✅ Suivre le [TUTORIAL.md](docs/TUTORIAL.md) pour un exemple complet
3. ✅ Configurer le mode silencieux pour CI/CD si besoin
4. ✅ Tester sur un vrai projet

---

## 🐛 Problèmes courants

### "command not found: gittbd"

```bash
# Vérifier le PATH
echo $PATH | grep ".local/bin"

# Si absent, ajouter
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

### "fzf not found"

```bash
# Installer fzf
sudo apt install fzf

# Tester
echo -e "option1\noption2" | fzf
```

### "gh/glab not found"

```bash
# Pour GitHub
sudo apt install gh
gh auth login

# Pour GitLab
curl -s https://gitlab.com/gitlab-org/cli/-/releases/permalink/latest/downloads/glab_amd64.deb -o glab.deb
sudo dpkg -i glab.deb
glab auth login
```

### "Émojis ne s'affichent pas"

```bash
# Vérifier l'encoding
echo $LANG
# Devrait contenir "UTF-8"

# Si non
export LANG=en_US.UTF-8
```

### "Tests échouent"

```bash
# Mode debug
DEBUG_MODE=true bash tests/test_prompts.sh

# Vérifier les dépendances
make check-deps
```

---

## 🔙 Rollback (si nécessaire)

Si vous rencontrez des problèmes, vous pouvez revenir en arrière :

```bash
# Désinstaller v2
cd ~/git-tbd
make uninstall

# Restaurer v1
cd ~
rm -rf git-tbd
mv git-tbd-v1-backup git-tbd
cd git-tbd

# Réinstaller v1
make install MODE=local
source ~/.zshrc
```

---

## 📞 Support

- 💬 Ouvrir une issue sur GitHub
- 📧 Contacter : nono.pxbsd
- 📚 Documentation : [README.md](README.md)

---

Bonne migration ! 🚀
