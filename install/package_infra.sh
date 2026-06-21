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

    # ── Linux amd64 (.gz simple, no tar) — único target de este script ──
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

    rm -rf "${tmp}"
    # Nota: el .exe de Windows se descarga en package_binaries.sh
    # (install_chisel_win), junto al resto de binarios para servir a targets.
}

function install_ligolo() {
    echo -e "  ${CYAN}bin${RESET} ligolo-ng"

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

    rm -rf "${tmp}"
    # Nota: los .exe de Windows (agent/proxy) se descargan en
    # package_binaries.sh (install_ligolo_win).
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
     colorecho "Installing pwncat-vl"

    _ensure_pipx || return 1

    # ── Instalar vía pipx ──
    local log rc
    log=$(pipx install --system-site-packages pwncat-vl 2>&1)
    rc=$?
    if [[ ${rc} -eq 0 ]]; then
        _ok "pipx: pwncat-vl"
    else
        _err "pipx: pwncat-vl (rc=${rc})"
        echo "----- output -----"
        echo "${log}" | tail -20
        echo "-------------------"
        return 1
    fi

    # ── Downgrade cryptography (Blowfish deprecado) ──
    # https://github.com/paramiko/paramiko/issues/2038
    log=$(pipx inject pwncat-vl "cryptography==36.0.2" 2>&1)
    rc=$?
    if [[ ${rc} -eq 0 ]]; then
        _ok "pipx: inject cryptography==36.0.2"
    else
        _err "pipx: inject cryptography==36.0.2 (rc=${rc})"
        echo "----- output -----"
        echo "${log}" | tail -10
        echo "-------------------"
        return 1
    fi

    # ── Verificar ──
    if command -v pwncat-vl >/dev/null 2>&1 && pwncat-vl --help >/dev/null 2>&1; then
        _ok "pwncat-vl: instalado correctamente 🎉"
    else
        _err "pwncat-vl: verificación falló"
        pwncat-vl --help 2>&1 | tail -15
    fi
}
function install_havoc() {
    colorecho "Installing Havoc"

    local dest="${KON_SRC}/Havoc"

    # ── Clonar repositorio (con submódulos, shallow) ──
    if [[ -d "${dest}" ]]; then
        _info "Havoc repo ya existe, eliminando antes de re-clonar"
        rm -rf "${dest}"
    fi

    local log rc
    log=$(git clone --depth 1 --recursive --shallow-submodules \
        https://github.com/HavocFramework/Havoc "${dest}" 2>&1)
    rc=$?
    if [[ ${rc} -eq 0 ]]; then
        _ok "git: Havoc → ${dest}"
    else
        _err "git: Havoc (rc=${rc})"
        echo "----- output -----"; echo "${log}" | tail -20; echo "-------------------"
        return 1
    fi

    cd "${dest}" || { _err "cd: ${dest}"; return 1; }

    # ── Building Team Server ──
    sed -i 's/golang-go//' teamserver/Install.sh

    # https://github.com/HavocFramework/Havoc/issues/312
    # `make ts-build` corre teamserver/Install.sh, que descarga con
    # `wget -q` dos toolchains musl-cross desde musl.cc:
    #   /tmp/mingw-musl-64.tgz  y  /tmp/mingw-musl-32.tgz
    # Si la red corta a medias, queda un .tgz truncado que `make clean`
    # NO borra, y cada intento posterior reutiliza ese mismo archivo roto.
    local attempt
    rc=1
    for attempt in 1 2 3; do
        rm -f /tmp/mingw-musl-64.tgz /tmp/mingw-musl-32.tgz
        log=$(make ts-build 2>&1)
        rc=$?
        if [[ ${rc} -eq 0 ]]; then
            break
        fi
        _info "make ts-build falló (intento ${attempt}/3), borrando .tgz truncados (musl.cc) y reintentando"
        sleep 3
    done

    if [[ ${rc} -eq 0 ]]; then
        _ok "make: ts-build"
    else
        _err "make: ts-build (rc=${rc}) tras 3 intentos"
        echo "----- output -----"; echo "${log}" | tail -40; echo "-------------------"
        _info "si persiste, revisar conectividad a musl.cc (puede estar caído/inestable):"
        _info "  curl -sI https://musl.cc/x86_64-w64-mingw32-cross.tgz"
        return 1
    fi

    # ── Building Client ──
    install_apt qtmultimedia5-dev
    install_apt libqt5websockets5-dev

    log=$(make client-build 2>&1)
    rc=$?
    if [[ ${rc} -eq 0 ]]; then
        _ok "make: client-build"
    else
        _err "make: client-build (rc=${rc})"
        echo "----- output -----"; echo "${log}" | tail -40; echo "-------------------"
        if [[ -f "${dest}/client/Build/CMakeFiles/CMakeOutput.log" ]]; then
            echo "----- CMakeOutput.log (tail) -----"
            tail -40 "${dest}/client/Build/CMakeFiles/CMakeOutput.log"
            echo "-----------------------------------"
        fi
        return 1
    fi

    # `make clean` elimina los binarios igual, así que solo borramos el
    # directorio de build del client para liberar espacio.
    rm -rf "${dest}/client/Build/"

    # ── Wrapper en bin/ ──
    # No usamos symlink directo: Havoc resuelve rutas relativas (profiles/,
    # data/, etc.) respecto al directorio desde donde se ejecuta, así que
    # un symlink plano rompería todo si se corre desde otro cwd.
    cat > "${KON_BIN}/havoc" << EOF
#!/usr/bin/env bash
cd "${dest}" && exec ./havoc "\$@"
EOF
    chmod +x "${KON_BIN}/havoc"
    _ok "bin: havoc → ${KON_BIN}/havoc (wrapper, cd a ${dest})"

    # ── Verificar ──
    if [[ -x "${dest}/havoc" ]] && [[ -x "${KON_BIN}/havoc" ]]; then
        _ok "havoc: instalado correctamente 🎉 (havoc server --profile ...)"
    else
        _err "havoc: verificación falló (binario o wrapper no encontrado)"
    fi
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
