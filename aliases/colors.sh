#!/bin/bash
# Описание: Цветной вывод базовых утилит через dircolors
# Категория: colors

if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'           # цветной ls
    alias grep='grep --color=auto'       # цветной grep
    alias fgrep='fgrep --color=auto'     # цветной fgrep
    alias egrep='egrep --color=auto'     # цветной egrep
fi