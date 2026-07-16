#!/usr/bin/env bash

# Author: z1rov

ANVIL="${KON_ANVIL:-/anvil}"

mkdir -p "${ANVIL}"/
mkdir -p /opt/tools/bin /opt/tools/src /opt/tools/forja
mkdir -p /usr/share/wordlists /usr/share/rules

if [[ -f "/kon/assets/aliases.sh" ]]; then
    grep -qxF "source /kon/assets/aliases.sh" /root/.bashrc 2>/dev/null || \
        echo "source /kon/assets/aliases.sh" >> /root/.bashrc
fi
