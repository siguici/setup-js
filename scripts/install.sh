#!/bin/bash

if [[ ! -f "package.json" ]]; then
  echo "❌ No package.json found in current working directory."
  exit 1
fi

if ! command -v corepack &> /dev/null; then
  echo "❌ Corepack is not installed. Please install it and try again."
  exit 1
fi

if ! command -v jq &> /dev/null; then
  echo "❌ jq is not installed. Please install it and try again."
  exit 1
fi

echo "⚙️ Installing $pm dependencies"
if [[ "${runtime}" == "node" ]]; then
  corepack enable

  if [[ "$pm" == "yarn" ]]; then
    echo "ℹ️ Preparing package.json for Yarn..."

    if [[ "$pm_version" == "latest" ]]; then
      pm_version=$(yarn --version)
    fi
 
    echo "ℹ️ Defining the 'packageManager' field to 'yarn@$pm_version'..."
    jq ".packageManager = \"yarn@$pm_version\"" package.json > yarn-package.json

    mv package.json package.json.bak
    mv yarn-package.json package.json
  fi

  corepack prepare $pm@$pm_version --activate

  if [[ "$pm" == "npm" ]]; then
    npm install --legacy-peer-deps
  else
    $pm install
  fi
else
  $pm install
fi
