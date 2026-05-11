#!/bin/bash
# Описание: Системные алиасы — процессы, сеть, диски, память, функция me с инфой о системе
# Категория: system

# Команды-однострочники, отличающиеся по ОС
if [ "${DOTFILES_OS:-}" = "mac" ]; then
  alias ports='lsof -iTCP -sTCP:LISTEN -n -P'                              # кто слушает TCP-порты на macOS
  alias localip='ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1'  # локальный IP первого активного интерфейса
  alias mem='vm_stat'                                                       # использование памяти на macOS (страницами)
else
  alias ports='ss -tulpn'                                                   # кто слушает порты (TCP/UDP, с PID процесса)
  alias localip="hostname -I | awk '{print \$1}'"                           # локальный IP в сети
  alias mem='free -h'                                                       # использование памяти в человекочитаемом виде
fi

alias myip='curl -s ifconfig.me'              # внешний IP машины
alias psg='ps aux | grep -v grep | grep'      # поиск процесса по имени: psg nginx
alias killz='kill -9'                         # принудительно прибить процесс по PID
alias path='echo -e ${PATH//:/\\n}'           # вывести PATH построчно (читабельно)
alias reload='source ~/.bashrc 2>/dev/null || source ~/.zshrc'  # перечитать конфиг текущего shell
alias h='history'                             # история команд
alias now='date +"%Y-%m-%d %H:%M:%S"'         # текущая дата/время
alias week='date +%V'                         # номер текущей недели в году
alias diskspace='df -h'                       # свободное место на дисках
alias biggest="du -h -d 1 2>/dev/null | sort -hr | head -20"  # самые жирные подпапки в текущей директории (-d 1 работает и на BSD/macOS)

# me — краткая сводка о системе: железо, ОС, ядро, ресурсы.
# Если установлен fastfetch/neofetch — используем его, иначе собираем сами.
me() {
  if command -v fastfetch &>/dev/null; then
    fastfetch
    return
  fi
  if command -v neofetch &>/dev/null; then
    neofetch
    return
  fi

  # Минимальный кросс-платформенный fallback
  echo "Host:    $(hostname)"
  echo "OS:      $(uname -srm)"
  echo "Shell:   $(basename "${SHELL:-?}")"
  if [ "${DOTFILES_OS:-}" = "mac" ]; then
    echo "CPU:     $(sysctl -n machdep.cpu.brand_string 2>/dev/null) ($(sysctl -n hw.ncpu) cores)"
    echo "RAM:     $(($(sysctl -n hw.memsize) / 1024 / 1024 / 1024)) GiB"
  else
    echo "CPU:     $(grep -m1 'model name' /proc/cpuinfo | sed 's/.*: //') ($(nproc) cores)"
    command -v free &>/dev/null && echo "RAM:     $(free -h --si | awk '/^Mem:/ {print $3" / "$2}')"
  fi
  df -h / | awk 'NR==2 {print "Disk /:  "$3" / "$2" ("$5" used)"}'
}
