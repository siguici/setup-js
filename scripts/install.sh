#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/utils.sh"

pm=${1:-"npm"}
pm_version=${2:-"latest"}

# Ensure prerequisites
command -v jq &> /dev/null || panic "jq is not installed. Please install it and try again."
[[ -f "package.json" ]] || panic "No package.json found in the current working directory."

install_pm() {
  local pm=$1 pm_version=$2

  if command -v corepack &> /dev/null; then
    info "Installing $pm@$pm_version using Corepack..."
    corepack enable || panic "Failed to enable Corepack."
    corepack prepare "$pm@$pm_version" --activate || panic "Failed to prepare Corepack for $pm@$pm_version."
  else
    warning "Corepack is not installed."
    info "Installing $pm@$pm_version globally via NPM..."
    npm install -g "$pm@$pm_version" || panic "Failed to install $pm@$pm_version globally via NPM."
  fi
}

update_pm() {
  local pm=$1 pm_version=$2
  local current_version

  current_version=$("$pm" --version)

  if [[ "$pm_version" == "latest" ]]; then
    pm_version=$(npm show "$pm" version 2>/dev/null) || \
      pm_version=$(curl -s "https://registry.npmjs.org/$pm/latest" | jq -r '.version') || \
      panic "Failed to fetch the latest version of $pm."
  fi

  if [[ "$current_version" != "$pm_version" ]]; then
    info "Updating $pm version from $current_version to $pm_version..."
    $pm install -g "$pm@$pm_version" || panic "Failed to update $pm to version $pm_version."
  else
    info "$pm is already at the requested version $pm_version."
  fi
}

install_or_update_pm() {
  local pm=$1
  local pm_version=$2

  if ! command -v "$pm" &> /dev/null; then
    install_pm "$pm" "$pm_version"
  else
    update_pm "$pm" "$pm_version"
  fi
}

install_or_update_pm $pm $pm_version

# Handle package manager and runtime
if [[ "$pm" == "npm" || "$pm" == "pnpm" || "$pm" == "yarn" || "$pm" == "bun" ]]; then
  info "Preparing package.json for $pm..."

  if [[ "$pm_version" == "latest" ]]; then
    pm_version=$("$pm" --version) || panic "Failed to determine $pm version."
  fi

  jq ".packageManager = \"$pm@$pm_version\"" package.json > package.json.tmp || panic "Failed to update package.json."
  mv package.json package.json.bak || panic "Failed to backup package.json."
  mv package.json.tmp package.json || panic "Failed to replace package.json."

  if [[ "$pm" == "npm" ]]; then
    npm install --legacy-peer-deps || panic "npm install failed."
  else
    $pm install || panic "$pm install failed."
  fi
elif [[ "$pm" == "deno" ]]; then
  deno install --allow-scripts || panic "'deno install --allow-scripts' failed"
else
  $pm install || panic "'$pm install' failed."
fi
