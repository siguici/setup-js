#!/usr/bin/env bash

set -eEuo pipefail

trap 'handle_error $LINENO "$BASH_COMMAND" $?' ERR

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/messages.ini"

DEBUG=${DEBUG:-false}

declare -A script_messages=(
  ["test"]=$TEST_MESSAGE
  ["lint"]=$LINT_MESSAGE
  ["format"]=$FORMAT_MESSAGE
  ["check"]=$CHECK_MESSAGE
  ["build"]=$BUILD_MESSAGE
  ["ci"]=$CI_MESSAGE
  ["deploy"]=$DEPLOY_MESSAGE
  ["release"]=$RELEASE_MESSAGE
)

log() {
  local level="$1"
  local message="$2"
  case "$level" in
    DEBUG) [ "$DEBUG" = true ] && echo -e "🐞 $message" >&2 ;;
    INFO) echo -e "ℹ️ $message" ;;
    WARNING) echo -e "⚠️ $message" >&2 ;;
    ERROR) echo -e "❌ $message" >&2 ;;
    SUCCESS) echo -e "✔  $message" ;;
    *) echo "🚫 Unknown log level: $level" >&2 ;;
  esac
}

debug() { log "DEBUG" "$*"; }
info() { log "INFO" "$*"; }
warning() { log "WARNING" "$*"; }
error() { log "ERROR" "$*"; }
success() { log "SUCCESS" "$*"; }
panic() {
  error "$1"
  exit "${2:-1}"
}

handle_error() {
  local lineno="$1"
  local cmd="$2"
  local exit_code="$3"

  error "$(date +'%Y-%m-%d %H:%M:%S') [$0] Error:"

  case $exit_code in
    1) warning "Incorrect command: '$cmd' failed at line $lineno." ;;
    127) warning "Command not found: '$cmd' at line $lineno." ;;
    *) warning "Unexpected error: '$cmd' failed at line $lineno with exit code $exit_code." ;;
  esac

  exit "$exit_code"
}

get_message() {
  local script="$1"

  for key in "${!script_messages[@]}"; do
    if [[ "$script" == $key || "$script" == $key:* || "$script" == $key.* || "$script" == *:$key || "$script" == *.$key ]]; then
      echo "${script_messages[$key]} ($script)"
      return
    fi
  done

  echo "🔨 Running $script"
}

message() {
  echo "$(get_message "$1...")"
}
