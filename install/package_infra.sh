#!/usr/bin/env bash
source /kon/install/common.sh
mkdir -p /anvil /opt/tools


# --- Tunneling ---
function install_socat()    { install_apt socat; }
function install_ncat()     { install_apt ncat; }
function install_sshuttle() { install_apt sshuttle; }

function install_chisel() {
    if [[ -d "/opt/tools/chisel" ]]; then
        _info "skip: chisel (already exists)"
        return
    fi
    git clone -q --depth 1 https://github.com/jpillora/chisel /opt/tools/chisel >/dev/null 2>&1 \
        || { _err "git: chisel"; return; }
    cd /opt/tools/chisel && go build -o /usr/local/bin/chisel . >/dev/null 2>&1 \
        && _ok "git: chisel → /usr/local/bin/chisel" \
        || _err "build: chisel"
    cd /anvil
}

function install_ligolo() {
    if [[ -d "/opt/tools/ligolo-ng" ]]; then
        _info "skip: ligolo-ng (already exists)"
        return
    fi
    git clone -q --depth 1 https://github.com/nicocha30/ligolo-ng /opt/tools/ligolo-ng >/dev/null 2>&1 \
        || { _err "git: ligolo-ng"; return; }
    cd /opt/tools/ligolo-ng \
        && go build -o /usr/local/bin/ligolo-proxy ./cmd/proxy >/dev/null 2>&1 \
        && go build -o /usr/local/bin/ligolo-agent ./cmd/agent >/dev/null 2>&1 \
        && _ok "git: ligolo-ng → ligolo-proxy / ligolo-agent" \
        || _err "build: ligolo-ng"
    cd /anvil
}

# --- C2 Frameworks ---
function install_sliver() {
    echo -e "  ${CYAN}bin${RESET} sliver"
    local arch="amd64"
    [[ $(uname -m) == "aarch64" ]] && arch="arm64"
    local url
    url=$(curl -s https://api.github.com/repos/BishopFox/sliver/releases/latest \
        | grep "browser_download_url.*sliver-server.*linux.*${arch}" \
        | grep -o 'https://[^"]*' | head -1)
    if [[ -n "${url}" ]]; then
        curl -sL -o /opt/tools/sliver-server "${url}" && chmod +x /opt/tools/sliver-server
        local client_url
        client_url=$(curl -s https://api.github.com/repos/BishopFox/sliver/releases/latest \
            | grep "browser_download_url.*sliver-client.*linux.*${arch}" \
            | grep -o 'https://[^"]*' | head -1)
        curl -sL -o /opt/tools/sliver-client "${client_url}" && chmod +x /opt/tools/sliver-client
        _ok "bin: sliver"
    else
        _err "bin: sliver"
    fi
}

function install_havoc() {
    _info "skip: Havoc (requires Qt5 + manual build)"
}

function install_villain() {
    if [[ -d "/opt/tools/Villain" ]]; then
        _info "skip: Villain (already exists)"
        return
    fi
    git clone -q --depth 1 https://github.com/t3l3machus/Villain /opt/tools/Villain >/dev/null 2>&1 \
        || { _err "git: Villain"; return; }
    pip3 install -q --no-cache-dir --break-system-packages \
        -r /opt/tools/Villain/requirements.txt >/dev/null 2>&1
    cat > /usr/local/bin/villain << 'EOF'
#!/usr/bin/env bash
exec python3 /opt/tools/Villain/Villain.py "$@"
EOF
    chmod +x /usr/local/bin/villain
    _ok "git: Villain → villain"
}

function install_pwncat() {
    install_pip pwncat-cs
}

function install_metasploit() {
    echo -e "  ${CYAN}bin${RESET} metasploit-framework"
    curl -sL https://raw.githubusercontent.com/rapid7/metasploit-omnibus/master/config/templates/metasploit-framework-wrappers/msfupdate.erb \
        | sed 's/sleep(.*)/sleep(0)/' > /tmp/msfinstall
    chmod +x /tmp/msfinstall
    /tmp/msfinstall >/dev/null 2>&1 \
        && _ok "bin: metasploit" || _err "bin: metasploit"
}

# --- Proxies and pivoting ---
function install_proxify() {
    install_go proxify github.com/projectdiscovery/proxify/cmd/proxify@latest
}

function install_goproxy() {
    install_go goproxy github.com/snail007/goproxy@latest
}

# --- Package runner ---
function package_infra() {
    echo ""
    echo -e "\033[0;36m[*] ┌┬┬ INFRA / C2 ┬┬┐\033[0m"

    # APT
    install_socat
    install_ncat
    install_sshuttle

    # Git + build
    install_chisel
    install_ligolo
    install_villain
    install_havoc

    # Pip
    install_pwncat

    # Bin
    install_sliver
    install_metasploit

    # Go
    install_proxify
    install_goproxy
}
