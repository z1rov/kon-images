#!/usr/bin/env bash

# Author: z1rov

ANVIL="${Z1_ANVIL:-/anvil}"

mkdir -p "${ANVIL}"/
mkdir -p /opt/tools/bin /opt/tools/src /opt/tools/forja
mkdir -p /usr/share/wordlists /usr/share/rules

if [[ -f "/z1/assets/aliases.sh" ]]; then
    grep -qxF "source /z1/assets/aliases.sh" /root/.bashrc 2>/dev/null || \
        echo "source /z1/assets/aliases.sh" >> /root/.bashrc
fi
