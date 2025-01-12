#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/utils.sh"

if [[ ! -f "package.json" ]]; then
  panic "No package.json found in the current working directory."
fi

if ! command -v corepack &> /dev/null; then
  panic "Corepack is not installed. Please install it and try again."
fi

if ! command -v jq &> /dev/null; then
  panic "jq is not installed. Please install it and try again."
fi

echo -e "⚙️ Installing $pm dependencies"

if [[ "${runtime}" == "node" ]]; then
  corepack enable || panic "Failed to enable Corepack."

  if [[ "$pm" == "yarn" ]]; then
    info "Preparing package.json for Yarn..."

    if [[ "$pm_version" == "latest" ]]; then
      pm_version=$(yarn --version) || panic "Failed to determine Yarn version."
    fi

    info "Defining the 'packageManager' field to 'yarn@$pm_version'..."
    jq ".packageManager = \"yarn@$pm_version\"" package.json > yarn-package.json ||
      panic "Failed to update package.json."

    mv package.json package.json.bak || panic "Failed to backup package.json."
    mv yarn-package.json package.json || panic "Failed to replace package.json."
  fi

  corepack prepare $pm@$pm_version --activate ||
    panic "Failed to prepare Corepack for $pm@$pm_version."

  if [[ "$pm" == "npm" ]]; then
    npm install --legacy-peer-deps || panic "npm install failed."
  else
    $pm install || panic "$pm install failed."
  fi
elif [[ "$pm" == "deno" ]]; then
  deno install -A || panic "'deno install -A' failed"
else
  $pm install || panic "'$pm install' failed."
fi
