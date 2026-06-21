#!/usr/bin/env bash
source /kon/install/common.sh
mkdir -p /anvil /opt/tools

_gh_find_asset() {
    local repo="$1" expr="$2"
    python3 - "${repo}" "${expr}" << 'PYEOF'
import sys, json, urllib.request, ssl

repo = sys.argv[1]
expr = sys.argv[2]

ctx = ssl.create_default_context()
ctx.check_hostname = False
ctx.verify_mode = ssl.CERT_NONE

def fetch(url):
    req = urllib.request.Request(url, headers={"User-Agent": "curl/7.0"})
    with urllib.request.urlopen(req, context=ctx, timeout=15) as r:
        return json.load(r)

endpoints = [
    f"https://api.github.com/repos/{repo}/releases/latest",
    f"https://api.github.com/repos/{repo}/releases?per_page=10",
]

for ep in endpoints:
    try:
        data = fetch(ep)
        releases = data if isinstance(data, list) else [data]
        for release in releases:
            for asset in release.get("assets", []):
                n = asset["name"]
                try:
                    if eval(expr):
                        print(asset["browser_download_url"])
                        sys.exit(0)
                except Exception:
                    pass
    except Exception:
        pass

sys.exit(1)
PYEOF
}

# debug helper: muestra todos los assets de un repo
_gh_list_assets() {
    local repo="$1"
    python3 - "${repo}" << 'PYEOF'
import sys, json, urllib.request, ssl
repo = sys.argv[1]
ctx = ssl.create_default_context()
ctx.check_hostname = False
ctx.verify_mode = ssl.CERT_NONE
req = urllib.request.Request(
    f"https://api.github.com/repos/{repo}/releases/latest",
    headers={"User-Agent": "curl/7.0"})
with urllib.request.urlopen(req, context=ctx, timeout=15) as r:
    data = json.load(r)
for a in data.get("assets", []):
    print(a["name"])
PYEOF
}

function install_socat()    { install_apt socat; }
function install_ncat()     { install_apt ncat; }
function install_sshuttle() { install_apt sshuttle; }

function install_chisel() {
    echo -e "  ${CYAN}bin${RESET} chisel"
    local forja_dir="${KON_FORJA}/chisel"
    mkdir -p "${forja_dir}"

    install_apt unzip

    # Obtener version
    local version
    version=$(python3 - << 'PYEOF'
import urllib.request, json, ssl
ctx = ssl.create_default_context()
ctx.check_hostname = False
ctx.verify_mode = ssl.CERT_NONE
req = urllib.request.Request(
    "https://api.github.com/repos/jpillora/chisel/releases/latest",
    headers={"User-Agent": "curl/7.0"})
with urllib.request.urlopen(req, context=ctx, timeout=15) as r:
    print(json.load(r)["tag_name"].lstrip("v"))
PYEOF
)

    if [[ -z "${version}" ]]; then
        _err "chisel: no se pudo obtener la version del release"
        return
    fi

    _info "chisel version: ${version}"
    local base="https://github.com/jpillora/chisel/releases/download/v${version}"
    local tmp
    tmp=$(mktemp -d)

    # ── Linux amd64 (.gz simple, no tar) ───────────────────────────────
    curl -sL -o "${tmp}/chisel_linux.gz" \
        "${base}/chisel_${version}_linux_amd64.gz"
    gunzip -f "${tmp}/chisel_linux.gz" 2>/dev/null
    if [[ -f "${tmp}/chisel_linux" ]]; then
        chmod +x "${tmp}/chisel_linux"
        cp "${tmp}/chisel_linux" "${KON_BIN}/chisel"
        _ok "bin: chisel (linux/amd64) → ${KON_BIN}/chisel"
    else
        _err "bin: chisel (linux/amd64) — binario no encontrado"
    fi
    rm -rf "${tmp:?}"/*

    # ── Windows amd64 (.zip) ───────────────────────────────────────────
    curl -sL -o "${tmp}/chisel_windows.zip" \
        "${base}/chisel_${version}_windows_amd64.zip"
    mkdir -p "${tmp}/win"
    unzip -q "${tmp}/chisel_windows.zip" -d "${tmp}/win" 2>/dev/null
    local win_bin
    win_bin=$(find "${tmp}/win" -maxdepth 3 -type f -name "*.exe" | head -1)
    if [[ -n "${win_bin}" ]]; then
        cp "${win_bin}" "${forja_dir}/chisel_windows_amd64.exe"
        _ok "forja: chisel (windows/amd64) → ${forja_dir}/chisel_windows_amd64.exe"
    else
        _err "forja: chisel (windows/amd64) — exe no encontrado en zip"
    fi

    rm -rf "${tmp}"
}

function install_ligolo() {
    echo -e "  ${CYAN}bin${RESET} ligolo-ng"
    local forja_dir="${KON_FORJA}/ligolo"
    mkdir -p "${forja_dir}"

    install_apt unzip

    # Obtener version
    local version
    version=$(python3 - << 'PYEOF'
import urllib.request, json, ssl
ctx = ssl.create_default_context()
ctx.check_hostname = False
ctx.verify_mode = ssl.CERT_NONE
req = urllib.request.Request(
    "https://api.github.com/repos/nicocha30/ligolo-ng/releases/latest",
    headers={"User-Agent": "curl/7.0"})
with urllib.request.urlopen(req, context=ctx, timeout=15) as r:
    print(json.load(r)["tag_name"].lstrip("v"))
PYEOF
)

    if [[ -z "${version}" ]]; then
        _err "ligolo-ng: no se pudo obtener la version del release"
        return
    fi

    _info "ligolo-ng version: ${version}"
    local base="https://github.com/nicocha30/ligolo-ng/releases/download/v${version}"
    local tmp
    tmp=$(mktemp -d)

    # ── Linux agent amd64 ─────────────────────────────────────────────
    curl -sL -o "${tmp}/agent_linux.tar.gz" \
        "${base}/ligolo-ng_agent_${version}_linux_amd64.tar.gz"
    tar -xzf "${tmp}/agent_linux.tar.gz" -C "${tmp}" 2>/dev/null
    local agent_bin
    agent_bin=$(find "${tmp}" -maxdepth 3 -type f -name "agent" 2>/dev/null | head -1)
    [[ -z "${agent_bin}" ]] && \
        agent_bin=$(find "${tmp}" -maxdepth 3 -type f \
            ! -name "*.tar.gz" ! -name "*.txt" ! -name "*.md" \
            -perm /111 2>/dev/null | head -1)
    if [[ -n "${agent_bin}" ]]; then
        chmod +x "${agent_bin}"
        cp "${agent_bin}" "${KON_BIN}/ligolo-agent"
        _ok "bin: ligolo-agent (linux/amd64) → ${KON_BIN}/ligolo-agent"
    else
        _err "bin: ligolo-agent (linux/amd64) — binario no encontrado en tar"
    fi
    rm -rf "${tmp:?}"/*

    # ── Linux proxy amd64 ─────────────────────────────────────────────
    curl -sL -o "${tmp}/proxy_linux.tar.gz" \
        "${base}/ligolo-ng_proxy_${version}_linux_amd64.tar.gz"
    tar -xzf "${tmp}/proxy_linux.tar.gz" -C "${tmp}" 2>/dev/null
    local proxy_bin
    proxy_bin=$(find "${tmp}" -maxdepth 3 -type f -name "proxy" 2>/dev/null | head -1)
    [[ -z "${proxy_bin}" ]] && \
        proxy_bin=$(find "${tmp}" -maxdepth 3 -type f \
            ! -name "*.tar.gz" ! -name "*.txt" ! -name "*.md" \
            -perm /111 2>/dev/null | head -1)
    if [[ -n "${proxy_bin}" ]]; then
        chmod +x "${proxy_bin}"
        cp "${proxy_bin}" "${KON_BIN}/ligolo-proxy"
        _ok "bin: ligolo-proxy (linux/amd64) → ${KON_BIN}/ligolo-proxy"
    else
        _err "bin: ligolo-proxy (linux/amd64) — binario no encontrado en tar"
    fi
    rm -rf "${tmp:?}"/*

    # ── Windows agent x64 ─────────────────────────────────────────────
    curl -sL -o "${tmp}/agent_windows.zip" \
        "${base}/ligolo-ng_agent_${version}_windows_amd64.zip"
    mkdir -p "${tmp}/agent_win"
    unzip -q "${tmp}/agent_windows.zip" -d "${tmp}/agent_win" 2>/dev/null
    local agent_win
    agent_win=$(find "${tmp}/agent_win" -maxdepth 3 -type f -name "*.exe" | head -1)
    if [[ -n "${agent_win}" ]]; then
        cp "${agent_win}" "${forja_dir}/ligolo-agent_windows_amd64.exe"
        _ok "forja: ligolo-agent (windows/amd64) → ${forja_dir}/ligolo-agent_windows_amd64.exe"
    else
        _err "forja: ligolo-agent (windows/amd64) — exe no encontrado en zip"
    fi
    rm -rf "${tmp:?}"/*

    # ── Windows proxy x64 ─────────────────────────────────────────────
    curl -sL -o "${tmp}/proxy_windows.zip" \
        "${base}/ligolo-ng_proxy_${version}_windows_amd64.zip"
    mkdir -p "${tmp}/proxy_win"
    unzip -q "${tmp}/proxy_windows.zip" -d "${tmp}/proxy_win" 2>/dev/null
    local proxy_win
    proxy_win=$(find "${tmp}/proxy_win" -maxdepth 3 -type f -name "*.exe" | head -1)
    if [[ -n "${proxy_win}" ]]; then
        cp "${proxy_win}" "${forja_dir}/ligolo-proxy_windows_amd64.exe"
        _ok "forja: ligolo-proxy (windows/amd64) → ${forja_dir}/ligolo-proxy_windows_amd64.exe"
    else
        _err "forja: ligolo-proxy (windows/amd64) — exe no encontrado en zip"
    fi

    rm -rf "${tmp}"
}

function install_sliver() {
    echo -e "  ${CYAN}bin${RESET} sliver"
    local dest_dir="${KON_SRC}/sliver"
    mkdir -p "${dest_dir}"
    local arch="amd64"
    [[ $(uname -m) == "aarch64" ]] && arch="arm64"

    local url_server url_client
    url_server=$(_gh_find_asset "BishopFox/sliver" \
        "'sliver-server' in n and 'linux' in n and '${arch}' in n")
    url_client=$(_gh_find_asset "BishopFox/sliver" \
        "'sliver-client' in n and 'linux' in n and '${arch}' in n")

    if [[ -n "${url_server}" ]]; then
        curl -sL -o "${dest_dir}/sliver-server" "${url_server}"
        chmod +x "${dest_dir}/sliver-server"
        ln -sf "${dest_dir}/sliver-server" "${KON_BIN}/sliver-server"
        _ok "bin: sliver-server → ${KON_BIN}/sliver-server"
    else
        _err "bin: sliver-server"
    fi

    if [[ -n "${url_client}" ]]; then
        curl -sL -o "${dest_dir}/sliver-client" "${url_client}"
        chmod +x "${dest_dir}/sliver-client"
        ln -sf "${dest_dir}/sliver-client" "${KON_BIN}/sliver-client"
        _ok "bin: sliver-client → ${KON_BIN}/sliver-client"
    else
        _err "bin: sliver-client"
    fi
}

function install_villain() {
    local dest="${KON_SRC}/Villain"
    install_git Villain https://github.com/t3l3machus/Villain
    if [[ -f "${dest}/requirements.txt" ]]; then
        python3 -m pip install -q --no-cache-dir --break-system-packages \
            -r "${dest}/requirements.txt" 2>/dev/null || true
    fi
    if [[ -f "${dest}/Villain.py" ]]; then
        printf '#!/usr/bin/env bash\nexec python3 "%s/Villain.py" "$@"\n' \
            "${dest}" > "${KON_BIN}/villain"
        chmod +x "${KON_BIN}/villain"
        _ok "git: Villain → ${KON_BIN}/villain"
    else
        _err "git: Villain (Villain.py not found)"
    fi
}
function install_pwncat() {
    echo -e "  ${CYAN}pip${RESET} pwncat-cs"

    # Desinstalar instalación previa para empezar limpio
    python3 -m pip uninstall -y --break-system-packages \
        pwncat-cs ZODB ZODB3 ZEO zodburi persistent transaction BTrees \
        zc.lockfile zodbpickle zope.interface zope.proxy zope.deferredimport \
        2>/dev/null || true

    # Instalar desde el repo de GitHub (trae todas las deps correctas)
    python3 -m pip install -q --no-cache-dir --break-system-packages \
        "git+https://github.com/calebstewart/pwncat.git" 2>&1 | tail -10

    # Fijar zodburi en el rango que pwncat-cs realmente requiere (<3.0.0)
    python3 -m pip install -q --no-cache-dir --break-system-packages \
        --force-reinstall "zodburi<3.0.0,>=2.5.0" 2>&1 | tail -5

    if command -v pwncat-cs >/dev/null 2>&1; then
        ln -sf "$(command -v pwncat-cs)" "${KON_BIN}/pwncat-cs" 2>/dev/null || true
        _ok "pip: pwncat-cs → ${KON_BIN}/pwncat-cs"
    else
        _err "pip: pwncat-cs"
    fi
}

function install_havoc() {
    echo -e "  ${CYAN}git${RESET} Havoc"
    local dest="${KON_SRC}/Havoc"

    if [[ ! -d "${dest}" ]]; then
        git clone -q --depth 1 --recursive --shallow-submodules \
            https://github.com/HavocFramework/Havoc "${dest}" \
            || { _err "git: Havoc (clone failed)"; return; }
    fi

    cd "${dest}" || return

    install_apt build-essential
    install_apt cmake
    install_apt libboost-all-dev
    install_apt qtmultimedia5-dev
    install_apt libqt5websockets5-dev

    # teamserver — quitar golang-go del script de deps porque ya tenemos go en PATH
    if [[ -f "teamserver/Install.sh" ]]; then
        sed -i 's/\bgolang-go\b//' teamserver/Install.sh
    fi
    make ts-build 2>&1 | tail -3
    if [[ -f "${dest}/havoc" ]]; then
        _ok "build: havoc teamserver"
    else
        _err "build: havoc teamserver"
    fi

    make client-build 2>&1 | tail -3
    if [[ -f "${dest}/havoc" ]]; then
        _ok "build: havoc client"
    fi

    rm -rf "${dest}/client/Build/" 2>/dev/null || true

    # Havoc usa rutas relativas internas → wrapper que cd al src
    if [[ -f "${dest}/havoc" ]]; then
        printf '#!/usr/bin/env bash\ncd "%s" && exec ./havoc "$@"\n' \
            "${dest}" > "${KON_BIN}/havoc"
        chmod +x "${KON_BIN}/havoc"
        _ok "git: Havoc → ${KON_BIN}/havoc"
    else
        _err "git: Havoc (build fallido — binario no encontrado)"
    fi

    cd /anvil
}

function install_metasploit() {
    echo -e "  ${CYAN}git${RESET} metasploit-framework"
    local dest="${KON_SRC}/metasploit-framework"

    install_apt libpcap-dev
    install_apt libpq-dev
    install_apt zlib1g-dev
    install_apt libsqlite3-dev
    install_apt postgresql

    if [[ ! -d "${dest}" ]]; then
        git clone -q --depth 1 \
            https://github.com/rapid7/metasploit-framework.git "${dest}" \
            || { _err "git: metasploit-framework (clone failed)"; return; }
    fi

    cd "${dest}" || return
    git config user.name "kon"
    git config user.email "kon@localhost"

    # rvm: instalar si no existe
    if ! command -v rvm >/dev/null 2>&1; then
        curl -sSL https://rvm.io/mpapis.asc | gpg --import - 2>/dev/null || true
        curl -sSL https://rvm.io/pkuczynski.asc | gpg --import - 2>/dev/null || true
        curl -sSL https://get.rvm.io | bash -s stable >/dev/null 2>&1
    fi
    # source rvm
    # shellcheck disable=SC1091
    [[ -s /etc/profile.d/rvm.sh ]] && source /etc/profile.d/rvm.sh
    [[ -s ~/.rvm/scripts/rvm   ]] && source ~/.rvm/scripts/rvm

    rvm install 3.3.8 --quiet 2>/dev/null || true
    rvm use 3.3.8@metasploit-framework --create --quiet 2>/dev/null || true

    gem install bundler --quiet --no-document 2>/dev/null || true
    bundle install --quiet 2>/dev/null || true
    gem install rex rex-text --quiet --no-document 2>/dev/null || true
    gem install timeout --version 0.4.1 --quiet --no-document 2>/dev/null || true

    # msfdb init
    chmod -R o+rx "${dest}/"
    chmod 444 "${dest}/.git/index" 2>/dev/null || true
    cp -r /root/.bundle /var/lib/postgresql/ 2>/dev/null || true
    chown -R postgres:postgres /var/lib/postgresql/.bundle 2>/dev/null || true

    sudo -u postgres bash -c "
        source /etc/profile.d/rvm.sh 2>/dev/null || source ~/.rvm/scripts/rvm 2>/dev/null || true
        git config --global --add safe.directory ${dest}
        rvm use 3.3.8@metasploit-framework --quiet 2>/dev/null || true
        bundle exec ${dest}/msfdb init 2>/dev/null || true
    " 2>/dev/null || true

    cp -r /var/lib/postgresql/.msf4 /root 2>/dev/null || true

    # peass module
    curl -sL \
        https://raw.githubusercontent.com/peass-ng/PEASS-ng/master/metasploit/peass.rb \
        -o "${dest}/modules/post/multi/gather/peass.rb" 2>/dev/null || true

    # wrappers en KON_BIN — sourcea rvm + activa gemset antes de ejecutar
    # esto soluciona el "LicenseFinder not checked out" que pasa cuando
    # el gemset no está activo al momento de correr el wrapper
    for tool in msfconsole msfvenom msfdb msfrpc msfrpcd msfupdate; do
        if [[ -f "${dest}/${tool}" ]]; then
            cat > "${KON_BIN}/${tool}" << WRAPPER
#!/usr/bin/env bash
[[ -s /etc/profile.d/rvm.sh ]] && source /etc/profile.d/rvm.sh
[[ -s ~/.rvm/scripts/rvm   ]] && source ~/.rvm/scripts/rvm
rvm use 3.3.8@metasploit-framework --quiet 2>/dev/null || true
cd "${dest}"
exec "${dest}/${tool}" "\$@"
WRAPPER
            chmod +x "${KON_BIN}/${tool}"
        fi
    done
    _ok "git: metasploit → ${KON_BIN}/msfconsole + msfvenom + ..."

    cd /anvil
}

function install_proxify() {
    # proxify usa un import path distinto desde v0.0.13
    install_go proxify github.com/projectdiscovery/proxify/cmd/proxify@latest
}

function install_goproxy() {
    install_go goproxy github.com/snail007/goproxy@latest
}

function package_infra() {
    echo ""
    echo -e "\033[0;36m[*] ┌┬┬ INFRA / C2 ┬┬┐\033[0m"

    install_socat
    install_ncat
    install_sshuttle

    install_chisel
    install_ligolo

    install_villain
    install_havoc
    install_pwncat
    install_sliver
    install_metasploit

    install_proxify
    install_goproxy

    echo -e "\033[0;32m[OK]  INFRA package completed${RESET}"
}
