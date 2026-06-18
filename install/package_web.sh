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

# ── Feroxbuster (binario suelto → forja/, symlink en bin/) ─────────────────
# Fix: el release de feroxbuster en Linux es .zip, NO .gz — el grep antiguo
# nunca encontraba nada y el binario que quedaba estaba corrupto (exec format
# error). Usamos siempre el instalador oficial (que sabe resolver arch/zip)
# y lo apuntamos a forja/ + bin/ en vez de tirarlo suelto en /opt/tools.
function install_feroxbuster() {
    echo -e "  ${CYAN}bin${RESET} feroxbuster"
    command -v unzip >/dev/null 2>&1 || install_apt unzip

    local dest_dir="${KON_FORJA}/feroxbuster"
    mkdir -p "${dest_dir}"

    curl -sL https://raw.githubusercontent.com/epi052/feroxbuster/main/install-nix.sh \
        | bash -s "${dest_dir}" >/dev/null 2>&1

    if [[ -f "${dest_dir}/feroxbuster" ]]; then
        link_bin feroxbuster "${dest_dir}/feroxbuster"
    else
        _err "bin: feroxbuster"
    fi
}

# ── Rustscan (.deb suelto → forja/, symlink en bin/) ───────────────────────
# Fix: el asset .deb de RustScan se llama "..._amd64.deb", sin "linux" en el
# nombre — el grep viejo exigía x86_64+linux+deb a la vez y nunca matcheaba.
function install_rustscan() {
    echo -e "  ${CYAN}bin${RESET} rustscan"
    local dest_dir="${KON_FORJA}/rustscan"
    mkdir -p "${dest_dir}"

    local api="https://api.github.com/repos/RustScan/RustScan/releases/latest"
    local url
    url=$(curl -s "${api}" \
        | grep -o '"browser_download_url": *"[^"]*amd64[^"]*\.deb"' \
        | grep -o 'https://[^"]*' | head -1)
    [[ -z "${url}" ]] && url=$(curl -s "${api}" \
        | grep -o '"browser_download_url": *"[^"]*x86_64[^"]*\.deb"' \
        | grep -o 'https://[^"]*' | head -1)

    if [[ -z "${url}" ]]; then
        _err "rustscan: no release found"
        return
    fi

    curl -sL -o "${dest_dir}/rustscan.deb" "${url}"
    dpkg -i "${dest_dir}/rustscan.deb" >/dev/null 2>&1 \
        || apt-get -f install -y >/dev/null 2>&1

    local rs_bin
    rs_bin=$(command -v rustscan)
    if [[ -n "${rs_bin}" ]]; then
        link_bin rustscan "${rs_bin}"
    else
        _err "deb: rustscan"
    fi
}

# ── Python tools ────────────────────────────────────────────────────────────
function install_wafw00f() { install_pip wafw00f; }
function install_arjun()   { install_pip arjun; }

# theHarvester: el paquete de PyPI viene atrasado/roto en varios entornos.
# Lo instalamos desde el repo oficial (igual que EyeWitness) en src/ + bin/,
# y usamos "python3 -m pip" para garantizar que las deps van al MISMO
# intérprete que después ejecuta el wrapper (causa típica de
# ModuleNotFoundError aunque pip "diga" que instaló bien).
function install_theharvester() {
    install_git theHarvester https://github.com/laramies/theHarvester
    local dest="${KON_SRC}/theHarvester"

    if [[ -f "${dest}/requirements.txt" ]]; then
        python3 -m pip install -q --no-cache-dir --break-system-packages \
            -r "${dest}/requirements.txt" >/dev/null 2>&1 \
            || _err "pip: theHarvester requirements"
    fi

    if [[ -f "${dest}/theHarvester.py" ]]; then
        cat > "${KON_BIN}/theHarvester" << EOF
#!/usr/bin/env bash
exec python3 "${dest}/theHarvester.py" "\$@"
EOF
        chmod +x "${KON_BIN}/theHarvester"
        _ok "git: theHarvester"
    else
        _err "git: theHarvester"
    fi
}

# ── Git tools ────────────────────────────────────────────────────────────
# Fix: install_git ahora clona en KON_SRC/nikto (/opt/tools/src/nikto), pero
# el check viejo seguía buscando /opt/tools/nikto/program/nikto.pl → nunca
# encontraba el archivo y el symlink jamás se creaba.
function install_nikto() {
    install_git nikto https://github.com/sullo/nikto
    link_bin nikto "${KON_SRC}/nikto/program/nikto.pl"
}

# Fix: clonaba directo a /opt/tools/EyeWitness (rompiendo la convención
# src/), y el pip install de requirements.txt no chequeaba el resultado, así
# que un fallo (p.ej. netaddr) quedaba en silencio. Movido a KON_SRC, wrapper
# en KON_BIN, y "python3 -m pip" por la misma razón que en theHarvester.
function install_eyewitness() {
    install_git EyeWitness https://github.com/RedSiege/EyeWitness
    local dest="${KON_SRC}/EyeWitness"

    if [[ -f "${dest}/Python/requirements.txt" ]]; then
        python3 -m pip install -q --no-cache-dir --break-system-packages \
            -r "${dest}/Python/requirements.txt" >/dev/null 2>&1 \
            || _err "pip: EyeWitness requirements"
    fi

    if [[ -f "${dest}/Python/EyeWitness.py" ]]; then
        cat > "${KON_BIN}/eyewitness" << EOF
#!/usr/bin/env bash
exec python3 "${dest}/Python/EyeWitness.py" "\$@"
EOF
        chmod +x "${KON_BIN}/eyewitness"
        _ok "git: EyeWitness"
    else
        _err "git: EyeWitness"
    fi
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
