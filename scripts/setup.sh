#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

runtime=${runtime:-""}
pm=${pm:-""}
pm_version=${pm_version:-"latest"}
pm_lockfile=${pm_lockfile:-"none"}
os=${os:-""}
os_name=${os_name:-""}
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

detect_pm() {
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

normalize_arch() {
  case "$1" in
    x86_64|amd64) os_arch="x64" ;;
    i386|i686) os_arch="x86" ;;
    armv7*|armhf) os_arch="arm" ;;
    aarch64|arm64) os_arch="arm64" ;;
    riscv64) os_arch="riscv64" ;;
    *) os_arch="unknown" ;;
  esac
}

detect_os() {
  if [ -z "$os" ]; then
    case "$OSTYPE" in
      darwin*) os="darwin" ;;
      linux*) os="linux" ;;
      msys*|cygwin*|win32*) os="windows" ;;
      *) os="unknown" ;;
    esac
  fi

  if [[ "$os" == "darwin" ]]; then
    os_name="macOS"
    os_version=$(sw_vers -productVersion)
  elif [[ "$os" == "linux" ]]; then
    if [ -f "/etc/os-release" ]; then
      os_name=$(grep '^NAME=' /etc/os-release | cut -d '=' -f 2 | tr -d '"')
      os_version=$(grep '^VERSION_ID=' /etc/os-release | cut -d '=' -f 2 | tr -d '"')
    else
      os_name="Generic"
      os_version=$(lsb_release -rs 2>/dev/null || echo "$(uname -r)")
    fi
  elif [[ "$os" == "windows" ]]; then
    os_name="Windows"
    os_version=$(powershell -Command "(Get-CimInstance -Class Win32_OperatingSystem).Version")
  else
    os_name="Unknown"
    os_version="unknown"
  fi

  os_arch=$(normalize_arch $(uname -m))
}

os_info() {
  case "$os" in
    "darwin") OS="$DARWIN" ;;
    "linux")
      if grep -qi microsoft /proc/version 2>/dev/null; then
        OS="$WINDOWS Subsystem for $LINUX (WSL)"
      else
        OS="$LINUX"
      fi
      ;;
    "windows") OS="$WINDOWS" ;;
    *) OS="$UNKNOWN OS, type: $OSTYPE" ;;
  esac

  echo -e "$OS ($os_name $os_version, $os_arch)"
}

detect_runtime
detect_pm
detect_os

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
  echo "os_name=$os_name"
  echo "os_version=$os_version"
  echo "os_arch=$os_arch"
} >> "$GITHUB_ENV"
