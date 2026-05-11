# ~/.bashrc — bash startup для интерактивных сессий

# 1) Общая часть (PATH, OS-детекция, ssh-agent) — работает и в zsh
for f in ~/.shell/*; do
  [[ -f $f ]] && source "$f"
done

# 2) bash-специфика (HISTCONTROL, bind, shopt, prompt)
for f in ~/.bash/*; do
  [[ -f $f ]] && source "$f"
done

# 3) Алиасы
if [ -d ~/.aliases ]; then
  for f in ~/.aliases/*.sh; do
    [ -f "$f" ] && source "$f"
  done
fi

# 4) Локальные оверрайды (секреты, машино-специфичное)
[ -f ~/.bashrc.local ] && source ~/.bashrc.local
