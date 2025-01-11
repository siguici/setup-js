#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/messages.ini"

declare -A script_messages=(
  ["test"]=$TEST_MESSAGE
  ["lint"]=$LINT_MESSAGE
  ["format"]=$FORMAT_MESSAGE
  ["check"]=$CHECK_MESSAGE
  ["build"]=$BUILD_MESSAGE
  ["ci"]=$CI_MESSAGE
  ["deploy"]=$DEPLOY_MESSAGE
  ["release"]=$RELEASE_MESSAGE
)

error() {
  echo "❌ $1" >&2
}

info() {
  echo "ℹ️ $1"
}

warning() {
  echo "⚠️ $1"
}

success() {
  echo "✔  $1"
}

panic() {
  error "$1"
  exit "${2:-1}"
}

ensure_var_exists() {
  if [ -z "${1:-}" ]; then
    panic "Undefined or empty variable"
  fi
}

get_message() {
  local script="$1"

  ensure_var_exists script;

  for key in "${!script_messages[@]}"; do
    if [[ "$script" == $key || "$script" == $key:* || "$script" == $key.* || "$script" == *:$key || "$script" == *.$key ]]; then
      echo "${script_messages[$key]} ($script)"
      return
    fi
  done

  echo "🔨 Running $script"
}

message() {
  echo $(get_message "$1...")
}
