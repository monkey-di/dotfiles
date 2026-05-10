# Настройка истории команд
HISTCONTROL=ignoredups # Игнорировать дубликаты в истории
HISTSIZE=1000
HISTFILESIZE=2000
PROMPT_COMMAND="history -a; history -c; history -r; $PROMPT_COMMAND"
HISTTIMEFORMAT="%F %T "          # таймстампы в history
HISTCONTROL=ignoredups:erasedups # дубликаты не только игнорируются, но и удаляются из файла

# Настройка поиска по истории с учетом текущего ввода
bind '"\e[A": history-search-backward' 2>/dev/null
bind '"\e[B": history-search-forward' 2>/dev/null

# Настройка автодополнения для перебора вариантов
bind 'set completion-ignore-case on' 2>/dev/null
bind 'set show-all-if-ambiguous off' 2>/dev/null
bind 'set show-all-if-unmodified off' 2>/dev/null
bind 'set menu-complete-display-prefix on' 2>/dev/null
bind 'TAB:menu-complete' 2>/dev/null

shopt -s globstar   # ** для рекурсивного матчинга
shopt -s extglob    # @(a|b), !(pattern), *(pattern) и т.д.
shopt -s nocaseglob # регистронезависимый globbing — спорно, на любителя
shopt -s cdspell    # автокор
shopt -s dirspell   # то же при tab-completion
shopt -s autocd
# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize
# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"
# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
  xterm-color | *-256color) color_prompt=yes ;;
esac
force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
  if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
    # We have color support; assume it's compliant with Ecma-48
    # (ISO/IEC-6429). (Lack of such support is extremely rare, and such
    # a case would tend to support setf rather than setaf.)
    color_prompt=yes
  else
    color_prompt=
  fi
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi
