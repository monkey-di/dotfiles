#!/bin/bash
# Описание: Замены классических утилит на современные (bat/eza/fd/rg/btop/dust/duf) — выставляются только если установлены
# Категория: modern
# Установка зависимостей: install-modern-tools

# bat — cat с подсветкой синтаксиса и нумерацией строк
if command -v bat &>/dev/null; then
  alias cat='bat --paging=never'
  alias catp='bat'                                # с пагинацией (less)
elif command -v batcat &>/dev/null; then          # на Debian/Ubuntu бинарь называется batcat
  alias cat='batcat --paging=never'
  alias catp='batcat'
fi

# eza — современная замена ls (цвета, иконки, git-статус)
if command -v eza &>/dev/null; then
  alias ls='eza --icons'
  alias ll='eza -lah --icons --git'               # подробный список с git-статусом файлов
  alias lt='eza --tree --icons --level=2'         # дерево на 2 уровня
  alias la='eza -a --icons'                       # включая скрытые
fi

# fd — быстрая и удобная замена find (синтаксис проще, уважает .gitignore)
if command -v fd &>/dev/null; then
  alias ffind='fd'                                # не перекрываем системный find
elif command -v fdfind &>/dev/null; then          # на Debian/Ubuntu бинарь называется fdfind
  alias ffind='fdfind'
fi

# ripgrep — быстрый grep, по умолчанию рекурсивный, уважает .gitignore
if command -v rg &>/dev/null; then
  alias rgrep='rg'                                # не перекрываем системный grep
fi

# btop — красивый top с графиками (CPU/RAM/сеть/диски)
if command -v btop &>/dev/null; then
  alias top='btop'
fi

# dust — du с визуализацией размера директорий
if command -v dust &>/dev/null; then
  alias ddu='dust'                                # не перекрываем системный du
fi

# duf — df с цветным выводом и группировкой по типу ФС
if command -v duf &>/dev/null; then
  alias ddf='duf'                                 # не перекрываем системный df
fi
