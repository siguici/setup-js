#!/bin/bash

declare -A script_messages=(
  ["test"]="🧪 Running tests"
  ["lint"]="🧐 Linting code"
  ["format"]="✨ Formatting code"
  ["check"]="✅ Checking code style"
  ["build"]="🏗️ Building the project"
  ["ci"]="💚 Running CI pipeline"
  ["deploy"]="🚀 Deploying the project"
  ["release"]="📦 Project release"
)

isset() {
  if [ -z "${1:-}" ]; then
    echo "Undefined or empty variable" >&2
    return 1
  fi
}

get_script_message() {
  local script="$1"
  if ! isset "$script"; then
    return 1
  fi
  for key in "${!script_messages[@]}"; do
    if [[ "$script" == $key || "$script" == $key:* || "$script" == $key.* || "$script" == *:$key || "$script" == *.$key ]]; then
      echo "${script_messages[$key]} ($script)"
      return
    fi
  done
  echo "🔨 Running $script"
}

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

