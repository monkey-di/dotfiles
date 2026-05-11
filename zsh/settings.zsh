#!/usr/bin/env zsh
# Описание: zsh-настройки (история, completion, опции) — аналог bash settings.bash
# Категория: shell

# История
HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000
SAVEHIST=10000

setopt SHARE_HISTORY              # синхронизация истории между сессиями
setopt HIST_IGNORE_DUPS            # не писать подряд идущие дубликаты
setopt HIST_IGNORE_ALL_DUPS        # удалять старые дубликаты при добавлении
setopt HIST_REDUCE_BLANKS          # схлопывать лишние пробелы
setopt EXTENDED_HISTORY            # таймстампы в history

# Глоббинг
setopt EXTENDED_GLOB               # ** для рекурсии, ^ для исключения и т.д.
setopt NO_CASE_GLOB                # регистронезависимый globbing
setopt AUTO_CD                     # просто имя каталога = cd туда
setopt CORRECT                     # автокоррекция имён команд

# Word-split — bash-подобное поведение для $var (zsh по умолчанию не сплитит)
setopt SH_WORD_SPLIT

# Поиск по истории с учётом текущего ввода (как в bash через bind '\e[A')
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey '^[[A' up-line-or-beginning-search       # стрелка вверх
bindkey '^[[B' down-line-or-beginning-search     # стрелка вниз

# Completion: регистронезависимое, меню по Tab
autoload -Uz compinit && compinit
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' menu select
