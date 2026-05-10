#!/usr/bin/env bash
# Описание: Установка современных замен классических утилит (bat, eza, fd, ripgrep, btop, dust, duf) для алиасов из modern.sh
# Использование: install-modern-tools
# Зависимости: paru/pacman (Arch) или apt (Debian/Ubuntu)
# Категория: system

set -euo pipefail

if [ ! -f /etc/os-release ]; then
  echo "Не могу определить ОС: /etc/os-release не найден"
  exit 1
fi

. /etc/os-release

case "$ID" in
  arch|endeavouros|manjaro)
    PKGS=(bat eza fd ripgrep btop dust duf)
    if command -v paru &>/dev/null; then
      paru -S --needed --noconfirm "${PKGS[@]}"
    else
      sudo pacman -S --needed --noconfirm "${PKGS[@]}"
    fi
    ;;
  ubuntu|debian|linuxmint|pop)
    # На Debian/Ubuntu: bat → пакет bat (бинарь batcat), fd → пакет fd-find (бинарь fdfind)
    # eza, dust, duf могут отсутствовать в старых репозиториях — устанавливаем что есть
    sudo apt update
    sudo apt install -y bat fd-find ripgrep btop duf || true
    # eza обычно ставится из их официального репозитория — здесь пропускаем,
    # см. https://github.com/eza-community/eza/blob/main/INSTALL.md
    if ! command -v eza &>/dev/null; then
      echo "eza: не установлен. Установка из исходников/репозитория — см. документацию eza."
    fi
    if ! command -v dust &>/dev/null; then
      echo "dust: не установлен. Поставь через cargo: cargo install du-dust"
    fi
    ;;
  *)
    echo "Неподдерживаемая ОС: $ID"
    exit 1
    ;;
esac

echo
echo "Готово. Перезапусти терминал или выполни: source ~/.bashrc"
