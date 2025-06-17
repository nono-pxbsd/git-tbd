#!/bin/bash

for type in "${!BRANCH_TYPES[@]}"; do
  eval "
  start_${type}() {
    local name=\"\$1\"
    if [[ -z \"\$name\" ]]; then
      echo -e \"\${YELLOW}⚠️  Tu dois spécifier un nom de ${type}.\${RESET}\"
      exit 1
    fi
    create_branch \"${type}\" \"\$name\"
  }
  "
done
