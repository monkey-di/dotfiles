#!/bin/bash
# Описание: Алиасы для Claude Code
# Категория: claude

alias cc='claude'                                                                                                              # запустить claude
alias ccd='claude --dangerously-skip-permissions'                                                                              # YOLO: claude без подтверждений на действия
alias vccd='vpnns run claude --dangerously-skip-permissions'                                                                   # YOLO через VPN namespace
alias pccd='https_proxy=http://10.200.0.1:1080 http_proxy=http://10.200.0.1:1080 claude --dangerously-skip-permissions'        # YOLO через прокси (для терминала в Obsidian)
