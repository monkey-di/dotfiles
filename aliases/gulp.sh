#!/bin/bash
# Описание: Алиасы для gulp (префикс gl, чтобы не конфликтовать с git-алиасами)
# Категория: gulp

alias gl='gulp'
alias gld='gulp dev'
alias glb='gulp build'
alias glw='gulp watch'
alias gls='gulp serve'
alias glc='gulp clean'
alias glf='gulp default'
alias glt='gulp --tasks'

# Через npx — если gulp-cli не установлен глобально
alias ngl='npx gulp'
alias ngld='npx gulp dev'
alias nglb='npx gulp build'
alias nglw='npx gulp watch'
