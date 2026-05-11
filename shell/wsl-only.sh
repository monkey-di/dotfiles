if grep -qi microsoft /proc/version 2>/dev/null; then
  # Тут код, который нужен только в WSL
  export BROWSER="/mnt/c/Windows/explorer.exe"
  alias open='explorer.exe'
fi
