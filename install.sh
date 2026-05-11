#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles_backup/$(date +%Y%m%d_%H%M%S)"

# Какой shell ставить:
#   --bash | --zsh | --both — явный выбор
#   без флага — текущий $SHELL
SHELL_CHOICE=""
case "${1:-}" in
  --bash) SHELL_CHOICE="bash" ;;
  --zsh)  SHELL_CHOICE="zsh" ;;
  --both) SHELL_CHOICE="both" ;;
  "")
    case "$(basename "${SHELL:-bash}")" in
      zsh)  SHELL_CHOICE="zsh" ;;
      *)    SHELL_CHOICE="bash" ;;
    esac
    ;;
  -h|--help)
    echo "Использование: $0 [--bash|--zsh|--both]"
    echo "По умолчанию выбирается shell из \$SHELL ($SHELL)."
    exit 0
    ;;
  *)
    echo "Неизвестный аргумент: $1" >&2
    exit 1
    ;;
esac

# Общие симлинки (нужны обоим shell)
declare -A LINKS=(
  ["$DOTFILES_DIR/aliases"]="$HOME/.aliases"
  ["$DOTFILES_DIR/scripts"]="$HOME/.scripts"
  ["$DOTFILES_DIR/shell"]="$HOME/.shell"
)

case "$SHELL_CHOICE" in
  bash)
    LINKS["$DOTFILES_DIR/bashrc"]="$HOME/.bashrc"
    LINKS["$DOTFILES_DIR/bash"]="$HOME/.bash"
    ;;
  zsh)
    LINKS["$DOTFILES_DIR/zshrc"]="$HOME/.zshrc"
    LINKS["$DOTFILES_DIR/zsh"]="$HOME/.zsh"
    ;;
  both)
    LINKS["$DOTFILES_DIR/bashrc"]="$HOME/.bashrc"
    LINKS["$DOTFILES_DIR/bash"]="$HOME/.bash"
    LINKS["$DOTFILES_DIR/zshrc"]="$HOME/.zshrc"
    LINKS["$DOTFILES_DIR/zsh"]="$HOME/.zsh"
    ;;
esac

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
echo "Shell: $SHELL_CHOICE"
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

# macOS: проверка наличия Homebrew, рекомендация если нет
if [ "$(uname -s)" = "Darwin" ] && ! command -v brew >/dev/null 2>&1; then
  echo
  echo "⚠ macOS обнаружен, но Homebrew не установлен."
  echo "  Поставь его перед использованием pkg-алиасов и install-modern-tools:"
  echo '  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
fi

echo
echo "Готово. Перезапустите терминал или выполните:"
case "$SHELL_CHOICE" in
  bash) echo "  source ~/.bashrc" ;;
  zsh)  echo "  source ~/.zshrc" ;;
  both) echo "  source ~/.bashrc  # или  source ~/.zshrc" ;;
esac
