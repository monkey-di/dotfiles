# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

for f in ~/.bash/*; do
  [[ -f $f ]] && source "$f"
done

if [ -f ~/.bash_aliases ]; then
  . ~/.bash_aliases
fi

# Load all alias files from .aliases directory
if [ -d ~/.aliases ]; then
  for file in ~/.aliases/*.sh; do
    if [ -f "$file" ]; then
      . "$file"
    fi
  done
fi

# Start ssh-agent and add SSH key automatically
if [ -z "$SSH_AUTH_SOCK" ]; then
  eval "$(ssh-agent -s)" >/dev/null
  ssh-add ~/.ssh/id_ed25519 2>/dev/null
fi

# Local overrides (secrets, machine-specific settings)
[ -f ~/.bashrc.local ] && . ~/.bashrc.local
