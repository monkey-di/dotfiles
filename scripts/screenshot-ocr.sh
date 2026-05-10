#!/usr/bin/env bash
# Описание: Снимок выделенной области экрана → OCR → текст в буфер обмена
# Использование: screenshot-ocr [-l rus|eng|rus+eng]
# Зависимости: tesseract (+ tesseract-data-rus/eng), grim+slurp (Wayland) или maim (X11), wl-copy или xclip
# Категория: media

set -euo pipefail

lang="rus+eng"
while [ $# -gt 0 ]; do
  case "$1" in
    -l) lang="$2"; shift 2 ;;
    -h|--help) sed -n '2,5p' "$0"; exit 0 ;;
    *) echo "Неизвестный аргумент: $1" >&2; exit 1 ;;
  esac
done

if ! command -v tesseract &>/dev/null; then
  echo "Ошибка: нужен tesseract (sudo pacman -S tesseract tesseract-data-rus tesseract-data-eng)" >&2
  exit 1
fi

img=$(mktemp --suffix=.png)
trap 'rm -f "$img"' EXIT

# Снимок области: сначала пробуем Wayland (grim+slurp), потом X11 (maim)
if [ "${XDG_SESSION_TYPE:-}" = "wayland" ] && command -v grim &>/dev/null && command -v slurp &>/dev/null; then
  grim -g "$(slurp)" "$img"
elif command -v maim &>/dev/null; then
  maim -s "$img"
else
  echo "Ошибка: нужен grim+slurp (Wayland) или maim (X11)" >&2
  exit 1
fi

# OCR → текст
text=$(tesseract "$img" - -l "$lang" 2>/dev/null)

if [ -z "$text" ]; then
  echo "Ничего не распознано" >&2
  exit 1
fi

# Копирование в буфер: wl-copy для Wayland, xclip для X11
if command -v wl-copy &>/dev/null && [ "${XDG_SESSION_TYPE:-}" = "wayland" ]; then
  printf '%s' "$text" | wl-copy
elif command -v xclip &>/dev/null; then
  printf '%s' "$text" | xclip -selection clipboard
fi

echo "$text"
echo "---"
echo "✓ скопировано в буфер обмена"
