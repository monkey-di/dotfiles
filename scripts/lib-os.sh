#!/usr/bin/env bash
# Описание: Кросс-платформенные хелперы для скриптов (_clip, _notify) — не запускать отдельно
# Использование: source lib-os
# Категория: system

# Положить stdin в буфер обмена.
# Использование: echo hello | _clip
_clip() {
  if command -v pbcopy &>/dev/null; then              # macOS
    pbcopy
  elif [ "${XDG_SESSION_TYPE:-}" = "wayland" ] && command -v wl-copy &>/dev/null; then
    wl-copy --trim-newline
  elif command -v xclip &>/dev/null; then              # X11
    xclip -selection clipboard
  else
    cat >/dev/null
    return 1
  fi
}

# Десктопное уведомление: notify-send на Linux, osascript на macOS.
# Использование: _notify "Заголовок" "Текст"
_notify() {
  local title="$1" body="${2:-}"
  if command -v notify-send &>/dev/null; then          # Linux
    notify-send -- "$title" "$body"
  elif command -v osascript &>/dev/null; then          # macOS
    osascript -e "display notification \"${body//\"/\\\"}\" with title \"${title//\"/\\\"}\""
  fi
}
