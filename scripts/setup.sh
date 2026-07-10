#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

runtime=${runtime:-""}
cwd=${cwd:-"."}
pm=${pm:-""}
pm_version=${pm_version:-"latest"}
pm_lockfile=${pm_lockfile:-"none"}
os=${os:-""}
os_name=${os_name:-"$os"}
os_version=${os_version:-""}
os_arch=${os_arch:-""}

parse_pm() {
  local input=$1
  local name
  local version
  name=$(echo "$input" | grep -o '^[^@]*')
  version=$(echo "$input" | grep -o '@.*' | sed 's/^@//' || echo "latest")
  echo "$name $version"
}

detect_runtime() {
  if [ -z "$runtime" ]; then
    if [ -f "$cwd/deno.json" ] || [ -f "$cwd/deno.jsonc" ]; then
      runtime="deno"
    elif [ -f "$cwd/bun.lock" ] || [ -f "$cwd/bun.lockb" ]; then
      runtime="bun"
    elif command -v bun &>/dev/null; then
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
    valid_pms=("npm" "yarn" "pnpm" "bun" "deno" "nub")
    if [[ ! " ${valid_pms[@]} " =~ " $pm " ]]; then
      panic "Invalid package manager '$pm'. Valid options are: ${valid_pms[*]}."
    fi
  elif [ -f "$cwd/package.json" ]; then
    local pkg_manager=$(jq -r '.packageManager // empty' "$cwd/package.json" 2>/dev/null || true)
    if [ -n "$pkg_manager" ]; then
      read -r pm pm_version <<< "$(parse_pm "$pkg_manager")"
    fi
  fi

  local detected_lock=""
  if [ -f "$cwd/bun.lock" ]; then detected_lock="bun.lock"; [ -z "$pm" ] && pm="bun"; fi
  if [ -f "$cwd/bun.lockb" ]; then detected_lock="bun.lockb"; [ -z "$pm" ] && pm="bun"; fi
  if [ -f "$cwd/deno.lock" ]; then detected_lock="deno.lock"; [ -z "$pm" ] && pm="deno"; fi
  if [ -f "$cwd/lock.yaml" ]; then detected_lock="lock.yaml"; [ -z "$pm" ] && pm="nub"; fi
  if [ -f "$cwd/pnpm-lock.yaml" ]; then detected_lock="pnpm-lock.yaml"; [ -z "$pm" ] && pm="pnpm"; fi
  if [ -f "$cwd/yarn.lock" ]; then detected_lock="yarn.lock"; [ -z "$pm" ] && pm="yarn"; fi
  if [ -f "$cwd/package-lock.json" ]; then detected_lock="package-lock.json"; [ -z "$pm" ] && pm="npm"; fi

  local search_dir="$cwd"
  while [[ "$search_dir" != "." && "$search_dir" != "/" ]]; do
    if [ -f "$search_dir/pnpm-lock.yaml" ]; then detected_lock="pnpm-lock.yaml"; pm="pnpm"; break; fi
    if [ -f "$search_dir/yarn.lock" ]; then detected_lock="yarn.lock"; pm="yarn"; break; fi
    if [ -f "$search_dir/package-lock.json" ]; then detected_lock="package-lock.json"; pm="npm"; break; fi
    search_dir=$(dirname "$search_dir")
  done

  pm="${pm:-$runtime}"
  pm="${pm//node/npm}"
  pm=${pm:-"npm"}

  if [ -n "$detected_lock" ]; then
    pm_lockfile="$cwd/$detected_lock"
  else
    pm_lockfile=""
  fi
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
      *) os="$OSTYPE" ;;
    esac
  fi

  if [ -n "$os_name" ]; then
    if [[ "$os" =~ ^([a-zA-Z0-9\-]+)-([0-9\.]+)$ ]]; then
      os_name="${BASH_REMATCH[1]}"
    elif [[ "$os" =~ ^([a-zA-Z0-9\-]+)-latest$ ]]; then
      os_name="${BASH_REMATCH[1]}"
    fi

    case "${os_name,,}" in
      ubuntu) os_name="Ubuntu" ;;
      macos) os_name="macOS" ;;
      windows) os_name="Windows" ;;
    esac
  fi

  if [[ "$os" == "darwin" ]]; then
    os_name=${os_name:-"macOS"}
    os_version=$(sw_vers -productVersion)
  elif [[ "$os" == "linux" ]]; then
    if [ -f "/etc/os-release" ]; then
      os_name=$(grep '^NAME=' /etc/os-release | cut -d '=' -f 2 | tr -d '"')
      os_version=$(grep '^VERSION_ID=' /etc/os-release | cut -d '=' -f 2 | tr -d '"')
    else
      os_name=${os_name:-"Generic"}
      if command -v lsb_release >/dev/null 2>&1; then
        os_version=$(lsb_release -rs 2>/dev/null || echo "$(uname -r)")
      else
        os_version=$(cat /etc/issue | grep -oP 'Ubuntu \K[0-9]+\.[0-9]+' 2>/dev/null || echo "$(uname -r)")
      fi
    fi
  elif [[ "$os" == "windows" ]]; then
    os_name=${os_name:-"Windows"}
    os_version=$(cmd.exe /c ver 2>/dev/null | grep -oP 'Version \K[0-9\.]+' || powershell -Command "(Get-CimInstance -Class Win32_OperatingSystem).Version" 2>/dev/null || echo "10.0")
  else
    os_name=${os_name:-"Unknown"}
    os_version="unknown"
  fi

  normalize_arch "$(uname -m)"
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
    *) OS="$UNKNOWN $os" ;;
  esac

  echo -e "$OS ($os_name $os_version, $os_arch)"
}

detect_runtime
detect_pm
detect_os

if [[ "$pm" == "$runtime" ]]; then
  info "Using $runtime"
else
  info "$pm@$pm_version under $runtime"
fi

if [ -n "$pm_lockfile" ]; then
  info "Lockfile: $pm_lockfile"
fi

os_info

if [[ -w "$GITHUB_ENV" ]]; then
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
else
  panic "Failed to write to $GITHUB_ENV."
fi
