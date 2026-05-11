#!/bin/bash
# Описание: Алиасы и функции для git (статус, коммит, ветки, откат)
# Категория: git

alias gi='git init'                          # инициализация репозитория
alias gs='git status'                        # статус рабочего дерева
alias ga='git add .'                         # застейджить все изменения
alias gra='git remote add origin'            # добавить remote origin: gra <url>
alias gc='git commit -m'                     # коммит с сообщением: gc "msg"
alias gp='git push'                          # push в текущую ветку
alias gac='git add . && git commit -m'       # add + commit одной командой

alias gd='git diff'                          # diff незастейдженных изменений
alias gds='git diff --staged'                # diff того, что уже в индексе
alias gst='git stash'                        # спрятать текущие изменения
alias gstp='git stash pop'                   # вернуть последний stash
alias glo='git log --oneline --graph --decorate -20'  # компактный лог последних 20 коммитов
alias gco='git checkout'                     # переключение веток/файлов
alias gpl='git pull'                         # подтянуть изменения с remote
alias gpf='git push --force-with-lease'      # безопасный force push (не затрёт чужие коммиты)
alias gcl='git clone'                        # клонировать репозиторий
alias gunadd='git reset HEAD --'             # отменить git add для файла

# Функция для переключения или создания ветки
gf() {
  local feature_name="$1"
  if [ -z "$feature_name" ]; then
    echo "Ошибка: укажите имя ветки"
    echo "Использование: gco <имя_ветки>"
    return 1
  fi

  # Проверяем, существует ли ветка локально
  if git show-ref --verify --quiet "refs/heads/$feature_name"; then
    git checkout "$feature_name"
    echo "Успешно переключились на существующую ветку $feature_name"
  else
    # Создаём новую локальную ветку
    git checkout -b "$feature_name"
    echo "Создали и переключились на новую локальную ветку $feature_name"
  fi
}

# Функция для переключения на master
gm() {
  # Сохраняем текущую ветку
  local current_branch
  current_branch=$(git branch --show-current)
  echo "Текущая ветка: $current_branch"

  # Переключаемся на master
  if ! git checkout master; then
    echo "Ошибка при переключении на ветку master"
    return 1
  fi

  # Обновляем локальную ветку master

  if ! git pull origin master; then
    echo "Ошибка при обновлении ветки master"
    exit $?
  fi

  # Мержим feature-ветку в master
  if ! git merge "$current_branch"; then
    echo "Ошибка при мерже ветки $current_branch в master"
    echo "Возможно, потребуется разрешить конфликты вручную"
    exit $?
  fi
}

gr() {
  local choice;
  local commit_hash;
  echo "Выберите действие для отката:"
  echo "1) Отменить все незакоммиченные изменения"
  echo "2) Отменить последний коммит"
  echo "3) Выбрать из последних коммитов"
  echo "0) Отмена"

  printf 'Ваш выбор: '
  read -r choice

  case $choice in
  1)
  # Отменить незакоммиченные изменения
    git --git-dir="$GIT2_DIR" --work-tree=. reset --hard HEAD
    echo "✓ Все незакоммиченные изменения отменены"
    ;;
  2)
  # Отменить последний коммит
    git --git-dir="$GIT2_DIR" --work-tree=. reset --hard HEAD~1
    echo "✓ Последний коммит отменен"
    ;;
  3)
  # Выбор из последних коммитов
    echo "Последние 5 коммитов:"
    git --git-dir="$GIT2_DIR" --work-tree=. log --oneline -5

    printf 'Введите хэш коммита для отката (или Enter для отмены): '
    read -r commit_hash
    if [ -n "$commit_hash" ]; then
      git --git-dir="$GIT2_DIR" --work-tree=. reset --hard "$commit_hash"
      echo "✓ Откат к коммиту $commit_hash выполнен"
    else
      echo "Откат отменен"
    fi
    ;;
  0|*)
    echo "Откат отменен"
    ;;
  esac
}
