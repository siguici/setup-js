#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/messages.sh"

IFS=',' read -ra scripts <<< "$scripts"

for script in "${scripts[@]}"; do
  message=$(get_script_message "$script")
  echo "$message..."

  case "$pm" in
  "npm"|"bun")
    $pm run $script
    success "$pm run $script executed"
    ;;
  "pnpm"|"yarn")
    $pm $script
    success "$pm $script executed"
    ;;
  "deno")
    deno task $script
    success "deno task $script executed"
    ;;
  *)
    panic "Unknown package manager: $pm"
    ;;
  esac
done

