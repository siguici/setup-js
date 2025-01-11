#!/usr/bin/env bash

if [[ "$OSTYPE" == "darwin"* ]]; then
  echo "Running on macOS... 💻"
  if ((BASH_VERSINFO[0] < 4)); then
    echo "⬆️Update Bash..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    brew install bash
    echo "📌 Bash version : $(bash --version)"
  fi
else
  echo "No Bash update required for $OSTYPE 😊"
fi
