#!/bin/bash
# Описание: Алиасы для npm и bun (управление пакетами и запуск скриптов)
# Категория: npm

# npm
alias n='npm'
alias ni='npm install'
alias nid='npm install --save-dev'
alias nig='npm install -g'
alias nun='npm uninstall'
alias nup='npm update'
alias nci='npm ci'
alias nls='npm list --depth=0'
alias nout='npm outdated'
alias ncc='npm cache clean --force'

# npm scripts
alias nr='npm run'
alias nrd='npm run dev'
alias nrs='npm run start'
alias ns='npm start'
alias nrb='npm run build'
alias nrt='npm run test'
alias nt='npm test'
alias nrl='npm run lint'
alias nrf='npm run format'

# npx
alias nx='npx'

# Полная переустановка зависимостей
alias nrm='rm -rf node_modules package-lock.json && npm install'

# bun
alias bn='bun'
alias bi='bun install'
alias ba='bun add'
alias bad='bun add -d'
alias br='bun run'
alias bd='bun dev'
alias bb='bun build'
