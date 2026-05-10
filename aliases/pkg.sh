#!/bin/bash
# Описание: Универсальные алиасы управления пакетами для Arch (paru/pacman) и Ubuntu/Debian (apt)
# Категория: pkg

if [ -f /etc/os-release ]; then
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
