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

get_script_message() {
  local script="$1"
  for key in "${!script_messages[@]}"; do
    if [[ "$script" == $key || "$script" == $key:* || "$script" == $key.* || "$script" == *:$key || "$script" == *.$key ]]; then
      echo "${script_messages[$key]} ($script)"
      return
    fi
  done
  echo "🔨 Running $script"
}

IFS=',' read -ra scripts <<< "$scripts"

for script in "${scripts[@]}"; do
  message=$(get_script_message "$script")
  echo "$message..."

  case "$runtime" in
    "node")
      $pm run $script
      echo "ℹ️ $pm run $script executed"
      ;;
    "deno")
      deno task $script
      echo "ℹ️ deno task $script executed"
      ;;
    "bun")
      bun run $script
      echo "ℹ️ bun run $script executed"
      ;;
  esac
done

