#!/usr/bin/env bash
# Описание: Универсальная распаковка архивов по расширению (tar.*, zip, rar, 7z и др.)
# Использование: extract <архив> [<архив>...]
# Примеры:
#   extract archive.tar.gz
#   extract *.zip
# Зависимости: tar, gzip, bzip2, unzip, unrar, 7z, xz (по необходимости)
# Категория: files

set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Использование: extract <архив> [<архив>...]" >&2
  exit 1
fi

extract_one() {
  local file="$1"
  if [ ! -f "$file" ]; then
    echo "'$file': не файл или не существует" >&2
    return 1
  fi
  case "$file" in
    *.tar.bz2|*.tbz2) tar xvjf "$file" ;;
    *.tar.gz|*.tgz)   tar xvzf "$file" ;;
    *.tar.xz|*.txz)   tar xvJf "$file" ;;
    *.tar.zst)        tar --use-compress-program=unzstd -xvf "$file" ;;
    *.tar)            tar xvf  "$file" ;;
    *.bz2)            bunzip2  "$file" ;;
    *.gz)             gunzip   "$file" ;;
    *.xz)             unxz     "$file" ;;
    *.zst)            unzstd   "$file" ;;
    *.zip)            unzip    "$file" ;;
    *.rar)            unrar x  "$file" ;;
    *.7z)             7z x     "$file" ;;
    *.Z)              uncompress "$file" ;;
    *) echo "Не знаю как распаковать '$file'" >&2; return 1 ;;
  esac
}

rc=0
for f in "$@"; do
  extract_one "$f" || rc=1
done
exit $rc
