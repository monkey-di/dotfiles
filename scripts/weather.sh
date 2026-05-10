#!/usr/bin/env bash
# Описание: Погода через wttr.in с автоопределением локации по публичному IP
# Использование: weather [город|координаты] [-f]
# Примеры:
#   weather
#   weather Moscow
#   weather "Saint Petersburg"
#   weather 55.75,37.61
#   weather -f
# Зависимости: curl
# Категория: info

set -euo pipefail

format="2"   # компактный однострочник: место + темп + ветер + влажность
location=""

while [ $# -gt 0 ]; do
  case "$1" in
    -f|--full) format=""; shift ;;
    -h|--help) sed -n '2,9p' "$0"; exit 0 ;;
    *) location="$1"; shift ;;
  esac
done

# Если локация не задана — wttr.in сам определит её по IP запроса.
# URL-кодируем пробелы.
loc_path="${location// /%20}"

# Локализация и метрика
qs="lang=ru&m"
[ -n "$format" ] && qs="${qs}&format=${format}"

curl -fsS --max-time 10 "https://wttr.in/${loc_path}?${qs}"
echo
