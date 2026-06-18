#!/usr/bin/env bash

KON_HOME="/kon"

if [[ -f "${KON_HOME}/runtime/workspace.sh" ]]; then
    source "${KON_HOME}/runtime/workspace.sh" || true
fi


# Copiar config de ZSH
if [[ -f "${KON_HOME}/assets/zshrc-kon" ]]; then
    cp "${KON_HOME}/assets/zshrc-kon" /root/.zshrc
fi

# Iniciar ZSH
exec /bin/zsh --login -i
