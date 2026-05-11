#!/usr/bin/env bash
# Описание: Определение ОС и shell. Экспортирует DOTFILES_OS и DOTFILES_SHELL.
# Категория: shell

# Linux | Darwin (mac) | прочее
case "$(uname -s)" in
  Linux*)  export DOTFILES_OS="linux" ;;
  Darwin*) export DOTFILES_OS="mac" ;;
  *)       export DOTFILES_OS="other" ;;
esac

# bash | zsh — по shell-специфичным переменным версии
if [ -n "${BASH_VERSION:-}" ]; then
  export DOTFILES_SHELL="bash"
elif [ -n "${ZSH_VERSION:-}" ]; then
  export DOTFILES_SHELL="zsh"
else
  export DOTFILES_SHELL="sh"
fi

# Кросс-платформенная команда «положить stdin в буфер обмена».
# Использование: echo hello | clip
clip() {
  case "$DOTFILES_OS" in
    mac)
      pbcopy
      ;;
    linux)
      if [ "${XDG_SESSION_TYPE:-}" = "wayland" ] && command -v wl-copy &>/dev/null; then
        wl-copy
      elif command -v xclip &>/dev/null; then
        xclip -selection clipboard
      else
        return 1
      fi
      ;;
    *) return 1 ;;
  esac
}
