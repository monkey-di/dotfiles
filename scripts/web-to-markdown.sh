#!/usr/bin/env bash
# Описание: Сохранение веб-страницы как markdown через trafilatura (выделяет основную статью без шапок/футеров)
# Использование: web-to-markdown <url> [имя-файла] [-d каталог]
# Зависимости: trafilatura, curl
# Категория: content

set -euo pipefail

DIR="$PWD"
URL=""
FILENAME=""

while [ $# -gt 0 ]; do
  case "$1" in
    -d | --dir)
      DIR="$2"
      shift 2
      ;;
    -h | --help)
      echo "Использование: web-to-markdown.sh <url> [имя-файла] [-d каталог]"
      exit 0
      ;;
    *)
      if [ -z "$URL" ]; then
        URL="$1"
      elif [ -z "$FILENAME" ]; then
        FILENAME="$1"
      else
        echo "Лишний аргумент: $1" >&2
        exit 1
      fi
      shift
      ;;
  esac
done

if [ -z "$URL" ]; then
  echo "Использование: web-to-markdown.sh <url> [имя-файла] [-d каталог]"
  exit 1
fi

if [ -z "$FILENAME" ]; then
  TITLE=$(curl -sL "$URL" | grep -oP '(?<=<title>)[^<]+' | head -1 | sed 's/[\/\\:*?"<>|]/-/g' | cut -c1-80)
  FILENAME="${TITLE:-$(date +%Y-%m-%d-%H%M%S)}"
fi

DATE=$(date +%Y-%m-%d)
OUTPUT="$DIR/$FILENAME.md"

# Извлекаем основную статью и конвертируем в markdown
{
  echo "# $FILENAME"
  echo ""
  echo "**Источник:** $URL"
  echo "**Сохранено:** $DATE"
  echo ""
  echo "---"
  echo ""
  trafilatura -u "$URL" \
    --output-format markdown \
    --no-comments \
    --links 2>/dev/null \
    || echo "Не удалось извлечь содержимое страницы."
} >"$OUTPUT"

if [ -s "$OUTPUT" ]; then
  echo "Сохранено: $OUTPUT"
else
  rm -f "$OUTPUT"
  echo "Не удалось сохранить."
  exit 1
fi
