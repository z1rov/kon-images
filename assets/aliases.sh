#!/usr/bin/env bash

# Author: z1rov

alias anvil='cd /anvil'
alias projects='cd /anvil/projects'
alias loot='cd /anvil/loot'
alias wordlists='cd /usr/share/wordlists'
alias rules='cd /usr/share/rules'
alias tools='cd /opt/tools'
alias tbin='cd /opt/tools/bin'
alias tsrc='cd /opt/tools/src'
alias forja='cd /opt/tools/forja'
alias mimikatz='cd /opt/tools/forja/mimikatz'
alias myip='ip -4 addr show | grep inet | awk "{print \$2}"'
alias vpnip='ip -4 addr show tun0 2>/dev/null | awk "/inet /{print \$2}" || echo "no vpn"'
alias ifaces='ip -brief link show'
alias ll='ls -lahF --color=auto'
alias la='ls -la --color=auto'
alias grep='grep --color=auto'
alias cls='clear'
alias kon-tools='ls /opt/tools/bin/'
export PS1='\[\033[0;36m\][KON:] \[\033[1;32m\]\w\[\033[0m\] # '
export HOME=/root
cd /anvil 2>/dev/null || cd /root
