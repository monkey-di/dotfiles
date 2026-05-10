#!/usr/bin/env bash
# Описание: Конвертация markdown → docx со стилизацией по референсу и опциональной выгрузкой в Google Drive
# Использование: md2docx <input.md> [output.docx] [-r <reference.docx>] [-u]
# Примеры:
#   md2docx article.md
#   md2docx article.md out.docx -r my-style.docx
#   md2docx article.md -u
# Зависимости: pandoc, rclone (для -u), xclip или wl-copy
# Категория: content

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
REFERENCE="${PANDOC_REFERENCE_DOC:-$SCRIPT_DIR/reference/pandoc-reference.docx}"
REMOTE_DIR="${MD2DOCX_REMOTE_DIR:-gdrive:Documents/}"
INPUT=""
OUTPUT=""
UPLOAD=0

while [ $# -gt 0 ]; do
  case "$1" in
    -r | --reference)
      REFERENCE="$2"
      shift 2
      ;;
    -u | --upload)
      UPLOAD=1
      shift
      ;;
    -h | --help)
      echo "Использование: md2docx <input.md> [output.docx] [-r <reference.docx>] [-u]"
      exit 0
      ;;
    *)
      if [ -z "$INPUT" ]; then
        INPUT="$1"
      elif [ -z "$OUTPUT" ]; then
        OUTPUT="$1"
      else
        echo "Лишний аргумент: $1" >&2
        exit 1
      fi
      shift
      ;;
  esac
done

if [ -z "$INPUT" ]; then
  echo "Использование: md2docx <input.md> [output.docx] [-r <reference.docx>]"
  exit 1
fi

if [ -z "$OUTPUT" ]; then
  BASE=$(basename "$INPUT")
  OUTPUT="$PWD/${BASE%.*}.docx"
fi

if [ ! -f "$REFERENCE" ]; then
  echo "Reference doc не найден: $REFERENCE" >&2
  exit 1
fi

pandoc "$INPUT" \
  --from=markdown+pipe_tables+grid_tables \
  --to=docx \
  --reference-doc="$REFERENCE" \
  --output="$OUTPUT"

echo "Сохранено: $OUTPUT"

if [ "$UPLOAD" -eq 1 ]; then
  BASENAME=$(basename "$OUTPUT")
  if rclone copy "$OUTPUT" "$REMOTE_DIR" --quiet 2>/tmp/md2docx-upload.log; then
    URL=$(rclone link "${REMOTE_DIR%/}/$BASENAME" 2>>/tmp/md2docx-upload.log || true)
    if [[ "$URL" =~ ^https?:// ]]; then
      printf '%s' "$URL" | wl-copy 2>/dev/null || true
      command -v notify-send >/dev/null && notify-send "docx загружен в Google Drive" "$URL"
      echo "Ссылка: $URL"
      exit 0
    fi
  fi
  command -v notify-send >/dev/null && notify-send -u critical "Загрузка не удалась" "$OUTPUT (см. /tmp/md2docx-upload.log)"
  echo "Загрузка не удалась, см. /tmp/md2docx-upload.log" >&2
  exit 1
fi
