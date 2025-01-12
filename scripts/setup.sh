#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

runtime=${runtime:-""}
pm=${pm:-""}
pm_version=${pm_version:-"latest"}
pm_lockfile=${pm_lockfile:-"none"}
os=${os:-""}
os_version=${os_version:-""}
os_arch=${os_arch:-""}

parse_pm() {
  local input=$1
  local name=$(echo "$input" | grep -o '^[^@]*')
  local version=$(echo "$input" | grep -o '@.*' | sed 's/^@//' || echo "latest")
  echo "$name $version"
}

detect_runtime() {
  if [ -z "$runtime" ]; then
    if command -v bun &>/dev/null; then
      runtime="bun"
    elif command -v deno &>/dev/null; then
      runtime="deno"
    else
      runtime="node"
    fi
  fi
}

detect_package_manager() {
  if [ -n "$pm" ]; then
    read -r pm pm_version <<< "$(parse_pm "$pm")"
    valid_pms=("npm" "yarn" "pnpm" "bun" "deno")
    if [[ ! " ${valid_pms[@]} " =~ " $pm " ]]; then
      panic "Invalid package manager '$pm'. Valid options are: ${valid_pms[*]}."
    fi
  elif [ -f "package.json" ]; then
    local pkg_manager=$(jq -r '.packageManager // empty' package.json 2>/dev/null || true)
    if [ -n "$pkg_manager" ]; then
      read -r pm pm_version <<< "$(parse_pm "$pkg_manager")"
    fi
  fi

  case "$pm" in
    "" )
      [ -f "pnpm-lock.yaml" ] && pm="pnpm" && pm_lockfile="pnpm-lock.yaml"
      [ -f "yarn.lock" ] && pm="yarn" && pm_lockfile="yarn.lock"
      [ -f "package-lock.json" ] && pm="npm" && pm_lockfile="package-lock.json"
      [ -f "bun.lockb" ] && pm="bun" && pm_lockfile="bun.lockb"
      [ -f "deno.lock" ] && pm="deno" && pm_lockfile="deno.lock"
      ;;
  esac

  pm="${pm:-$runtime}"
  pm="${pm//node/npm}"
  pm=${pm:-"npm"}
}

detect_os() {
  if [ -z "$os" ]; then
    case "$OSTYPE" in
      darwin*) os="macOS" ;;
      linux-gnu*) os="Linux" ;;
      msys*|cygwin*|win32*) os="Windows" ;;
      *) os="Unknown" ;;
    esac
  fi

  if [[ "$os" == "macOS" ]]; then
    os_version=$(sw_vers -productVersion)
  elif [[ "$os" == "Linux" ]]; then
    os_version=$(lsb_release -rs 2>/dev/null || echo "$(uname -r)")
  elif [[ "$os" == "Windows" ]]; then
    os_version=$(powershell -Command "(Get-CimInstance -Class Win32_OperatingSystem).Version")
  else
    os_version="Unknown"
  fi

  os_arch=$(uname -m)
}

os_info(){
  case "$os" in
    "macOS") OS="$MACOS" ;;
    "Linux")
      if grep -qi microsoft /proc/version 2>/dev/null; then
        OS="$WINDOWS Subsystem for $LINUX (WSL)"
      else
        OS="$LINUX"
      fi
      ;;
    "Windows") OS="$WINDOWS" ;;
    *) OS="$UNKNOWN OS, type: $OSTYPE" ;;
  esac

  echo -e "$OS ($os_version, $os_arch)"
}

detect_os
detect_runtime
detect_package_manager

if [[ "$pm" == "$runtime" ]]; then
  info "Using $runtime"
else
  info "$pm@$pm_version detected with lockfile $pm_lockfile under $runtime"
fi

os_info

{
  echo "runtime=$runtime"
  echo "pm=$pm"
  echo "pm_version=$pm_version"
  echo "pm_lockfile=$pm_lockfile"
  echo "os=$os"
  echo "os_version=$os_version"
  echo "os_arch=$os_arch"
} >> "$GITHUB_ENV"
