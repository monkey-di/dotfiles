#!/usr/bin/env bash
# Описание: Загружает файлы на Google Drive через rclone, получает публичную ссылку и кладёт её в буфер обмена
# Использование: gdup [-f папка] <файл> [<файл>...]
# Зависимости: rclone, pbcopy (macOS) или wl-copy/xclip (Linux)
# Категория: content

set -uo pipefail

# shellcheck source=lib-os.sh
source "$(dirname "$(readlink -f "$0")")/lib-os.sh"

REMOTE="gdrive"
FOLDER="Uploads"

usage() {
    echo "Использование: $(basename "$0") [-f папка] ФАЙЛ [ФАЙЛ...]"
    echo "  -f папка   путь на ${REMOTE}: (по умолчанию: ${FOLDER})"
    exit 1
}

while getopts ":f:h" opt; do
    case "$opt" in
        f) FOLDER="$OPTARG" ;;
        h|*) usage ;;
    esac
done
shift $((OPTIND - 1))

[[ $# -ge 1 ]] || usage

DEST="${REMOTE}:${FOLDER%/}/"
LOG="$(mktemp -t gdrive-upload.XXXXXX.log)"
LINKS=()
FAILED=()

for FILE in "$@"; do
    if [[ ! -f "$FILE" ]]; then
        echo "Пропущено (не файл): $FILE" >&2
        FAILED+=("$FILE")
        continue
    fi
    NAME="$(basename "$FILE")"
    if rclone copy "$FILE" "$DEST" --quiet 2>>"$LOG"; then
        URL="$(rclone link "${DEST}${NAME}" 2>>"$LOG" || true)"
        if [[ "$URL" =~ ^https?:// ]]; then
            LINKS+=("$URL")
            echo "$NAME → $URL"
        else
            echo "Загружен, но ссылку получить не удалось: $NAME" >&2
            FAILED+=("$FILE")
        fi
    else
        echo "Ошибка загрузки: $FILE (см. $LOG)" >&2
        FAILED+=("$FILE")
    fi
done

if [[ ${#LINKS[@]} -gt 0 ]]; then
    printf '%s\n' "${LINKS[@]}" | _clip || true
    if [[ ${#LINKS[@]} -eq 1 ]]; then
        _notify "Загружено в Google Drive" "${LINKS[0]}"
    else
        _notify "Загружено в Google Drive" "Файлов: ${#LINKS[@]} (ссылки в буфере)"
    fi
fi

if [[ ${#FAILED[@]} -gt 0 ]]; then
    _notify "Не загружено" "Файлов: ${#FAILED[@]} (см. $LOG)"
    exit 1
fi

rm -f "$LOG"
