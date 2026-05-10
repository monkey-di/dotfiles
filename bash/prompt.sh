# Цвет значка $ — зависит от exit code предыдущей команды
prompt_sigil() {
  if [[ $? -eq 0 ]]; then
    tput setaf 4 # синий — всё ок
  else
    tput setaf 1 # красный — упало
  fi
}

# Git-ветка, если в репозитории
git_branch() {
  local b
  b=$(git symbolic-ref --short HEAD 2>/dev/null) || return
  printf " \001%s\002[%s]\001%s\002" "$(tput setaf 5)" "$b" "$(tput sgr0)"
}

# Промпт
PS1='\n\[$(tput setaf 7)\]\u@\h\[$(tput sgr0)\] \[$(tput bold)$(tput setaf 6)\]\w\[$(tput sgr0)\]$(git_branch)\n\[$(prompt_sigil)\]λ\[$(tput sgr0)\] '

# Обёртка ssh — красит локальный курсор и меняет title окна на время сессии
ssh() {
  printf '\033]0;ssh: %s\007' "$*"
  printf '\033]12;#ff5555\007'
  command ssh "$@"
  local rc=$?
  printf '\033]0;%s\007' "${PWD/#$HOME/~}"
  printf '\033]112\007'
  return $rc
}
