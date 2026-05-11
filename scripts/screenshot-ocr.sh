#!/usr/bin/env bash
# Описание: Снимок выделенной области экрана → OCR → текст в буфер обмена
# Использование: screenshot-ocr [-l rus|eng|rus+eng]
# Зависимости: tesseract (+ tesseract-data-rus/eng); grim+slurp (Wayland), maim (X11) или screencapture (macOS); pbcopy/wl-copy/xclip
# Категория: media

set -euo pipefail

# shellcheck source=lib-os.sh
source "$(dirname "$(readlink -f "$0")")/lib-os.sh"

lang="rus+eng"
while [ $# -gt 0 ]; do
  case "$1" in
    -l) lang="$2"; shift 2 ;;
    -h|--help) sed -n '2,5p' "$0"; exit 0 ;;
    *) echo "Неизвестный аргумент: $1" >&2; exit 1 ;;
  esac
done

if ! command -v tesseract &>/dev/null; then
  echo "Ошибка: нужен tesseract" >&2
  echo "  Arch:   sudo pacman -S tesseract tesseract-data-rus tesseract-data-eng" >&2
  echo "  Debian: sudo apt install tesseract-ocr tesseract-ocr-rus tesseract-ocr-eng" >&2
  echo "  macOS:  brew install tesseract tesseract-lang" >&2
  exit 1
fi

img=$(mktemp -t screenshot-ocr.XXXXXX).png
trap 'rm -f "$img"' EXIT

# Снимок области экрана
case "$(uname -s)" in
  Darwin)
    # -i интерактивный выбор; -x без звука затвора
    screencapture -i -x "$img"
    [ -s "$img" ] || { echo "Снимок отменён" >&2; exit 1; }
    ;;
  Linux)
    if [ "${XDG_SESSION_TYPE:-}" = "wayland" ] && command -v grim &>/dev/null && command -v slurp &>/dev/null; then
      grim -g "$(slurp)" "$img"
    elif command -v maim &>/dev/null; then
      maim -s "$img"
    else
      echo "Ошибка: нужен grim+slurp (Wayland) или maim (X11)" >&2
      exit 1
    fi
    ;;
  *)
    echo "Неподдерживаемая ОС: $(uname -s)" >&2
    exit 1
    ;;
esac

# OCR → текст
text=$(tesseract "$img" - -l "$lang" 2>/dev/null)

if [ -z "$text" ]; then
  echo "Ничего не распознано" >&2
  exit 1
fi

printf '%s' "$text" | _clip || true

echo "$text"
echo "---"
echo "✓ скопировано в буфер обмена"
