#!/bin/bash
# lib/commands/sync.sh
# shellcheck disable=SC2154

# Note : Cette commande est un wrapper CLI de sync_branch_to_remote()
# qui est déjà définie dans lib/domain/sync.sh
# On ne redéfinit rien ici, juste un alias si besoin

# Si tu veux ajouter une logique CLI spécifique, tu peux faire :
# sync_command() {
#   # Wrapper CLI avec parsing d'arguments spécifique
#   sync_branch_to_remote "$@"
# }

# Pour l'instant, on utilise directement sync_branch_to_remote
# qui est appelée depuis le dispatcher dans bin/gittbd