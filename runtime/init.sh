#!/usr/bin/env bash

# Author: z1rov

Z1_HOME="/z1"

if [[ -f "${Z1_HOME}/runtime/workspace.sh" ]]; then
    source "${Z1_HOME}/runtime/workspace.sh" || true
fi

if [[ -f "${Z1_HOME}/assets/zshrc-z1" ]]; then
    cp "${Z1_HOME}/assets/zshrc-z1" /root/.zshrc
fi

exec /bin/zsh --login -i
