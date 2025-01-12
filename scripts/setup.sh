#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

os=${os:-""}
os_version=${os_version:-""}
os_architecture=${os_architecture:-""}
os_cpu=${os_cpu:-""}
os_kernel=${os_kernel:-""}
os_hostname=${os_hostname:-""}
os_uptime=${os_uptime:-""}
runtime=${runtime:-""}
pm=${pm:-""}
pm_version=${pm_version:-"latest"}
pm_lockfile=${pm_lockfile:-"none"}

parse_pm() {
  local input=$1
  local name=$(echo "$input" | grep -o '^[^@]*')
  local version=$(echo "$input" | grep -o '@.*' | sed 's/^@//' || echo "latest")
  echo "$name $version"
}

detect_os() {
  if [ -z "$os" ]; then
    case "$OSTYPE" in
      darwin*)
        os="macOS"
        os_version=$(sw_vers -productVersion)
        os_cpu=$(sysctl -n machdep.cpu.brand_string)
      ;;
      linux-gnu*)
        os="Linux"
        os_version=$(lsb_release -rs 2>/dev/null || echo "$(uname -r)")
        os_cpu=$(lscpu | grep 'Model name' | cut -d ':' -f2 | xargs)
      ;;
      msys*|cygwin*|win32*)
        os="Windows"
        os_version=$(powershell -Command "(Get-CimInstance -Class Win32_OperatingSystem).Version")
        os_cpu=$(powershell -Command "(Get-CimInstance -Class Win32_Processor).Name")
      ;;
      *)
        os="Unknown"
        os_version="Unknown"
        os_cpu="Unknown"
      ;;
    esac

    if [[ "$os" == "macOS" || "$os" == "Linux" ]]; then
      os_uptime=$(cat /proc/uptime 2>/dev/null | awk '{print $1}' || uptime | awk -F'( |,|:)+' '{print $3*3600 + $4*60 + $5}')
    elif [[ "$os" == "Windows" ]]; then
      os_uptime=$(powershell -Command "(Get-CimInstance -Class Win32_OperatingSystem).LastBootUpTime")
    else
      echo "Unknown"
    fi

    os_architecture=$(uname -m)
    os_kernel=$(uname -s)$(uname -r)
    os_hostname=$(hostname)
  fi
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

os_info(){
  case "$os" in
    "macOS") echo -e "$MACOS detected..." ;;
    "Linux") echo -e "$LINUX detected..." ;;
    "Windows")
      if grep -q Microsoft /proc/version 2>/dev/null; then
        echo -e "$WINDOWS Subsystem for $LINUX (WSL) detected..."
      else
        echo -e "$WINDOWS detected..."
      fi
      ;;
    *) echo -e "$UNKNOWN OS, type: $OSTYPE" ;;
  esac
  
  echo "OS: $os"
  echo "OS Version: $os_version"
  echo "OS Architecture: $os_architecture"
  echo "OS CPU: $os_cpu"
  echo "OS Kernel: $os_kernel"
  echo "OS Hostname: $os_hostname"
  echo "OS Uptime: $os_uptime"
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
  echo "os=$os"
  echo "os_version=$os_version"
  echo "os_architecture=$os_architecture"
  echo "os_cpu=$os_cpu"
  echo "os_kernel=$os_kernel"
  echo "os_hostname=$os_hostname"
  echo "os_uptime=$os_uptime"
  echo "runtime=$runtime"
  echo "pm=$pm"
  echo "pm_version=$pm_version"
  echo "pm_lockfile=$pm_lockfile"
} >> "$GITHUB_ENV"
