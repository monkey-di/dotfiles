#!/bin/bash
# Описание: Системные алиасы — процессы, сеть, диски, память, функция me с инфой о системе
# Категория: system

alias ports='ss -tulpn'                       # кто слушает порты (TCP/UDP, с PID процесса)
alias myip='curl -s ifconfig.me'              # внешний IP машины
alias localip="hostname -I | awk '{print \$1}'"  # локальный IP в сети
alias psg='ps aux | grep -v grep | grep'      # поиск процесса по имени: psg nginx
alias killz='kill -9'                         # принудительно прибить процесс по PID
alias path='echo -e ${PATH//:/\\n}'           # вывести PATH построчно (читабельно)
alias reload='source ~/.bashrc'               # перечитать bashrc после правок
alias h='history'                             # история команд
alias now='date +"%Y-%m-%d %H:%M:%S"'         # текущая дата/время
alias week='date +%V'                         # номер текущей недели в году
alias mem='free -h'                           # использование памяти в человекочитаемом виде
alias diskspace='df -h'                       # свободное место на дисках
alias biggest="du -h --max-depth=1 | sort -hr | head -20"  # самые жирные подпапки в текущей директории

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

  # Fallback: собираем сами из /sys, /proc и стандартных утилит
  local model="unknown"
  if [ -r /sys/class/dmi/id/product_name ]; then
    model=$(cat /sys/class/dmi/id/product_name)
    [ -r /sys/class/dmi/id/product_version ] && model="$model ($(cat /sys/class/dmi/id/product_version))"
  fi

  local os="unknown"
  [ -r /etc/os-release ] && os=$(. /etc/os-release && echo "$PRETTY_NAME")

  local cpu
  cpu=$(grep -m1 'model name' /proc/cpuinfo | sed 's/.*: //')
  local cores
  cores=$(nproc)

  local gpu
  gpu=$(lspci 2>/dev/null | grep -iE 'vga|3d|display' | head -1 | sed 's/.*: //')

  local ram_used ram_total
  read -r ram_used ram_total < <(free -h --si | awk '/^Mem:/ {print $3, $2}')

  local disk
  disk=$(df -h / | awk 'NR==2 {print $3" / "$2" ("$5" used)"}')

  local kernel
  kernel=$(uname -r)

  local shell_name
  shell_name=$(basename "$SHELL")

  local up
  up=$(uptime -p 2>/dev/null | sed 's/^up //')

  echo "Host:    $(hostname) — $model"
  echo "OS:      $os"
  echo "Kernel:  $kernel"
  echo "Shell:   $shell_name"
  echo "Uptime:  $up"
  echo "CPU:     $cpu ($cores cores)"
  [ -n "$gpu" ] && echo "GPU:     $gpu"
  echo "RAM:     $ram_used / $ram_total"
  echo "Disk /:  $disk"
}
