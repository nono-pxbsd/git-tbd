#!/bin/bash
# lib/core/logging.sh
# shellcheck disable=SC2154

log_debug() {
  # Affiche si DEBUG_MODE=true
  [[ "$DEBUG_MODE" != true ]] && return
  echo -e "${BLUE}[DEBUG]${RESET} $*" >&2
}

log_info() {
  # Affiche si SILENT_MODE=false
  [[ "$SILENT_MODE" == true ]] && return
  echo -e "$*" >&2
}

log_warn() {
  # Toujours affiché
  [[ "$SILENT_MODE" == true ]] && return
  echo -e "${YELLOW}⚠️  $*${RESET}" >&2
}

log_error() {
  # Toujours affiché (même en mode silencieux)
  echo -e "${RED}❌ $*${RESET}" >&2
}

log_success() {
  # Affiche si SILENT_MODE=false
  [[ "$SILENT_MODE" == true ]] && return
  echo -e "${GREEN}✅ $*${RESET}" >&2
}

print_message() {
  # Affiche un message vers stderr (pour ne pas polluer stdout)
  echo -e "$*" >&2
}