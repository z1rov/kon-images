#!/usr/bin/env bash
source /kon/install/common.sh
mkdir -p /opt/tools 

# ── APT ─────────────────────────────────────────────────────────────────
function install_nmap()     { install_apt nmap; }
function install_masscan()  { install_apt masscan; }
function install_whois()    { install_apt whois; }
function install_dnsutils() { install_apt dnsutils; }
function install_netcat()   { install_apt ncat; }
function install_jq()       { install_apt jq; }
function install_dirb()     { install_apt dirb; }

# ── GO tools (requieren Go 1.21+ — ver Dockerfile) ────────────────────────
function install_subfinder() {
    install_go subfinder github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
}

function install_httpx() {
    install_go httpx github.com/projectdiscovery/httpx/cmd/httpx@latest
}

function install_nuclei() {
    install_go nuclei github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest
}

function install_dnsx() {
    install_go dnsx github.com/projectdiscovery/dnsx/cmd/dnsx@latest
}

function install_naabu() {
    install_go naabu github.com/projectdiscovery/naabu/v2/cmd/naabu@latest
}

function install_katana() {
    install_go katana github.com/projectdiscovery/katana/cmd/katana@latest
}

function install_tlsx() {
    install_go tlsx github.com/projectdiscovery/tlsx/cmd/tlsx@latest
}

function install_alterx() {
    install_go alterx github.com/projectdiscovery/alterx/cmd/alterx@latest
}

function install_ffuf() {
    install_go ffuf github.com/ffuf/ffuf/v2@latest
}

function install_gobuster() {
    install_go gobuster github.com/OJ/gobuster/v3@latest
}

function install_amass() {
    install_go amass github.com/owasp-amass/amass/v4/...@master
}

# ── Feroxbuster (binary release — sin Rust) ────────────────────────────────
function install_feroxbuster() {
    echo -e "  ${CYAN}bin${RESET} feroxbuster"
    local arch="x86_64"
    [[ $(uname -m) == "aarch64" ]] && arch="aarch64"
    local url
    url=$(curl -s https://api.github.com/repos/epi052/feroxbuster/releases/latest \
        | grep "browser_download_url.*${arch}.*linux.*gz\"" \
        | grep -o 'https://[^"]*' | head -1)
    if [[ -n "${url}" ]]; then
        curl -sL "${url}" | gunzip > /opt/tools/feroxbuster 2>/dev/null \
            && chmod +x /opt/tools/feroxbuster \
            && _ok "bin: feroxbuster" \
            || _err "bin: feroxbuster"
    else
        # fallback: install script oficial
        curl -sL https://raw.githubusercontent.com/epi052/feroxbuster/main/install-nix.sh \
            | bash -s /opt/tools >/dev/null 2>&1 \
            && _ok "bin: feroxbuster (fallback)" || _err "bin: feroxbuster"
    fi
}

# ── Rustscan (binary release) ──────────────────────────────────────────────
function install_rustscan() {
    echo -e "  ${CYAN}bin${RESET} rustscan"
    local url
    # busca .deb para x86_64 (musl o gnu)
    url=$(curl -s https://api.github.com/repos/RustScan/RustScan/releases/latest \
        | grep "browser_download_url.*x86_64.*linux.*\.deb\"" \
        | grep -o 'https://[^"]*' | head -1)
    # fallback: cualquier .deb disponible
    [[ -z "${url}" ]] && url=$(curl -s https://api.github.com/repos/RustScan/RustScan/releases/latest \
        | grep "browser_download_url.*\.deb\"" \
        | grep -o 'https://[^"]*' | head -1)
    if [[ -n "${url}" ]]; then
        curl -sL -o /tmp/rustscan.deb "${url}" \
            && dpkg -i /tmp/rustscan.deb >/dev/null 2>&1 \
            && rm -f /tmp/rustscan.deb \
            && _ok "deb: rustscan" || _err "deb: rustscan"
    else
        _err "rustscan: no release found"
    fi
}

# ── Python tools ────────────────────────────────────────────────────────────
function install_theharvester() { install_pip theHarvester; }
function install_wafw00f()      { install_pip wafw00f; }
function install_arjun()        { install_pip arjun; }

# ── Git tools ────────────────────────────────────────────────────────────
function install_nikto() {
    install_git nikto https://github.com/sullo/nikto
    [[ -f /opt/tools/nikto/program/nikto.pl ]] \
        && ln -sf /opt/tools/nikto/program/nikto.pl /usr/local/bin/nikto
}

function install_eyewitness() {
    [[ -d "/opt/tools/EyeWitness" ]] && { _info "skip: EyeWitness"; return; }
    git clone -q --depth 1 https://github.com/RedSiege/EyeWitness /opt/tools/EyeWitness >/dev/null 2>&1 \
        || { _err "git: EyeWitness"; return; }
    pip3 install -q --no-cache-dir --break-system-packages \
        -r /opt/tools/EyeWitness/Python/requirements.txt >/dev/null 2>&1
    cat > /usr/local/bin/eyewitness << 'EOF'
#!/usr/bin/env bash
exec python3 /opt/tools/EyeWitness/Python/EyeWitness.py "$@"
EOF
    chmod +x /usr/local/bin/eyewitness
    _ok "git: EyeWitness"
}

# ── Package runner ────────────────────────────────────────────────────────
function package_recon() {
    echo ""
    echo -e "\033[0;36m[*] ┌┬┬ RECON ┬┬┐\033[0m"

    # APT
    install_nmap
    install_masscan
    install_whois
    install_dnsutils
    install_netcat
    install_jq
    install_dirb

    # Go (projectdiscovery suite)
    install_subfinder
    install_httpx
    install_nuclei
    install_dnsx
    install_naabu
    install_katana
    install_tlsx
    install_alterx

    # Go (otros)
    install_ffuf
    install_gobuster
    install_amass

    # Binaries
    install_feroxbuster
    install_rustscan

    # Python
    install_theharvester
    install_wafw00f
    install_arjun

    # Git
    install_nikto
    install_eyewitness
}
