if grep -qi microsoft /proc/version 2>/dev/null; then
  # Тут код, который нужен только в WSL
  #export BROWSER="/mnt/c/Windows/explorer.exe"
  #alias open='explorer.exe'
  # v2rayN mixed proxy from Windows host
  WIN_HOST=$(ip route show | grep -i default | awk '{print $3}')
  export HTTP_PROXY="http://$WIN_HOST:10808"
  export HTTPS_PROXY="http://$WIN_HOST:10808"
  export NO_PROXY="localhost,127.0.0.1,::1"
  export PATH="$HOME/.local/bin:$PATH"
  
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
  [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
fi
