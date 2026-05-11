#!/usr/bin/env bash
# Описание: Библиотека парсинга алиасов и скриптов из dotfiles (для gen-readme и cheat)
# Использование: source cheat-lib  (отдельно не запускается)
# Категория: system

# Корневой каталог dotfiles. Если запущено из симлинка ~/.scripts/ — резолвим.
__cheat_resolve_root() {
  local self
  self="$(readlink -f "${BASH_SOURCE[0]}")"
  echo "$(cd "$(dirname "$self")/.." && pwd)"
}
DOTFILES_ROOT="${DOTFILES_ROOT:-$(__cheat_resolve_root)}"
ALIASES_DIR="$DOTFILES_ROOT/aliases"
SCRIPTS_DIR="$DOTFILES_ROOT/scripts"

# Вытащить значение метки (Описание/Категория/Использование/Зависимости) из header'а файла.
# Берём только из первого блока комментариев (до первой не-комментарной/пустой строки).
header_field() {
  local file="$1" key="$2"
  awk -v key="$key" '
    BEGIN { in_header = 0 }
    NR == 1 && /^#!/ { next }                     # пропускаем shebang
    /^[[:space:]]*$/ { if (in_header) exit; next }
    /^#/ {
      in_header = 1
      line = $0
      sub(/^#[[:space:]]*/, "", line)
      if (line ~ "^" key ":") {
        sub("^" key ":[[:space:]]*", "", line)
        print line
        exit
      }
      next
    }
    in_header { exit }
  ' "$file"
}

# Многострочные секции (Использование/Примеры/Зависимости с продолжениями).
# Возвращает все строки секции включая продолжения с отступом.
header_block() {
  local file="$1" key="$2"
  awk -v key="$key" '
    BEGIN { in_header = 0; in_section = 0 }
    NR == 1 && /^#!/ { next }
    /^[[:space:]]*$/ { exit }
    /^#/ {
      in_header = 1
      line = $0
      sub(/^#[[:space:]]*/, "", line)
      # Новая известная метка прерывает текущую секцию
      if (line ~ /^(Описание|Использование|Примеры|Зависимости|Категория):/) {
        if (line ~ "^" key ":") {
          sub("^" key ":[[:space:]]*", "", line)
          if (length(line) > 0) print line
          in_section = 1
        } else {
          in_section = 0
        }
        next
      }
      if (in_section) print line
      next
    }
    in_header { exit }
  ' "$file"
}

# Список файлов алиасов (отсортированных по имени).
list_alias_files() {
  find "$ALIASES_DIR" -maxdepth 1 -name '*.sh' -type f | sort
}

# Список файлов скриптов (исключаем библиотеки и генератор README).
list_script_files() {
  find "$SCRIPTS_DIR" -maxdepth 1 -name '*.sh' -type f \
    ! -name 'cheat-lib.sh' ! -name 'lib-os.sh' ! -name 'gen-readme.sh' | sort
}

# Перебор пар «алиас — комментарий» из файла.
# Печатает: <name>\t<command>\t<comment>
alias_entries() {
  local file="$1"
  awk '
    /^[[:space:]]*alias[[:space:]]+[A-Za-z0-9_.-]+=/ {
      line = $0
      # имя
      match(line, /alias[[:space:]]+[A-Za-z0-9_.-]+=/)
      name = substr(line, RSTART + 6, RLENGTH - 7)
      gsub(/^[[:space:]]+/, "", name)
      rest = substr(line, RSTART + RLENGTH)
      # команда — между кавычек (одинарных или двойных)
      cmd = ""
      comment = ""
      q = substr(rest, 1, 1)
      if (q == "'\''" || q == "\"") {
        end = index(substr(rest, 2), q)
        if (end > 0) {
          cmd = substr(rest, 2, end - 1)
          tail = substr(rest, end + 2)
          # комментарий после команды
          if (match(tail, /#[[:space:]]*/) > 0) {
            comment = substr(tail, RSTART + RLENGTH)
            sub(/[[:space:]]+$/, "", comment)
          }
        }
      } else {
        # без кавычек — берём до пробела/комментария
        if (match(rest, /[[:space:]]*#/) > 0) {
          cmd = substr(rest, 1, RSTART - 1)
          comment = substr(rest, RSTART + RLENGTH)
          sub(/^[[:space:]]+/, "", comment)
        } else {
          cmd = rest
        }
        sub(/[[:space:]]+$/, "", cmd)
      }
      printf "%s\t%s\t%s\n", name, cmd, comment
    }
  ' "$file"
}
