#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles_backup/$(date +%Y%m%d_%H%M%S)"

# Файлы и директории для симлинков: источник -> цель
declare -A LINKS=(
  ["$DOTFILES_DIR/bashrc"]="$HOME/.bashrc"
  ["$DOTFILES_DIR/aliases"]="$HOME/.aliases"
  ["$DOTFILES_DIR/bash"]="$HOME/.bash"
  ["$DOTFILES_DIR/scripts"]="$HOME/.scripts"
)

backup_and_link() {
  local src="$1"
  local dst="$2"

  if [ -L "$dst" ]; then
    local current
    current="$(readlink "$dst")"
    if [ "$current" = "$src" ]; then
      echo "  [skip] $dst -> $src (уже установлен)"
      return
    fi
    echo "  [backup] удаляю старый симлинк $dst -> $current"
    mkdir -p "$BACKUP_DIR"
    mv "$dst" "$BACKUP_DIR/$(basename "$dst")"
  elif [ -e "$dst" ]; then
    echo "  [backup] $dst -> $BACKUP_DIR/"
    mkdir -p "$BACKUP_DIR"
    mv "$dst" "$BACKUP_DIR/$(basename "$dst")"
  fi

  ln -s "$src" "$dst"
  echo "  [link]  $dst -> $src"
}

echo "Установка дотфайлов из $DOTFILES_DIR"
echo

for src in "${!LINKS[@]}"; do
  backup_and_link "$src" "${LINKS[$src]}"
done

echo
if [ -d "$BACKUP_DIR" ]; then
  echo "Бэкапы сохранены в $BACKUP_DIR"
else
  echo "Бэкапы не потребовались."
fi
echo "Готово. Перезапустите терминал или выполните: source ~/.bashrc"
