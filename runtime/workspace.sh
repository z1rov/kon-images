#!/usr/bin/env bash

ANVIL="${KON_ANVIL:-/anvil}"

# Crear directorios del workspace
mkdir -p "${ANVIL}"/

# Estructura canónica de herramientas (debe existir incluso si las
# capas de instalación están desactivadas en el Dockerfile)
mkdir -p /opt/tools/bin /opt/tools/src /opt/tools/forja
mkdir -p /usr/share/wordlists /usr/share/rules

# Cargar aliases en bash
if [[ -f "/kon/assets/aliases.sh" ]]; then
    grep -qxF "source /kon/assets/aliases.sh" /root/.bashrc 2>/dev/null || \
        echo "source /kon/assets/aliases.sh" >> /root/.bashrc
fi
