#!/usr/bin/env bash
# Описание: Скачивает шрифт из репозитория google/fonts и устанавливает его локально
# Использование: gfont <name>
# Примеры:
#   gfont "Oswald"
#   gfont "PT Sans Narrow"
# Зависимости: curl, jq
# Категория: system

set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Использование: gfont <font name>"
  exit 1
fi

NAME="$*"
SLUG=$(echo "$NAME" | tr '[:upper:]' '[:lower:]' | tr -d ' ')
DEST="$HOME/.local/share/fonts/$SLUG"

# Каталог в google/fonts может быть в ofl/, apache/ или ufl/
API="https://api.github.com/repos/google/fonts/contents"
LICENSES=(ofl apache ufl)

DIR_JSON=""
for lic in "${LICENSES[@]}"; do
  resp=$(curl -sf "$API/$lic/$SLUG") && {
    DIR_JSON="$resp"
    break
  } || true
done

if [ -z "$DIR_JSON" ]; then
  echo "Шрифт «$NAME» не найден в google/fonts (искал ofl/$SLUG, apache/$SLUG, ufl/$SLUG)" >&2
  exit 1
fi

mkdir -p "$DEST"

# Скачиваем все .ttf/.otf и OFL/LICENSE
mapfile -t URLS < <(echo "$DIR_JSON" | jq -r '.[] | select(.name | test("\\.(ttf|otf)$") or (ascii_downcase | test("ofl|license"))) | .download_url')

if [ ${#URLS[@]} -eq 0 ]; then
  echo "В каталоге не найдено .ttf/.otf файлов" >&2
  exit 1
fi

for url in "${URLS[@]}"; do
  fname=$(basename "$url" | sed 's/%5B/[/g; s/%5D/]/g')
  echo "  $fname"
  curl -sL -o "$DEST/$fname" "$url"
done

fc-cache -f >/dev/null
echo "Установлено в $DEST"
echo "Доступные начертания:"
fc-list | grep -i "^$DEST" | sed 's|.*: |    |'
