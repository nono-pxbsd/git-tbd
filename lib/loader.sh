#!/bin/bash
# lib/loader.sh

set -euo pipefail

# Détection du répertoire lib
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=/dev/null

# Configuration globale
source "${LIB_DIR}/config.sh"

# Core (pas de dépendances métier)
source "${LIB_DIR}/core/logging.sh"                 # Système de logs
source "${LIB_DIR}/core/git_wrapper.sh"             # Wrapper Git sécurisé
source "${LIB_DIR}/core/validation.sh"              # Validations génériques

# Domain (logique métier Git)
source "${LIB_DIR}/domain/branches.sh"              # Gestion branches
source "${LIB_DIR}/domain/commits.sh"               # Gestion commits
source "${LIB_DIR}/domain/sync.sh"                  # Synchronisation
source "${LIB_DIR}/domain/requests.sh"              # PR/MR

# Commands (interface CLI)
source "${LIB_DIR}/commands/start.sh"
source "${LIB_DIR}/commands/finish.sh"
source "${LIB_DIR}/commands/publish.sh"
source "${LIB_DIR}/commands/open_request.sh"
source "${LIB_DIR}/commands/validate_request.sh"
source "${LIB_DIR}/commands/cleanup.sh"
source "${LIB_DIR}/commands/sync.sh"
source "${LIB_DIR}/commands/bump.sh"