#!/usr/bin/env bash

if [[ "$OSTYPE" == "darwin"* ]]; then
  echo "Running on macOS... 💻"
  if ((BASH_VERSINFO[0] < 4)); then
    
    if ! command -v brew &>/dev/null; then
      echo "Installing Homebrew 🍻..."
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi

    echo "⬆️Updating Bash..."
    brew install bash
    echo "📌 Bash version : $(bash --version)"
  fi
else
  echo "No Bash update required for $OSTYPE 😊"
fi
