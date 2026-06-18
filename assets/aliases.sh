#!/usr/bin/env bash

# --- Navegación ---
alias anvil='cd /anvil'
alias projects='cd /anvil/projects'
alias loot='cd /anvil/loot'
alias wordlists='cd /usr/share/wordlists'
alias rules='cd /usr/share/rules'

# --- /opt/tools ---
alias tools='cd /opt/tools'
alias tbin='cd /opt/tools/bin'
alias tsrc='cd /opt/tools/src'
alias forja='cd /opt/tools/forja'

# --- Acceso directo a herramientas en forja/ (binarios sueltos, ej. mimikatz 32/64) ---
# Escribes el nombre y te lleva directo a su carpeta dentro de forja/.
alias mimikatz='cd /opt/tools/forja/mimikatz'

# --- Red ---
alias myip='ip -4 addr show | grep inet | awk "{print \$2}"'
alias vpnip='ip -4 addr show tun0 2>/dev/null | awk "/inet /{print \$2}" || echo "no vpn"'
alias ifaces='ip -brief link show'

# --- Utilidades ---
alias ll='ls -lahF --color=auto'
alias la='ls -la --color=auto'
alias grep='grep --color=auto'
alias cls='clear'

# --- KON ---
alias kon-tools='ls /opt/tools/bin/'

# --- Prompt ---
export PS1='\[\033[0;36m\][KON:] \[\033[1;32m\]\w\[\033[0m\] # '

# --- Fix de HOME ---
export HOME=/root
cd /anvil 2>/dev/null || cd /root
