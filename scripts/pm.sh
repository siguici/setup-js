#!/bin/bash

if [ -z "$GITHUB_ENV" ]; then
  echo "❌ GITHUB_ENV is not defined. Provide a path to a writable file."
  exit 1
fi

if [ -n "$input_pm" ] && [ "${#input_pm}" -gt 1 ]; then
  pm=$(echo "$input_pm" | grep -o '^[^@]*')
  pm_version=$(echo "$input_pm" | grep -o '@.*' | sed 's/^@//' || echo "latest")

  [ -z "$pm_version" ] && pm_version="latest"

  if [[ ! "$pm" =~ ^(npm|yarn|pnpm|bun|deno)$ ]]; then
    echo "❌ Invalid package manager '$pm'. Valid options are npm, yarn, pnpm, bun, deno."
    exit 1
  fi
else
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
  else
    pm="npm"
    pm_lockfile="package-lock.json"
  fi

  pm_version="latest"
fi

echo "pm=$pm" >> "$GITHUB_ENV"
echo "pm_version=$pm_version" >> "$GITHUB_ENV"
echo "pm_lockfile=$pm_lockfile" >> "$GITHUB_ENV"
