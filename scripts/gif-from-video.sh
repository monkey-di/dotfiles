#!/usr/bin/env bash
# Описание: Конвертация видео в качественный gif через ffmpeg с двухпроходной генерацией палитры
# Использование: gif-from-video <input> [output.gif] [-f fps] [-w width] [-s start] [-t duration]
# Примеры:
#   gif-from-video screen.mp4
#   gif-from-video screen.mp4 demo.gif -f 15 -w 800
#   gif-from-video screen.mp4 -s 00:00:05 -t 10
# Зависимости: ffmpeg
# Категория: media

set -euo pipefail

if ! command -v ffmpeg &>/dev/null; then
  echo "Ошибка: нужен ffmpeg" >&2
  exit 1
fi

input=""
output=""
fps=15
width=720
start=""
duration=""

while [ $# -gt 0 ]; do
  case "$1" in
    -f) fps="$2"; shift 2 ;;
    -w) width="$2"; shift 2 ;;
    -s) start="$2"; shift 2 ;;
    -t) duration="$2"; shift 2 ;;
    -h|--help) sed -n '2,8p' "$0"; exit 0 ;;
    *)
      if [ -z "$input" ]; then input="$1"
      elif [ -z "$output" ]; then output="$1"
      else echo "Лишний аргумент: $1" >&2; exit 1
      fi
      shift
      ;;
  esac
done

if [ -z "$input" ] || [ ! -f "$input" ]; then
  echo "Ошибка: укажите существующий видеофайл" >&2
  exit 1
fi

[ -z "$output" ] && output="${input%.*}.gif"

# Опции обрезки по времени (ставятся ПЕРЕД -i для скорости)
trim_args=()
[ -n "$start" ]    && trim_args+=(-ss "$start")
[ -n "$duration" ] && trim_args+=(-t "$duration")

# Двухпроходная конвертация: сначала палитра (точные цвета), потом gif
palette=$(mktemp --suffix=.png)
trap 'rm -f "$palette"' EXIT

filters="fps=${fps},scale=${width}:-1:flags=lanczos"

echo "→ генерирую палитру..."
ffmpeg -hide_banner -loglevel error -y \
  "${trim_args[@]}" -i "$input" \
  -vf "${filters},palettegen=stats_mode=diff" \
  "$palette"

echo "→ собираю gif: $output"
ffmpeg -hide_banner -loglevel error -y \
  "${trim_args[@]}" -i "$input" -i "$palette" \
  -lavfi "${filters} [x]; [x][1:v] paletteuse=dither=bayer:bayer_scale=5:diff_mode=rectangle" \
  "$output"

size=$(du -h "$output" | cut -f1)
echo "✓ готово: $output ($size)"
