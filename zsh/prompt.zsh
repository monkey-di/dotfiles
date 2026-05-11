#!/usr/bin/env zsh
# Описание: zsh-промпт с git-веткой и цветным сигилом (аналог bash prompt.sh)
# Категория: shell

# Включаем разворачивание prompt-подстановок
setopt PROMPT_SUBST

# Git-ветка, если в репозитории
_git_branch() {
  local b
  b=$(git symbolic-ref --short HEAD 2>/dev/null) || return
  printf " %%F{5}[%s]%%f" "$b"
}

# Цвет сигила λ — синий при exit 0, красный при ошибке
PROMPT='
%F{7}%n@%m%f %B%F{6}%~%f%b$(_git_branch)
%(?.%F{4}.%F{1})λ%f '

# Обёртка ssh: подсвечивает курсор и меняет title окна на время сессии
ssh() {
  printf '\033]0;ssh: %s\007' "$*"
  printf '\033]12;#ff5555\007'
  command ssh "$@"
  local rc=$?
  printf '\033]0;%s\007' "${PWD/#$HOME/~}"
  printf '\033]112\007'
  return $rc
}
