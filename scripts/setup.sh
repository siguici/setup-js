#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/messages.sh"

if [ -z "$GITHUB_ENV" ]; then
  panic "GITHUB_ENV is not defined. Provide a path to a writable file."
fi

parse_pm() {
  local input=$1
  local name=$(echo "$input" | grep -o '^[^@]*')
  local version=$(echo "$input" | grep -o '@.*' | sed 's/^@//' || echo "latest")
  echo "$name $version"
}

if [ -z "$runtime" ]; then
  warning "No runtime provided, runtime detection..."

  if command -v bun &>/dev/null; then
    runtime="bun"
  elif command -v deno &>/dev/null; then
    runtime="deno"
  else
    runtime="node"
  fi
fi

if [ -n "$input_pm" ] && [ "${#input_pm}" -gt 1 ]; then
  read -r pm pm_version <<< "$(parse_pm "$input_pm")"

  [ -z "$pm_version" ] && pm_version="latest"

  if [[ ! "$pm" =~ ^(npm|yarn|pnpm|bun|deno)$ ]]; then
    panic "Invalid package manager '$pm'. Valid options are npm, yarn, pnpm, bun, deno."
  fi
else
  if [ -f "package.json" ]; then
    package_manager=$(jq -r '.packageManager // empty' package.json 2>/dev/null)
    if [ -n "$package_manager" ]; then
      read -r pm pm_version <<< "$(parse_pm "$package_manager")"
    fi
  fi

  if [ -z "$pm" ]; then
    if [ -f "pnpm-lock.yaml" ]; then
      pm="pnpm"
      pm_lockfile="pnpm-lock.yaml"
    elif [ -f "yarn.lock" ]; then
      pm="yarn"
      pm_lockfile="yarn.lock"
    elif [ -f "package-lock.json" ]; then
      pm="npm"
      pm_lockfile="package-lock.json"
    elif [ -f "bun.lockb" ]; then
      pm="bun"
      pm_lockfile="bun.lockb"
    elif [ -f "deno.lock" ]; then
      pm="deno"
      pm_lockfile="deno.lock"
    fi
  fi

  if [ -z "$pm" ]; then
    case "$runtime" in
      "bun")
        pm="bun"
        ;;
      "deno")
        pm="deno"
        ;;
      *)
        pm="npm"
        ;;
    esac
  fi

  pm_version=${pm_version:-"latest"}
fi

version=$($runtime --version)

if [[ "$pm" == "$runtime" ]]; then
  info "Using $runtime@$version"
else
  info "$pm@$pm_version detected with lockfile $pm_lockfile under $runtime@$version"
fi

echo "runtime=$runtime" >> "$GITHUB_ENV"
echo "version=$version" >> "$GITHUB_ENV"
echo "pm=$pm" >> "$GITHUB_ENV"
echo "pm_version=$pm_version" >> "$GITHUB_ENV"
echo "pm_lockfile=${pm_lockfile:-none}" >> "$GITHUB_ENV"
