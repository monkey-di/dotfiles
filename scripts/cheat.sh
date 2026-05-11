#!/usr/bin/env bash
# Описание: Терминальная справка по скриптам и алиасам dotfiles на лету (без README)
# Использование: cheat [-s|--scripts] [-a|--alias|--aliases] [запрос]
# Примеры:
#   cheat                # все скрипты (по умолчанию)
#   cheat git            # скрипты, подходящие под "git"
#   cheat -a             # все алиасы сгруппированные по файлу/категории
#   cheat -a docker      # только алиасы из категории/файла docker
#   cheat -s -a          # и скрипты, и алиасы
# Зависимости: awk
# Категория: system

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
# shellcheck source=cheat-lib.sh
source "$SCRIPT_DIR/cheat-lib.sh"

show_aliases=0
show_scripts=0
query=""

while [ $# -gt 0 ]; do
  case "$1" in
    -s|--scripts) show_scripts=1; shift ;;
    -a|--alias|--aliases) show_aliases=1; shift ;;
    -h|--help) sed -n '2,10p' "$0"; exit 0 ;;
    *) query="$1"; shift ;;
  esac
done

# По умолчанию (без флагов) — только скрипты
if [ "$show_aliases" = "0" ] && [ "$show_scripts" = "0" ]; then
  show_scripts=1
fi

# Цвета (только если stdout — терминал)
if [ -t 1 ]; then
  C_HEAD=$'\033[1;35m'    # magenta bold — категория
  C_NAME=$'\033[1;36m'    # cyan bold — имя
  C_DESC=$'\033[2m'       # dim — описание
  C_OFF=$'\033[0m'
else
  C_HEAD=""; C_NAME=""; C_DESC=""; C_OFF=""
fi

# Совпадение запроса (без учёта регистра, в любой части строки)
matches() {
  [ -z "$query" ] && return 0
  local hay
  hay="$(printf '%s\n' "$@" | tr '[:upper:]' '[:lower:]')"
  local needle
  needle="$(printf '%s' "$query" | tr '[:upper:]' '[:lower:]')"
  [[ "$hay" == *"$needle"* ]]
}

if [ "$show_scripts" = "1" ]; then
  printed_header=0
  while IFS= read -r f; do
    name="$(basename "$f" .sh)"
    desc="$(header_field "$f" 'Описание')"
    cat="$(header_field "$f" 'Категория')"
    usage="$(header_field "$f" 'Использование')"
    deps="$(header_field "$f" 'Зависимости')"

    if matches "$name" "$desc" "$cat" "$usage" "$deps"; then
      if [ "$printed_header" = "0" ]; then
        printf "${C_HEAD}# scripts${C_OFF}\n"
        printed_header=1
      fi
      printf "  ${C_NAME}%-22s${C_OFF}  ${C_DESC}[%s]${C_OFF}  %s\n" "$name" "${cat:-?}" "$desc"
      [ -n "$usage" ] && printf "    ${C_DESC}usage:${C_OFF} %s\n" "$usage"
      [ -n "$deps" ]  && printf "    ${C_DESC}deps:${C_OFF}  %s\n" "$deps"
    fi
  done < <(list_script_files)
  [ "$printed_header" = "1" ] && echo
fi

if [ "$show_aliases" = "1" ]; then
  while IFS= read -r f; do
    local_desc="$(header_field "$f" 'Описание')"
    local_cat="$(header_field "$f" 'Категория')"
    fname="$(basename "$f" .sh)"

    # Собираем подходящие алиасы из файла
    block=""
    while IFS=$'\t' read -r aname acmd acomment; do
      [ -z "$aname" ] && continue
      if matches "$aname" "$acmd" "$acomment" "$fname" "$local_cat" "$local_desc"; then
        block+="  ${C_NAME}$(printf '%-8s' "$aname")${C_OFF}  $acmd"
        [ -n "$acomment" ] && block+="  ${C_DESC}# $acomment${C_OFF}"
        block+=$'\n'
      fi
    done < <(alias_entries "$f")

    if [ -n "$block" ]; then
      printf "${C_HEAD}# %s${C_OFF}  ${C_DESC}%s${C_OFF}\n" "${local_cat:-$fname}" "$local_desc"
      printf '%s' "$block"
      echo
    fi
  done < <(list_alias_files)
fi
