# ~/.zshrc — zsh startup для интерактивных сессий

# 1) Общая часть (PATH, OS-детекция, ssh-agent) — те же файлы что и в bash
for f in ~/.shell/*; do
  [[ -f $f ]] && source "$f"
done

# 2) zsh-специфика (история, completion, prompt)
for f in ~/.zsh/*; do
  [[ -f $f ]] && source "$f"
done

# 3) Алиасы (.sh-файлы написаны в общем подмножестве синтаксиса)
if [ -d ~/.aliases ]; then
  for f in ~/.aliases/*.sh; do
    [ -f "$f" ] && source "$f"
  done
fi

# 4) Локальные оверрайды
[ -f ~/.zshrc.local ] && source ~/.zshrc.local
