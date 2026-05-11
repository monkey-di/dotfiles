#!/bin/bash
# Описание: Универсальные алиасы управления пакетами для Arch (paru/pacman), Debian/Ubuntu (apt) и macOS (brew)
# Категория: pkg

if [ "${DOTFILES_OS:-}" = "mac" ]; then
  alias install='brew install'
  alias remove='brew uninstall'
  alias search='brew search'
  alias update='brew update && brew upgrade'
elif [ -f /etc/os-release ]; then
  . /etc/os-release
  case "$ID" in
    arch|endeavouros|manjaro)
      _pkg=$(command -v paru &>/dev/null && echo paru || echo 'sudo pacman')
      alias install="$_pkg -S --noconfirm"
      alias remove="$_pkg -Rns"
      alias search="$_pkg -Ss"
      alias update="$_pkg -Syu --noconfirm"
      ;;
    ubuntu|debian|linuxmint|pop)
      alias install='sudo apt install'
      alias remove='sudo apt remove'
      alias search='apt search'
      alias update='sudo apt update && sudo apt upgrade'
      ;;
  esac
  unset _pkg
fi
