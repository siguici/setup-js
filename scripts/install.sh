#!/bin/bash

error_exit() {
  echo "❌ $1" >&2
  exit 1
}

if [[ ! -f "package.json" ]]; then
  error_exit "No package.json found in the current working directory."
fi

if ! command -v corepack &> /dev/null; then
  error_exit "Corepack is not installed. Please install it and try again."
fi

if ! command -v jq &> /dev/null; then
  error_exit "jq is not installed. Please install it and try again."
fi

echo "⚙️ Installing $pm dependencies"

if [[ "${runtime}" == "node" ]]; then
  corepack enable || error_exit "Failed to enable Corepack."

  if [[ "$pm" == "yarn" ]]; then
    echo "ℹ️ Preparing package.json for Yarn..."

    if [[ "$pm_version" == "latest" ]]; then
      pm_version=$(yarn --version) || error_exit "Failed to determine Yarn version."
    fi

    echo "ℹ️ Defining the 'packageManager' field to 'yarn@$pm_version'..."
    jq ".packageManager = \"yarn@$pm_version\"" package.json > yarn-package.json ||
      error_exit "Failed to update package.json."

    mv package.json package.json.bak || error_exit "Failed to backup package.json."
    mv yarn-package.json package.json || error_exit "Failed to replace package.json."
  fi

  corepack prepare $pm@$pm_version --activate ||
    error_exit "Failed to prepare Corepack for $pm@$pm_version."

  if [[ "$pm" == "npm" ]]; then
    npm install --legacy-peer-deps || error_exit "npm install failed."
  else
    $pm install || error_exit "$pm install failed."
  fi
else
  $pm install || error_exit "$pm install failed."
fi
