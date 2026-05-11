# dotfiles

Настройки bash для Linux.

## Установка

```bash
git clone <repo-url> && cd dotfiles
./install.sh
```

Скрипт создаст симлинки:

| Источник   | Цель         |
| ---------- | ------------ |
| `bashrc`   | `~/.bashrc`  |
| `aliases/` | `~/.aliases` |
| `scripts/` | `~/.scripts` |

Существующие файлы сохраняются в `~/.dotfiles_backup/<timestamp>/`. Повторный запуск безопасен — уже установленные симлинки пропускаются.

## bashrc

- **История**: дедупликация (`ignoredups`), синхронизация между сессиями (`history -a/c/r`), поиск по стрелкам с учётом текущего ввода
- **Автодополнение**: без учёта регистра, перебор вариантов через Tab (`menu-complete`)
- **SSH-агент**: автозапуск и добавление ключа `~/.ssh/id_ed25519`
- **`~/.bashrc.local`** — подгружается в конце для машино-специфичных настроек и секретов

## Cheatsheet

Полная справка по алиасам и скриптам генерируется автоматически из header'ов файлов.
Для терминала используй команду `cheat` (`cheat <запрос>`, `cheat -s`, `cheat -a`).
Для обновления README после правок: `gen-readme`.

<!-- AUTO:BEGIN -->
<!-- НЕ РЕДАКТИРОВАТЬ ВРУЧНУЮ. Сгенерировано scripts/gen-readme.sh -->

## Алиасы

Все `.sh`-файлы из `~/.aliases/` подгружаются автоматически.

### `claude.sh` — Алиасы для Claude Code

| Алиас | Команда | Описание |
| --- | --- | --- |
| `cc` | `claude` | запустить claude |
| `ccd` | `claude --dangerously-skip-permissions` | YOLO: claude без подтверждений на действия |
| `vccd` | `vpnns run claude --dangerously-skip-permissions` | YOLO через VPN namespace |
| `pccd` | `https_proxy=http://10.200.0.1:1080 http_proxy=http://10.200.0.1:1080 claude --dangerously-skip-permissions` | YOLO через прокси (для терминала в Obsidian) |

### `colors.sh` — Цветной вывод базовых утилит через dircolors

| Алиас | Команда | Описание |
| --- | --- | --- |
| `ls` | `ls --color=auto` | цветной ls |
| `grep` | `grep --color=auto` | цветной grep |
| `fgrep` | `fgrep --color=auto` | цветной fgrep |
| `egrep` | `egrep --color=auto` | цветной egrep |

### `docker.sh` — Алиасы для docker и docker compose

| Алиас | Команда | Описание |
| --- | --- | --- |
| `d` | `docker` | короткий вызов docker |
| `dps` | `docker ps` | запущенные контейнеры |
| `dpsa` | `docker ps -a` | все контейнеры (включая остановленные) |
| `di` | `docker images` | список образов |
| `dex` | `docker exec -it` | зайти в контейнер: dex <id\|name> bash |
| `dlog` | `docker logs -f` | следить за логами контейнера |
| `dstop` | `docker stop` | остановить контейнер |
| `drm` | `docker rm` | удалить контейнер |
| `drmi` | `docker rmi` | удалить образ |
| `dprune` | `docker system prune -af` | снести всё неиспользуемое (контейнеры, образы, сети) |
| `dvprune` | `docker volume prune -f` | удалить неиспользуемые volume'ы |
| `dip` | `docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}'` | IP контейнера: dip <name> |
| `dc` | `docker compose` | короткий вызов compose |
| `dcu` | `docker compose up -d` | поднять стек в фоне |
| `dcd` | `docker compose down` | остановить и удалить контейнеры стека |
| `dcdv` | `docker compose down -v` | то же + удалить volume'ы (осторожно: данные пропадут) |
| `dcl` | `docker compose logs -f` | логи всех сервисов стека в реальном времени |
| `dcr` | `docker compose restart` | перезапустить сервисы |
| `dcb` | `docker compose build` | собрать образы из docker-compose.yml |
| `dcp` | `docker compose ps` | статус сервисов стека |
| `dce` | `docker compose exec` | выполнить команду в сервисе: dce <service> bash |

### `general.sh` — Общие повседневные алиасы (ls-варианты, замена nano)

| Алиас | Команда | Описание |
| --- | --- | --- |
| `ll` | `ls -alF` | подробный список с классификаторами (/, *, @) |
| `la` | `ls -A` | включая скрытые (без . и ..) |
| `l` | `ls -CF` | колонками с классификаторами |
| `nano` | `micro` | nano → micro (более удобный консольный редактор) |

### `git.sh` — Алиасы и функции для git (статус, коммит, ветки, откат)

| Алиас | Команда | Описание |
| --- | --- | --- |
| `gi` | `git init` | инициализация репозитория |
| `gs` | `git status` | статус рабочего дерева |
| `ga` | `git add .` | застейджить все изменения |
| `gra` | `git remote add origin` | добавить remote origin: gra <url> |
| `gc` | `git commit -m` | коммит с сообщением: gc "msg" |
| `gp` | `git push` | push в текущую ветку |
| `gac` | `git add . && git commit -m` | add + commit одной командой |
| `gd` | `git diff` | diff незастейдженных изменений |
| `gds` | `git diff --staged` | diff того, что уже в индексе |
| `gst` | `git stash` | спрятать текущие изменения |
| `gstp` | `git stash pop` | вернуть последний stash |
| `glo` | `git log --oneline --graph --decorate -20` | компактный лог последних 20 коммитов |
| `gco` | `git checkout` | переключение веток/файлов |
| `gpl` | `git pull` | подтянуть изменения с remote |
| `gpf` | `git push --force-with-lease` | безопасный force push (не затрёт чужие коммиты) |
| `gcl` | `git clone` | клонировать репозиторий |
| `gunadd` | `git reset HEAD --` | отменить git add для файла |

### `gulp.sh` — Алиасы для gulp (префикс gl, чтобы не конфликтовать с git-алиасами)

| Алиас | Команда | Описание |
| --- | --- | --- |
| `gl` | `gulp` |  |
| `gld` | `gulp dev` |  |
| `glb` | `gulp build` |  |
| `glw` | `gulp watch` |  |
| `gls` | `gulp serve` |  |
| `glc` | `gulp clean` |  |
| `glf` | `gulp default` |  |
| `glt` | `gulp --tasks` |  |
| `ngl` | `npx gulp` |  |
| `ngld` | `npx gulp dev` |  |
| `nglb` | `npx gulp build` |  |
| `nglw` | `npx gulp watch` |  |

### `modern.sh` — Замены классических утилит на современные (bat/eza/fd/rg/btop/dust/duf) — выставляются только если установлены

| Алиас | Команда | Описание |
| --- | --- | --- |
| `cat` | `bat --paging=never` |  |
| `catp` | `bat` | с пагинацией (less) |
| `cat` | `batcat --paging=never` |  |
| `catp` | `batcat` |  |
| `ls` | `eza --icons` |  |
| `ll` | `eza -lah --icons --git` | подробный список с git-статусом файлов |
| `lt` | `eza --tree --icons --level=2` | дерево на 2 уровня |
| `la` | `eza -a --icons` | включая скрытые |
| `ffind` | `fd` | не перекрываем системный find |
| `ffind` | `fdfind` |  |
| `rgrep` | `rg` | не перекрываем системный grep |
| `top` | `btop` |  |
| `ddu` | `dust` | не перекрываем системный du |
| `ddf` | `duf` | не перекрываем системный df |

### `npm.sh` — Алиасы для npm и bun (управление пакетами и запуск скриптов)

| Алиас | Команда | Описание |
| --- | --- | --- |
| `n` | `npm` |  |
| `ni` | `npm install` |  |
| `nid` | `npm install --save-dev` |  |
| `nig` | `npm install -g` |  |
| `nun` | `npm uninstall` |  |
| `nup` | `npm update` |  |
| `nci` | `npm ci` |  |
| `nls` | `npm list --depth=0` |  |
| `nout` | `npm outdated` |  |
| `ncc` | `npm cache clean --force` |  |
| `nr` | `npm run` |  |
| `nrd` | `npm run dev` |  |
| `nrs` | `npm run start` |  |
| `ns` | `npm start` |  |
| `nrb` | `npm run build` |  |
| `nrt` | `npm run test` |  |
| `nt` | `npm test` |  |
| `nrl` | `npm run lint` |  |
| `nrf` | `npm run format` |  |
| `nx` | `npx` |  |
| `nrm` | `rm -rf node_modules package-lock.json && npm install` |  |
| `bn` | `bun` |  |
| `bi` | `bun install` |  |
| `ba` | `bun add` |  |
| `bad` | `bun add -d` |  |
| `br` | `bun run` |  |
| `bd` | `bun dev` |  |
| `bb` | `bun build` |  |

### `pkg.sh` — Универсальные алиасы управления пакетами для Arch (paru/pacman) и Ubuntu/Debian (apt)

| Алиас | Команда | Описание |
| --- | --- | --- |
| `install` | `$_pkg -S --noconfirm` |  |
| `remove` | `$_pkg -Rns` |  |
| `search` | `$_pkg -Ss` |  |
| `update` | `$_pkg -Syu --noconfirm` |  |
| `install` | `sudo apt install` |  |
| `remove` | `sudo apt remove` |  |
| `search` | `apt search` |  |
| `update` | `sudo apt update && sudo apt upgrade` |  |

### `system.sh` — Системные алиасы — процессы, сеть, диски, память, функция me с инфой о системе

| Алиас | Команда | Описание |
| --- | --- | --- |
| `ports` | `ss -tulpn` | кто слушает порты (TCP/UDP, с PID процесса) |
| `myip` | `curl -s ifconfig.me` | внешний IP машины |
| `localip` | `hostname -I \| awk '{print \$1}'` | локальный IP в сети |
| `psg` | `ps aux \| grep -v grep \| grep` | поиск процесса по имени: psg nginx |
| `killz` | `kill -9` | принудительно прибить процесс по PID |
| `path` | `echo -e ${PATH//:/\\n}` | вывести PATH построчно (читабельно) |
| `reload` | `source ~/.bashrc` | перечитать bashrc после правок |
| `h` | `history` | история команд |
| `now` | `date +"%Y-%m-%d %H:%M:%S"` | текущая дата/время |
| `week` | `date +%V` | номер текущей недели в году |
| `mem` | `free -h` | использование памяти в человекочитаемом виде |
| `diskspace` | `df -h` | свободное место на дисках |
| `biggest` | `du -h --max-depth=1 \| sort -hr \| head -20` | самые жирные подпапки в текущей директории |

## Скрипты

Доступны через `PATH` как обычные команды (`~/.scripts/`).

| Скрипт | Категория | Описание | Зависимости |
| --- | --- | --- | --- |
| `cheat` | system | Терминальная справка по алиасам и скриптам dotfiles на лету (без README) | awk |
| `extract` | files | Универсальная распаковка архивов по расширению (tar.*, zip, rar, 7z и др.) | tar, gzip, bzip2, unzip, unrar, 7z, xz (по необходимости) |
| `gdup` | content | Загружает файлы на Google Drive через rclone, получает публичную ссылку и кладёт её в буфер обмена | rclone, xclip или wl-copy |
| `gfont` | system | Скачивает шрифт из репозитория google/fonts и устанавливает его локально | curl, jq |
| `gif-from-video` | media | Конвертация видео в качественный gif через ffmpeg с двухпроходной генерацией палитры | ffmpeg |
| `image-converter` | media | Конвертация PNG/JPG ↔ WebP с рекурсивной обработкой каталогов и dry-run режимом | imagemagick (convert) или cwebp/dwebp |
| `install-modern-tools` | system | Установка современных замен классических утилит (bat, eza, fd, ripgrep, btop, dust, duf) для алиасов из modern.sh | paru/pacman (Arch) или apt (Debian/Ubuntu) |
| `md2docx` | content | Конвертация markdown → docx со стилизацией по референсу и опциональной выгрузкой в Google Drive | pandoc, python3+lxml (для пост-обработки таблиц), rclone (для -u), xclip или wl-copy |
| `screenshot-ocr` | media | Снимок выделенной области экрана → OCR → текст в буфер обмена | tesseract (+ tesseract-data-rus/eng), grim+slurp (Wayland) или maim (X11), wl-copy или xclip |
| `ssh-fzf` | network | Интерактивный выбор хоста из ~/.ssh/config через fzf (с превью блока конфига) и подключение по ssh | fzf, ssh |
| `vpnns` | network | Запуск приложений через WireGuard в отдельном сетевом namespace (изолирует VPN-трафик от остальной системы) | wireguard-tools, iproute2, sudo |
| `weather` | info | Погода через wttr.in с автоопределением локации по публичному IP | curl |
| `web-to-markdown` | content | Сохранение веб-страницы как markdown через trafilatura (выделяет основную статью без шапок/футеров) | trafilatura, curl |
| `yt` | content | Извлечение транскрипта (субтитров) с YouTube-видео в текстовый файл | yt-dlp, jq |

<!-- AUTO:END -->
