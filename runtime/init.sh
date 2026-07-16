#!/usr/bin/env bash

# Author: z1rov

KON_HOME="/kon"

if [[ -f "${KON_HOME}/runtime/workspace.sh" ]]; then
    source "${KON_HOME}/runtime/workspace.sh" || true
fi

if [[ -f "${KON_HOME}/assets/zshrc-kon" ]]; then
    cp "${KON_HOME}/assets/zshrc-kon" /root/.zshrc
fi

exec /bin/zsh --login -i
