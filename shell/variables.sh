#!/usr/bin/env bash
# Описание: Переменные окружения и PATH (общие для bash/zsh, кросс-платформенно)
# Категория: shell

export CLAUDE_CODE_NO_FLICKER=1   # скролл в claude code

export PATH="$HOME/.scripts:$PATH"
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.npm-global/bin:$PATH"

# Homebrew (macOS): добавляем brew prefix в PATH если он есть
if [ "$DOTFILES_OS" = "mac" ]; then
  if [ -x /opt/homebrew/bin/brew ]; then        # Apple Silicon
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [ -x /usr/local/bin/brew ]; then          # Intel
    eval "$(/usr/local/bin/brew shellenv)"
  fi
fi

export VISUAL="micro"

# Браузер: xdg-open на Linux, `open` на macOS
case "$DOTFILES_OS" in
  mac)   export BROWSER="open" ;;
  linux) export BROWSER="xdg-open" ;;
esac
