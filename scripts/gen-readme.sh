#!/usr/bin/env bash
# Описание: Генерирует разделы README.md из header'ов скриптов и алиасов между маркерами AUTO:BEGIN/END
# Использование: gen-readme [--check]
# Примеры:
#   gen-readme              # перезаписать README.md
#   gen-readme --check      # упасть с кодом 1, если README устарел (для CI/pre-commit)
# Зависимости: awk, sed
# Категория: system

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
# shellcheck source=cheat-lib.sh
source "$SCRIPT_DIR/cheat-lib.sh"

README="$DOTFILES_ROOT/README.md"
BEGIN_MARK="<!-- AUTO:BEGIN -->"
END_MARK="<!-- AUTO:END -->"

generate() {
  echo "$BEGIN_MARK"
  echo "<!-- НЕ РЕДАКТИРОВАТЬ ВРУЧНУЮ. Сгенерировано scripts/gen-readme.sh -->"
  echo

  # Скрипты
  echo "## Скрипты"
  echo
  echo "Доступны через \`PATH\` как обычные команды (\`~/.scripts/\`)."
  echo
  echo "| Скрипт | Категория | Описание | Зависимости |"
  echo "| --- | --- | --- | --- |"
  while IFS= read -r f; do
    local name desc cat deps
    name="$(basename "$f" .sh)"
    desc="$(header_field "$f" 'Описание')"
    cat="$(header_field "$f" 'Категория')"
    deps="$(header_field "$f" 'Зависимости')"
    desc="${desc//|/\\|}"
    deps="${deps//|/\\|}"
    echo "| \`$name\` | $cat | $desc | ${deps:-—} |"
  done < <(list_script_files)
  echo

  # Алиасы
  echo "## Алиасы"
  echo
  echo "Все \`.sh\`-файлы из \`~/.aliases/\` подгружаются автоматически."
  echo
  while IFS= read -r f; do
    local name desc cat
    name="$(basename "$f")"
    desc="$(header_field "$f" 'Описание')"
    cat="$(header_field "$f" 'Категория')"
    echo "### \`$name\`${desc:+ — $desc}"
    echo
    # Таблица алиасов
    local entries
    entries="$(alias_entries "$f")"
    if [ -n "$entries" ]; then
      echo "| Алиас | Команда | Описание |"
      echo "| --- | --- | --- |"
      while IFS=$'\t' read -r aname acmd acomment; do
        acmd="${acmd//|/\\|}"
        acomment="${acomment//|/\\|}"
        echo "| \`$aname\` | \`$acmd\` | $acomment |"
      done <<< "$entries"
      echo
    fi
  done < <(list_alias_files)

  echo "$END_MARK"
}

new_section="$(generate)"

if [ "${1:-}" = "--check" ]; then
  current="$(awk -v b="$BEGIN_MARK" -v e="$END_MARK" '
    $0 == b { p=1 } p { print } $0 == e { exit }
  ' "$README")"
  if [ "$current" = "$new_section" ]; then
    echo "✓ README.md актуален"
    exit 0
  else
    echo "✗ README.md устарел. Запусти: gen-readme" >&2
    exit 1
  fi
fi

# Заменяем секцию между маркерами. Если маркеров нет — добавляем в конец.
if grep -q "$BEGIN_MARK" "$README" && grep -q "$END_MARK" "$README"; then
  # Используем awk для замены блока
  tmp="$(mktemp)"
  awk -v b="$BEGIN_MARK" -v e="$END_MARK" -v repl="$new_section" '
    $0 == b { print repl; skip=1; next }
    $0 == e { skip=0; next }
    !skip { print }
  ' "$README" > "$tmp"
  mv "$tmp" "$README"
else
  printf '\n%s\n' "$new_section" >> "$README"
fi

echo "✓ README.md обновлён"
