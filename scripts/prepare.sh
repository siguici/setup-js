#!/usr/bin/env bash

set -eEuo pipefail
trap 's=$?; echo "$(date "+%Y-%m-%d %H:%M:%S") $0: $BASH_COMMAND error on line $LINENO with exit code $s" >&2; exit $s' ERR

detect_os() {
  case "$OSTYPE" in
    darwin*) echo "macOS";;
    linux-gnu*) echo "Linux";;
    msys*|cygwin*|win32*) echo "Windows";;
    *) echo "❌ Unsupported OS";;
  esac
}

install_homebrew() {
  if ! command -v brew &>/dev/null; then
    echo "📥 Installing Homebrew 🍻 (requires admin privileges)..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
}

install_chocolatey() {
  if ! command -v choco &>/dev/null; then
    echo "📥 Installing Chocolatey (requires admin privileges)..."
    powershell -NoProfile -ExecutionPolicy Bypass -Command \
      "Set-ExecutionPolicy Bypass -Scope Process -Force; \
      [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12; \
      iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))"
  fi
}

install_scoop() {
  if ! command -v choco &>/dev/null; then
  echo "📥 Installing Scoop (does not require admin privileges)..."
  powershell -NoProfile -ExecutionPolicy Bypass -Command \
    "Set-ExecutionPolicy RemoteSigned -Scope CurrentUser; \
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://get.scoop.sh'))"
  fi
}

install_homebrew() {
  if ! command -v brew &>/dev/null; then
    echo "📥 Installing Homebrew 🍻 (requires admin privileges)..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
}

apt_install() {
  echo "🔧 Installing $* on 🐧 Linux (requires sudo)..."
  sudo apt-get install -y "$@"
}

brew_install() {
  echo "🔧 Installing $* on 🍏 macOS via Homebrew..."
  brew install "$@"
}

scoop_install() {
  echo "🔧 Installing $* on 🪟 Windows via Scoop..."
  scoop install "$@"
}

choco_install() {
  echo "🔧 Installing $* on 🪟 Windows via Chocolatey..."
  choco install -y "$@"
}

install_on_mac() {
  install_homebrew
  brew_install $@
}

install_on_linux() {
  sudo apt-get update
  apt_install $@
}

install_on_windows() {
  install_scoop || install_chocolatey
  scoop_install $@ || choco_install $@ || {
    echo "❌ Unable to install dependencies on Windows." >&2
    exit 1
  }
}

install () {
  case "$os" in
    "macOS")
      install_on_mac $@
      ;;
    "Linux")
      install_on_linux $@
      ;;
    "Windows")
      install_on_windows $@
      ;;
    *)
      echo "Cannot install $* on $os. Please install it manually."
      ;;
  esac
}

install_dependencies() {
  for cmd in "$@"; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      echo "⚠️ Missing command: $cmd" >&2
      install $cmd
    fi
  done
}

update_bash() {
  local os
  os=$(detect_os)

  echo "⬆️ Updating Bash..."

  case "$os" in
    "macOS")
      install_on_mac bash
      ;;
    "Linux")
      install_on_linux bash
      ;;
    *)
      echo "No Bash update required for $os 😊"
      ;;
  esac
}

main() {
  local os
  os=$(detect_os)
  echo "💻 Detected system: $os"

  install_dependencies curl jq

  if ((BASH_VERSINFO[0] < 4)); then
    echo "🔄 Updating Bash to version 4+..."
    update_bash
  fi

  echo "✅ All dependencies installed"
  echo "📌 Bash version: $(bash --version)"
}

main "$@"
