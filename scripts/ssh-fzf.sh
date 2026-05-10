#!/usr/bin/env bash
# Описание: Интерактивный выбор хоста из ~/.ssh/config через fzf (с превью блока конфига) и подключение по ssh
# Использование: ssh-fzf [фильтр]
# Зависимости: fzf, ssh
# Категория: network

set -euo pipefail

config="${HOME}/.ssh/config"

if [ ! -f "$config" ]; then
  echo "Ошибка: $config не найден" >&2
  exit 1
fi

# Извлекаем имена хостов из ssh-конфига.
# Учитываем директивы Include (ssh поддерживает их с 7.3).
collect_hosts() {
  local file="$1"
  [ -f "$file" ] || return 0
  awk '
    tolower($1) == "host"    { for (i=2; i<=NF; i++) if ($i !~ /[*?!]/) print $i }
    tolower($1) == "include" { for (i=2; i<=NF; i++) print "INCLUDE\t" $i }
  ' "$file" | while read -r line; do
    if [[ "$line" == INCLUDE* ]]; then
      local inc="${line#INCLUDE	}"
      # Раскрытие ~ и относительных путей относительно ~/.ssh/
      [[ "$inc" == ~* ]] && inc="${inc/#\~/$HOME}"
      [[ "$inc" != /* ]] && inc="$HOME/.ssh/$inc"
      for f in $inc; do collect_hosts "$f"; done
    else
      echo "$line"
    fi
  done
}

hosts=$(collect_hosts "$config" | sort -u)

if [ -z "$hosts" ]; then
  echo "В $config нет именованных хостов" >&2
  exit 1
fi

# Если задан фильтр — передаём его как начальный query в fzf
query="${1:-}"

selected=$(echo "$hosts" | fzf \
  --prompt="ssh > " \
  --height=40% \
  --reverse \
  --query="$query" \
  --preview="awk -v host={} '
    BEGIN { p=0 }
    /^[Hh]ost / {
      p=0
      for (i=2; i<=NF; i++) if (\$i == host) p=1
    }
    p { print }
  ' '$config'" \
  --preview-window=right:50%)

if [ -z "$selected" ]; then
  exit 0
fi

echo "→ ssh $selected"
exec ssh "$selected"
