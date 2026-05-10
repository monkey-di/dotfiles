#!/bin/bash
# Описание: Алиасы для docker и docker compose
# Категория: docker

alias d='docker'                                    # короткий вызов docker
alias dps='docker ps'                               # запущенные контейнеры
alias dpsa='docker ps -a'                           # все контейнеры (включая остановленные)
alias di='docker images'                            # список образов
alias dex='docker exec -it'                         # зайти в контейнер: dex <id|name> bash
alias dlog='docker logs -f'                         # следить за логами контейнера
alias dstop='docker stop'                           # остановить контейнер
alias drm='docker rm'                               # удалить контейнер
alias drmi='docker rmi'                             # удалить образ
alias dprune='docker system prune -af'              # снести всё неиспользуемое (контейнеры, образы, сети)
alias dvprune='docker volume prune -f'              # удалить неиспользуемые volume'ы
alias dip="docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}'"  # IP контейнера: dip <name>

# docker compose
alias dc='docker compose'                           # короткий вызов compose
alias dcu='docker compose up -d'                    # поднять стек в фоне
alias dcd='docker compose down'                     # остановить и удалить контейнеры стека
alias dcdv='docker compose down -v'                 # то же + удалить volume'ы (осторожно: данные пропадут)
alias dcl='docker compose logs -f'                  # логи всех сервисов стека в реальном времени
alias dcr='docker compose restart'                  # перезапустить сервисы
alias dcb='docker compose build'                    # собрать образы из docker-compose.yml
alias dcp='docker compose ps'                       # статус сервисов стека
alias dce='docker compose exec'                     # выполнить команду в сервисе: dce <service> bash
