#!/usr/bin/env bash
# Описание: Запуск ssh-agent и автодобавление ключа (кросс-платформенно).
# Категория: shell

# На macOS системный launchd ssh-agent уже работает, и Keychain хранит passphrase
# через `ssh-add --apple-use-keychain` — отдельный agent поднимать не надо.
if [ "$DOTFILES_OS" = "linux" ] && [ -z "${SSH_AUTH_SOCK:-}" ]; then
  eval "$(ssh-agent -s)" >/dev/null
  [ -f "$HOME/.ssh/id_ed25519" ] && ssh-add "$HOME/.ssh/id_ed25519" 2>/dev/null
fi
