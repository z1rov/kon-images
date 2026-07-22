#!/usr/bin/env bash
# Author: z1rov

function install_socat()    { install_apt socat; }
function install_ncat()     { install_apt ncat; }
function install_sshuttle() { install_apt sshuttle; }

function install_chisel() {
    install_apt unzip

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
        _err "chisel: could not get the release version"; return 1
    fi
    _info "chisel version: ${version}"

    local base="https://github.com/jpillora/chisel/releases/download/v${version}"
    local tmp; tmp=$(mktemp -d)

    curl -sL -o "${tmp}/chisel_linux.gz" "${base}/chisel_${version}_linux_amd64.gz"
    gunzip -f "${tmp}/chisel_linux.gz" 2>/dev/null
    if [[ -f "${tmp}/chisel_linux" ]]; then
        chmod +x "${tmp}/chisel_linux"
        cp "${tmp}/chisel_linux" "${Z1_BIN}/chisel"
        _ok "bin: chisel (linux/amd64) â†’ ${Z1_BIN}/chisel"
    else
        _err "bin: chisel (linux/amd64) â€” binary not found"
    fi
    rm -rf "${tmp}"
}

function install_ligolo() {
    install_apt unzip

    local version version_err
    version=$(python3 - << 'PYEOF' 2>/tmp/ligolo_ver_err
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
    version_err=$(cat /tmp/ligolo_ver_err 2>/dev/null); rm -f /tmp/ligolo_ver_err

    if [[ -z "${version}" ]]; then
        _err "ligolo-ng: could not get the release version"
        return 1
    fi
    _info "ligolo-ng version: ${version}"

    local base="https://github.com/nicocha30/ligolo-ng/releases/download/v${version}"
    local tmp; tmp=$(mktemp -d)

    local url="${base}/ligolo-ng_agent_${version}_linux_amd64.tar.gz"
    curl -sL -o "${tmp}/agent_linux.tar.gz" "${url}"
    if ! tar -tzf "${tmp}/agent_linux.tar.gz" >/dev/null 2>&1; then
        _err "bin: ligolo-agent â€” invalid download (${url})"
    else
        tar -xzf "${tmp}/agent_linux.tar.gz" -C "${tmp}" 2>/dev/null
        local agent_bin
        agent_bin=$(find "${tmp}" -maxdepth 3 -type f -name "agent" 2>/dev/null | head -1)
        if [[ -n "${agent_bin}" ]]; then
            chmod +x "${agent_bin}"
            cp "${agent_bin}" "${Z1_BIN}/ligolo-agent"
            _ok "bin: ligolo-agent (linux/amd64) â†’ ${Z1_BIN}/ligolo-agent"
        else
            _err "bin: ligolo-agent â€” binary 'agent' not found after extraction"
        fi
    fi
    rm -rf "${tmp:?}"/*

    url="${base}/ligolo-ng_proxy_${version}_linux_amd64.tar.gz"
    curl -sL -o "${tmp}/proxy_linux.tar.gz" "${url}"
    if ! tar -tzf "${tmp}/proxy_linux.tar.gz" >/dev/null 2>&1; then
        _err "bin: ligolo-proxy â€” invalid download (${url})"
    else
        tar -xzf "${tmp}/proxy_linux.tar.gz" -C "${tmp}" 2>/dev/null
        local proxy_bin
        proxy_bin=$(find "${tmp}" -maxdepth 3 -type f -name "proxy" 2>/dev/null | head -1)
        if [[ -n "${proxy_bin}" ]]; then
            chmod +x "${proxy_bin}"
            cp "${proxy_bin}" "${Z1_BIN}/ligolo-proxy"
            _ok "bin: ligolo-proxy (linux/amd64) â†’ ${Z1_BIN}/ligolo-proxy"
        else
            _err "bin: ligolo-proxy â€” binary 'proxy' not found after extraction"
        fi
    fi
    rm -rf "${tmp}"
}

function install_havoc() {
    local dest="${Z1_SRC}/Havoc"
    if [[ -d "${dest}" ]]; then
        _info "Havoc repo already exists, removing before re-cloning"
        rm -rf "${dest}"
    fi

    local log rc
    log=$(git clone --depth 1 --recursive --shallow-submodules \
        https://github.com/HavocFramework/Havoc "${dest}" 2>&1)
    rc=$?
    if [[ ${rc} -eq 0 ]]; then
        _ok "git: Havoc â†’ ${dest}"
    else
        _err "git: Havoc (rc=${rc})"
        return 1
    fi

    apt-get update -y >/dev/null 2>&1
    for pkg in \
        build-essential cmake git wget \
        libssl-dev libz-dev mingw-w64 \
        nasm python3-dev \
        qtbase5-dev qt5-qmake qtmultimedia5-dev libqt5websockets5-dev; do
        install_apt "${pkg}"
    done

    cd "${dest}" || { _err "cd: ${dest}"; return 1; }

    if ! command -v go >/dev/null 2>&1 || ! go version | grep -qE 'go1\.(2[3-9]|[3-9][0-9])'; then
        _info "havoc: installing Go 1.23+ (required for ts-build)"
        local go_version="1.23.5"
        local go_arch="amd64"
        [[ $(uname -m) == "aarch64" ]] && go_arch="arm64"
        
        curl -fsSL "https://go.dev/dl/go${go_version}.linux-${go_arch}.tar.gz" \
            -o /tmp/go.tar.gz
        rm -rf /usr/local/go
        tar -C /usr/local -xzf /tmp/go.tar.gz
        rm /tmp/go.tar.gz
        export PATH="/usr/local/go/bin:$PATH"
    fi
    _info "havoc: using $(go version)"

    if [[ -f teamserver/Install.sh ]]; then
        sed -i \
            -e '/golang-go/d' \
            -e '/go[0-9]\+\.[0-9]/d' \
            -e '/go\.tar/d' \
            -e '/curl.*go.*linux/d' \
            -e '/tar.*go.*tar/d' \
            -e '/rm.*go.*tar/d' \
            teamserver/Install.sh
        _info "havoc: Install.sh patched"
    fi

    if [[ -f teamserver/go.mod ]]; then
        sed -i 's/go 1\.[0-9]*\.[0-9]/go 1.23/' teamserver/go.mod
        _info "havoc: go.mod updated"
    fi

    if [[ -f teamserver/go.mod ]]; then
        cd "${dest}/teamserver"
        _info "havoc: running go mod tidy..."
        if ! go mod tidy 2>&1; then
            _warn "havoc: go mod tidy had warnings (continuing)"
        fi
        _ok "havoc: go mod tidy completed"
        cd "${dest}"
    fi

    if [[ -f makefile ]]; then
        sed -i \
            -e 's|teamserver/go/bin/go|go|g' \
            -e 's|\./go/bin/go|go|g' \
            makefile
        
        if grep -q 'curl.*go.*linux' makefile; then
            _warn "makefile still tries to download Go â€” removing"
            sed -i '/curl.*go.*linux/d' makefile
        fi
        
        _info "havoc: makefile patched"
    fi

    _info "havoc: building teamserver..."
    local ts_attempt ts_max_attempts=3
    rc=1
    for ((ts_attempt=1; ts_attempt<=ts_max_attempts; ts_attempt++)); do
        log=$(make ts-build 2>&1)
        rc=$?
        if [[ ${rc} -eq 0 ]]; then
            break
        fi
        if echo "${log}" | grep -qiE 'gzip: stdin: unexpected end of file|tar: Child returned status|tar: Unexpected EOF'; then
            _info "havoc: ts-build attempt ${ts_attempt}/${ts_max_attempts} failed (musl.cc mingw toolchain download likely truncated), retrying..."
            sleep 5
            continue
        fi
        break
    done
    if [[ ${rc} -eq 0 ]]; then
        _ok "make: ts-build"
    else
        _err "make: ts-build (rc=${rc}) after ${ts_max_attempts} attempts"
        _err "Log: $(echo "$log" | head -20)"
        return 1
    fi

    _info "havoc: building client..."
    log=$(make client-build 2>&1)
    rc=$?
    if [[ ${rc} -eq 0 ]]; then
        _ok "make: client-build"
    else
        _err "make: client-build (rc=${rc})"
        return 1
    fi

    rm -rf "${dest}/client/Build/"

    cat > "${Z1_BIN}/havoc" << EOF
#!/usr/bin/env bash
cd "${dest}" && exec ./havoc "\$@"
EOF
    chmod +x "${Z1_BIN}/havoc"
    _ok "havoc installed â†’ ${Z1_BIN}/havoc"
}


function _install_golang_latest() {
    local go_version="1.23.5"
    local go_arch="amd64"
    [[ $(uname -m) == "aarch64" ]] && go_arch="arm64"
    
    local go_file="go${go_version}.linux-${go_arch}.tar.gz"
    local go_url="https://go.dev/dl/${go_file}"
    local tmp; tmp=$(mktemp -d)
    
    _info "Go: downloading version ${go_version} (${go_arch})..."
    curl -sL -o "${tmp}/${go_file}" "${go_url}"
    
    if [[ ! -f "${tmp}/${go_file}" ]]; then
        _err "Go: download failed"
        rm -rf "${tmp}"
        return 1
    fi
    
    _info "Go: extracting to /usr/local..."
    rm -rf /usr/local/go 2>/dev/null || true
    tar -xzf "${tmp}/${go_file}" -C /usr/local
    rm -rf "${tmp}"
    
    export PATH="/usr/local/go/bin:$PATH"
    
    if command -v go >/dev/null 2>&1; then
        _ok "Go: $(go version)"
        return 0
    else
        _err "Go: installation failed"
        return 1
    fi
}

function install_sliver() {
    local dest_dir="${Z1_SRC}/sliver"
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
        ln -sf "${dest_dir}/sliver-server" "${Z1_BIN}/sliver-server"
        _ok "bin: sliver-server â†’ ${Z1_BIN}/sliver-server"
    else
        _err "bin: sliver-server"
    fi

    if [[ -n "${url_client}" ]]; then
        curl -sL -o "${dest_dir}/sliver-client" "${url_client}"
        chmod +x "${dest_dir}/sliver-client"
        ln -sf "${dest_dir}/sliver-client" "${Z1_BIN}/sliver-client"
        _ok "bin: sliver-client â†’ ${Z1_BIN}/sliver-client"
    else
        _err "bin: sliver-client"
    fi
}

function install_villain() {
    local dest="${Z1_SRC}/Villain"
    install_git Villain https://github.com/t3l3machus/Villain
    if [[ -f "${dest}/requirements.txt" ]]; then
        python3 -m pip install -q --no-cache-dir --break-system-packages \
            -r "${dest}/requirements.txt" 2>/dev/null || true
    fi
    if [[ -f "${dest}/Villain.py" ]]; then
        printf '#!/usr/bin/env bash\nexec python3 "%s/Villain.py" "$@"\n' \
            "${dest}" > "${Z1_BIN}/villain"
        chmod +x "${Z1_BIN}/villain"
        _ok "git: Villain â†’ ${Z1_BIN}/villain"
    else
        _err "git: Villain (Villain.py not found)"
    fi
}

function install_pwncat() {
    _ensure_pipx || return 1

    local log rc
    log=$(pipx install --system-site-packages pwncat-vl 2>&1)
    rc=$?
    if [[ ${rc} -eq 0 ]]; then
        _ok "pipx: pwncat-vl"
    else
        _err "pipx: pwncat-vl (rc=${rc})"
        return 1
    fi

    log=$(pipx inject pwncat-vl "cryptography==36.0.2" 2>&1)
    rc=$?
    if [[ ${rc} -eq 0 ]]; then
        _ok "pipx: inject cryptography==36.0.2"
    else
        _err "pipx: inject cryptography==36.0.2 (rc=${rc})"
        return 1
    fi

    if command -v pwncat-vl >/dev/null 2>&1 && pwncat-vl --help >/dev/null 2>&1; then
        _ok "pwncat-vl: installed successfully ðŸŽ‰"
    else
        _err "pwncat-vl: verification failed"
    fi
}

function install_penelope() {
    _ensure_pipx || return 1

    local log rc
    log=$(pipx install --system-site-packages penelope-shell-handler 2>&1)
    rc=$?
    if [[ ${rc} -eq 0 ]]; then
        _ok "pipx: penelope-shell-handler"
    else
        _err "pipx: penelope-shell-handler (rc=${rc})"
        return 1
    fi

    if command -v penelope >/dev/null 2>&1 && penelope --help >/dev/null 2>&1; then
        _ok "penelope: installed successfully ðŸŽ‰"
    else
        _err "penelope: verification failed"
    fi
}

function install_metasploit() {
    local dest="${Z1_SRC}/metasploit-framework"

    for pkg in libpcap-dev libpq-dev zlib1g-dev libsqlite3-dev postgresql; do
        install_apt "${pkg}"
    done

    if [[ ! -d "${dest}" ]]; then
        git clone -q --depth 1 \
            https://github.com/rapid7/metasploit-framework.git "${dest}" \
            || { _err "git: metasploit-framework (clone failed)"; return; }
    fi

    cd "${dest}" || return
    git config user.name "z1"
    git config user.email "z1@localhost"

    if ! command -v rvm >/dev/null 2>&1; then
        curl -sSL https://rvm.io/mpapis.asc | gpg --import - 2>/dev/null || true
        curl -sSL https://rvm.io/pkuczynski.asc | gpg --import - 2>/dev/null || true
        curl -sSL https://get.rvm.io | bash -s stable >/dev/null 2>&1
    fi
    [[ -s /etc/profile.d/rvm.sh ]] && source /etc/profile.d/rvm.sh
    [[ -s ~/.rvm/scripts/rvm   ]] && source ~/.rvm/scripts/rvm

    rvm install 3.3.8 --quiet 2>/dev/null || true
    rvm use 3.3.8@metasploit-framework --create --quiet 2>/dev/null || true

    gem install bundler --quiet --no-document 2>/dev/null || true
    bundle install --quiet 2>/dev/null || true
    gem install rex rex-text --quiet --no-document 2>/dev/null || true
    gem install timeout --version 0.4.1 --quiet --no-document 2>/dev/null || true

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

    curl -sL \
        https://raw.githubusercontent.com/peass-ng/PEASS-ng/master/metasploit/peass.rb \
        -o "${dest}/modules/post/multi/gather/peass.rb" 2>/dev/null || true

    for tool in msfconsole msfvenom msfdb msfrpc msfrpcd msfupdate; do
        if [[ -f "${dest}/${tool}" ]]; then
            cat > "${Z1_BIN}/${tool}" << WRAPPER
#!/usr/bin/env bash
[[ -s /etc/profile.d/rvm.sh ]] && source /etc/profile.d/rvm.sh
[[ -s ~/.rvm/scripts/rvm   ]] && source ~/.rvm/scripts/rvm
rvm use 3.3.8@metasploit-framework --quiet 2>/dev/null || true
cd "${dest}"
exec "${dest}/${tool}" "\$@"
WRAPPER
            chmod +x "${Z1_BIN}/${tool}"
        fi
    done
    _ok "git: metasploit â†’ ${Z1_BIN}/msfconsole + msfvenom + ..."

    cd /
}

function install_proxify() {
    install_go proxify github.com/projectdiscovery/proxify/cmd/proxify@latest
}

function install_goproxy() {
    install_go goproxy github.com/snail007/goproxy@latest
}


function install_netexec() {
    local NXC_DIR="${Z1_SRC}/NetExec"
    install_rust || { _err "netexec: aborting, rust toolchain required to build aardwolf"; return 1; }
    [[ -f "${HOME}/.cargo/env" ]] && source "${HOME}/.cargo/env"
    if [[ -d "${NXC_DIR}" ]]; then
        _info "skip: netexec (already exists)"
    else
        git clone -q --depth 1 https://github.com/Pennyw0rth/NetExec "${NXC_DIR}" >/dev/null 2>&1 || { _err "git: netexec"; return 1; }
    fi
    pipx ensurepath >/dev/null 2>&1
    export PATH="${HOME}/.cargo/bin:${HOME}/.local/bin:${PATH}"
    if pipx install --system-site-packages --force "${NXC_DIR}"; then
        _ok "pipx: netexec"
    else
        _err "pipx: netexec (see pipx output above)"
        return 1
    fi

    pip3 uninstall -y oscrypto --break-system-packages >/dev/null 2>&1 || true
    pipx runpip netexec install --force-reinstall --no-deps \
        "git+https://github.com/wbond/oscrypto.git" >/dev/null 2>&1 \
        && _ok "pipx: oscrypto (fix libcrypto, from git, injected into netexec venv)" \
        || _err "pipx: oscrypto (fix libcrypto, from git, injected into netexec venv)"

    local pipx_bin="${HOME}/.local/bin/nxc"
    if [[ -f "${pipx_bin}" ]]; then
        ln -sf "${pipx_bin}" "${Z1_BIN}/nxc"
        _ok "bin: nxc â†’ ${Z1_BIN}/nxc"
    else
        _err "netexec: nxc binary not found at ${pipx_bin} after pipx install"
        return 1
    fi

    if "${Z1_BIN}/nxc" --help >/tmp/nxc_check.log 2>&1; then
        _ok "nxc: verification OK"
    else
        _err "nxc: verification failed (check libcrypto/oscrypto)"
        sed 's/^/         /' /tmp/nxc_check.log
    fi
    rm -f /tmp/nxc_check.log
}



function p_infra() {
    install_socat
    install_ncat
    install_penelope
    install_sshuttle
    install_chisel
    install_ligolo

    install_havoc
    install_villain
    install_pwncat
    install_sliver
    install_metasploit

    install_proxify
    install_goproxy
    install_netexec 
}
