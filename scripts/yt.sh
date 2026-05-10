#!/usr/bin/env bash
# Описание: Извлечение транскрипта (субтитров) с YouTube-видео в текстовый файл
# Использование: yt <youtube-url> [имя-файла] [-d каталог]
# Зависимости: yt-dlp, jq
# Категория: content

set -uo pipefail

DIR="$PWD"
URL=""
CUSTOM_NAME=""

while [ $# -gt 0 ]; do
    case "$1" in
        -d|--dir)
            DIR="$2"
            shift 2
            ;;
        -h|--help)
            echo "Использование: yt <youtube-url> [имя-файла] [-d каталог]"
            exit 0
            ;;
        *)
            if [ -z "$URL" ]; then
                URL="$1"
            elif [ -z "$CUSTOM_NAME" ]; then
                CUSTOM_NAME="$1"
            else
                echo "Лишний аргумент: $1" >&2
                exit 1
            fi
            shift
            ;;
    esac
done

if [ -z "$URL" ]; then
    echo "Использование: yt <youtube-url> [имя-файла] [-d каталог]"
    exit 1
fi

# Предпочитаем свежую версию из pip, если есть
YTDLP=$(command -v ~/.local/bin/yt-dlp 2>/dev/null || command -v yt-dlp)

TITLE=$($YTDLP --no-warnings --get-title "$URL")
VIDEO_ID=$($YTDLP --no-warnings --get-id "$URL")
DATE=$(date +%Y-%m-%d)

if [ -n "$CUSTOM_NAME" ]; then
    SAFE_TITLE="$CUSTOM_NAME"
else
    SAFE_TITLE=$(echo "$TITLE" | sed 's/[\/\\:*?"<>|]/-/g' | cut -c1-80)
fi

OUTPUT="$DIR/$SAFE_TITLE.md"
TMPDIR=$(mktemp -d)

# Скачиваем что есть, игнорируем ошибки отдельных языков
$YTDLP --no-warnings --skip-download --write-subs --write-auto-subs \
    --sub-langs 'ru,ru.*,en,en.*' --sub-format json3 \
    -o '%(id)s.%(ext)s' "$URL" -P "$TMPDIR" 2>/dev/null || true

# Проверяем что хоть что-то скачалось
if ls "$TMPDIR"/*.json3 1>/dev/null 2>&1; then
    {
        echo "# $TITLE"
        echo ""
        echo "**Источник:** $URL"
        echo "**Video ID:** $VIDEO_ID"
        echo "**Сохранено:** $DATE"
        echo ""
        echo "---"
        echo ""
        # Берём первый json3 (предпочтительно ru)
        RU_FILE=$(ls "$TMPDIR"/*.ru.json3 "$TMPDIR"/*.ru-orig.json3 2>/dev/null | head -1)
        TARGET="${RU_FILE:-$(ls "$TMPDIR"/*.json3 | head -1)}"
        jq -r '.events[] | select(.segs) | .segs | map(.utf8) | join("")' "$TARGET" | \
            sed -E '
                # Убираем всё в квадратных скобках
                s/\[[^]]*\]//g
                s/^>>//
                # Нормализуем пробелы
                s/[[:space:]]+/ /g
                s/^ //
                s/ $//
            ' | \
            # Убираем пустые и дублирующиеся строки
            grep -v '^\s*$' | \
            awk '!seen[$0]++' | \
            # Склеиваем всё в абзацы: новый абзац только после .!?
            awk '
                {
                    if (length(prev) > 0) {
                        if (prev ~ /[.!?]$/) {
                            print prev
                            prev = $0
                        } else {
                            prev = prev " " $0
                        }
                    } else {
                        prev = $0
                    }
                }
                END { if (length(prev) > 0) print prev }
            '
    } > "$OUTPUT"

    rm -rf "$TMPDIR"
    echo "Сохранено: $OUTPUT"
else
    rm -rf "$TMPDIR"
    echo "Субтитры не найдены."
    exit 1
fi
