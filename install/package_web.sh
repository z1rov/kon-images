#!/usr/bin/env bash
source /kon/install/common.sh
mkdir -p /anvil /opt/tools

# ── Helpers extra ───────────────────────────────────────────────────────────
install_pipx() {
    pipx install -q --system-site-packages "$2" >/dev/null 2>&1 \
        && _ok "pipx: $1" || _err "pipx: $1"
}

# pyvenv python2 — usa el python2.7 real instalado vía pyenv (no 2to3).
# Uso: pyvenv2_setup <nombre_en_KON_SRC> <script_relativo_dentro_del_repo>
pyvenv2_setup() {
    local name="$1" script="$2"
    local dest="${KON_SRC}/${name}"
    if [[ ! -d "${dest}" ]]; then _err "pyvenv2: ${name} (src no existe)"; return 1; fi
    set_python_env
    local py2_bin
    py2_bin="$(pyenv root)/versions/2.7.18/bin/python2"
    if [[ ! -x "${py2_bin}" ]]; then
        _err "pyvenv2: python2.7.18 no encontrado (corre install_pyenv primero)"
        return 1
    fi
    "${py2_bin}" -m pip install -q --no-cache-dir virtualenv >/dev/null 2>&1
    "${py2_bin}" -m virtualenv -p "${py2_bin}" "${dest}/venv" >/dev/null 2>&1
    echo "${dest}/venv"
}

# venv_pip2 <dest_dir> <paquetes...>
venv_pip2() {
    local dest="$1"; shift
    "${dest}/venv/bin/pip" install -q --no-cache-dir "$@" 2>/dev/null
}

# Corre un comando, capturando su output. Si falla, lo imprime completo.
function _run_logged() {
    local desc="$1"; shift
    local log rc
    log=$("$@" 2>&1)
    rc=$?
    if [[ ${rc} -eq 0 ]]; then
        _ok "${desc}"
    else
        _err "${desc} (rc=${rc})"
        echo "----- output -----"
        echo "${log}"
        echo "-------------------"
    fi
    return ${rc}
}

# Asegura que pipx esté disponible, probando varias rutas antes de rendirse.
function _ensure_pipx() {
    if command -v pipx >/dev/null 2>&1; then
        return 0
    fi

    _info "pipx no encontrado, intentando instalar"

    apt-get update -y >/dev/null 2>&1
    if install_apt pipx && command -v pipx >/dev/null 2>&1; then
        return 0
    fi

    _info "apt falló, intentando con pip --user"
    pip3 install -q --no-cache-dir --user pipx >/dev/null 2>&1
    export PATH="$HOME/.local/bin:$PATH"
    if command -v pipx >/dev/null 2>&1; then
        _ok "pip: pipx (--user)"
        return 0
    fi

    _err "pipx: no se pudo instalar por ningún método"
    return 1
}

# ── APT base ─────────────────────────────────────────────────────────────────
function install_web_apt_tools() {
    install_apt dirb
    install_apt prips
    install_apt locales
    install_apt swaks
    echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen && locale-gen >/dev/null 2>&1 || true

    install_apt php-cli

    install_apt default-jre-headless

    install_apt libwww-perl

    install_apt python3-pycurl

    install_apt cmake
    install_apt build-essential

    install_apt libatk1.0-0
    install_apt libgtk-3-0
    install_apt libxcomposite1
    install_apt libxdamage1
    install_apt libxrandr2
    install_apt libgbm1
    install_apt libxkbcommon0
    install_apt libasound2
    install_apt libatspi2.0-0
    install_apt libxss1

    export PATH="${PATH}:/root/.local/bin"
    pipx ensurepath >/dev/null 2>&1 || true
}

# ── Webshells / fingerprinting ───────────────────────────────────────────────
function install_weevely() {
    install_apt weevely
}

function install_whatweb() {
    colorecho "Installing WhatWeb"

    local dest="${KON_SRC}/whatweb"
    rm -rf "${dest}" 2>/dev/null
    git clone -q --depth 1 https://github.com/urbanadventurer/WhatWeb.git "${dest}" \
        && _ok "git: whatweb → ${dest}" || { _err "git: whatweb"; return 1; }

    source /usr/local/rvm/scripts/rvm
    rvm use "${KON_RUBY_VERSION}@whatweb" --create >/dev/null 2>&1

    gem install -q addressable json rake >/dev/null 2>&1 \
        && _ok "gem: addressable json rake [gemset:whatweb]" \
        || _err "gem: addressable json rake [gemset:whatweb]"

    rvm use "${KON_RUBY_VERSION}@default" >/dev/null 2>&1

    chmod +x "${dest}/whatweb"

    cat > "${KON_BIN}/whatweb" << EOF
#!/usr/bin/env bash
source /usr/local/rvm/scripts/rvm 2>/dev/null
rvm use ${KON_RUBY_VERSION}@whatweb >/dev/null 2>&1
exec ruby "${dest}/whatweb" "\$@"
EOF
    chmod +x "${KON_BIN}/whatweb"
    _ok "whatweb: wrapper creado en ${KON_BIN}/whatweb"

    if "${KON_BIN}/whatweb" --version >/dev/null 2>&1; then
        _ok "whatweb: instalado correctamente"
    else
        _err "whatweb: verificación falló"
        "${KON_BIN}/whatweb" --version 2>&1 | head -10
    fi
}

# ── Fuzzers / discovery ──────────────────────────────────────────────────────
function install_kiterunner() {
    install_git kiterunner https://github.com/assetnote/kiterunner.git
    local dest="${KON_SRC}/kiterunner"
    if [[ -d "${dest}" ]]; then
        curl -sL https://wordlists-cdn.assetnote.io/data/kiterunner/routes-large.kite.tar.gz \
            -o "${dest}/routes-large.kite.tar.gz"
        curl -sL https://wordlists-cdn.assetnote.io/data/kiterunner/routes-small.kite.tar.gz \
            -o "${dest}/routes-small.kite.tar.gz"
        (cd "${dest}" && make build >/dev/null 2>&1)
        link_bin kr "${dest}/dist/kr"
    fi
}

function install_dirsearch() {
    install_git dirsearch https://github.com/maurosoria/dirsearch
    local dest="${KON_SRC}/dirsearch"
    if [[ -d "${dest}" ]]; then
        python3 -m venv --system-site-packages "${dest}/venv" >/dev/null 2>&1
        venv_pip "${dest}" requests
        [[ -f "${dest}/requirements.txt" ]] && \
            venv_pip "${dest}" -r "${dest}/requirements.txt"
        cat > "${KON_BIN}/dirsearch.py" << EOF
#!/usr/bin/env bash
exec "${dest}/venv/bin/python3" "${dest}/dirsearch.py" "\$@"
EOF
        chmod +x "${KON_BIN}/dirsearch.py"
        ln -sf "${KON_BIN}/dirsearch.py" "${KON_BIN}/dirsearch"
        _ok "git: dirsearch → ${KON_BIN}/dirsearch"
    fi
}

# ── SSRF / injection ─────────────────────────────────────────────────────────
function install_ssrfmap() {
    install_git ssrfmap https://github.com/swisskyrepo/SSRFmap
    local dest="${KON_SRC}/ssrfmap"
    if [[ -d "${dest}" ]]; then
        python3 -m venv --system-site-packages "${dest}/venv" >/dev/null 2>&1
        venv_pip "${dest}" requests
        [[ -f "${dest}/requirements.txt" ]] && \
            venv_pip "${dest}" -r "${dest}/requirements.txt"
        cat > "${KON_BIN}/ssrfmap.py" << EOF
#!/usr/bin/env bash
exec "${dest}/venv/bin/python3" "${dest}/ssrfmap.py" "\$@"
EOF
        chmod +x "${KON_BIN}/ssrfmap.py"
        ln -sf "${KON_BIN}/ssrfmap.py" "${KON_BIN}/ssrfmap"
        _ok "git: ssrfmap → ${KON_BIN}/ssrfmap"
    fi
}

function install_gopherus() {
    install_git gopherus https://github.com/tarunkant/Gopherus
    local dest="${KON_SRC}/gopherus"
    if [[ -d "${dest}" ]]; then
        pyvenv2_setup gopherus gopherus.py >/dev/null
        venv_pip2 "${dest}" argparse requests
        cat > "${KON_BIN}/gopherus.py" << EOF
#!/usr/bin/env bash
exec "${dest}/venv/bin/python" "${dest}/gopherus.py" "\$@"
EOF
        chmod +x "${KON_BIN}/gopherus.py"
        ln -sf "${KON_BIN}/gopherus.py" "${KON_BIN}/gopherus"
        _ok "git: gopherus → ${KON_BIN}/gopherus (python2.7 real)"
    fi
}

function install_nosqlmap() {
    install_git nosqlmap https://github.com/codingo/NoSQLMap.git
    local dest="${KON_SRC}/nosqlmap"
    if [[ -d "${dest}" ]]; then
        pyvenv2_setup nosqlmap nosqlmap.py >/dev/null
        if [[ -f "${dest}/setup.py" ]]; then
            sed -i 's/requests==2\.32\.4/requests==2.27.1/' "${dest}/setup.py"
        fi
        (cd "${dest}" && "${dest}/venv/bin/python" setup.py install >/dev/null 2>&1) || true
        rm -rf "${dest}"/venv/lib/python2.7/site-packages/certifi-2023.5.7-py2.7.egg 2>/dev/null
        venv_pip2 "${dest}" "certifi==2018.10.15"
        cat > "${KON_BIN}/nosqlmap.py" << EOF
#!/usr/bin/env bash
exec "${dest}/venv/bin/python" "${dest}/nosqlmap.py" "\$@"
EOF
        chmod +x "${KON_BIN}/nosqlmap.py"
        ln -sf "${KON_BIN}/nosqlmap.py" "${KON_BIN}/nosqlmap"
        _ok "git: nosqlmap → ${KON_BIN}/nosqlmap (python2.7 real)"
    fi
}

# ── XSS ──────────────────────────────────────────────────────────────────────
function install_xsstrike() {
    install_git xsstrike https://github.com/s0md3v/XSStrike.git
    local dest="${KON_SRC}/xsstrike"
    if [[ -d "${dest}" ]]; then
        python3 -m venv --system-site-packages "${dest}/venv" >/dev/null 2>&1
        venv_pip "${dest}" fuzzywuzzy python-Levenshtein
        [[ -f "${dest}/requirements.txt" ]] && \
            venv_pip "${dest}" -r "${dest}/requirements.txt"
        cat > "${KON_BIN}/xsstrike.py" << EOF
#!/usr/bin/env bash
exec "${dest}/venv/bin/python3" "${dest}/xsstrike.py" "\$@"
EOF
        chmod +x "${KON_BIN}/xsstrike.py"
        ln -sf "${KON_BIN}/xsstrike.py" "${KON_BIN}/xsstrike"
        _ok "git: xsstrike → ${KON_BIN}/xsstrike"
    fi
}

function install_xspear() {
    install_gem xspear XSpear
}

function install_xsser() {
    install_git xsser https://github.com/epsylon/xsser.git
    local dest="${KON_SRC}/xsser"
    if [[ -d "${dest}" ]]; then
        python3 -m venv --system-site-packages "${dest}/venv" >/dev/null 2>&1
        venv_pip "${dest}" bs4 selenium
        "${dest}/venv/bin/pip" install -q --no-cache-dir pycurl 2>/dev/null || true
        local xsser_script="${dest}/xsser"
        [[ ! -f "${xsser_script}" ]] && xsser_script="${dest}/xsser.py"
        cat > "${KON_BIN}/xsser" << EOF
#!/usr/bin/env bash
exec "${dest}/venv/bin/python3" "${xsser_script}" "\$@"
EOF
        chmod +x "${KON_BIN}/xsser"
        _ok "git: xsser → ${KON_BIN}/xsser"
    fi
}

# ── CSRF ─────────────────────────────────────────────────────────────────────
function install_xsrfprobe() {
    pip3 install -q --no-cache-dir --break-system-packages \
        "git+https://github.com/0xInfection/XSRFProbe" >/dev/null 2>&1 \
        && _ok "pip: xsrfprobe" || _err "pip: xsrfprobe"
}

function install_bolt() {
    install_git bolt https://github.com/s0md3v/Bolt.git
    local dest="${KON_SRC}/bolt"
    if [[ -d "${dest}" ]]; then
        python3 -m venv --system-site-packages "${dest}/venv" >/dev/null 2>&1
        venv_pip "${dest}" fuzzywuzzy python-Levenshtein
        [[ -f "${dest}/requirements.txt" ]] && \
            venv_pip "${dest}" -r "${dest}/requirements.txt"
        cat > "${KON_BIN}/bolt" << EOF
#!/usr/bin/env bash
exec "${dest}/venv/bin/python3" "${dest}/bolt.py" "\$@"
EOF
        chmod +x "${KON_BIN}/bolt"
        _ok "git: bolt → ${KON_BIN}/bolt"
    fi
}

# ── LFI / upload / login ─────────────────────────────────────────────────────
function install_kadimus() {
    install_apt libcurl4-openssl-dev
    install_apt libpcre3-dev
    install_apt libssh-dev
    install_git kadimus https://github.com/P0cL4bs/Kadimus
    local dest="${KON_SRC}/kadimus"
    if [[ -d "${dest}" ]]; then
        (cd "${dest}" && make -j >/dev/null 2>&1)
        link_bin kadimus "${dest}/kadimus"
    fi
}

function install_fuxploider() {
    install_git fuxploider https://github.com/almandin/fuxploider.git
    local dest="${KON_SRC}/fuxploider"
    if [[ -d "${dest}" ]]; then
        python3 -m venv --system-site-packages "${dest}/venv" >/dev/null 2>&1
        venv_pip "${dest}" coloredlogs
        [[ -f "${dest}/requirements.txt" ]] && \
            venv_pip "${dest}" -r "${dest}/requirements.txt"
        cat > "${KON_BIN}/fuxploider" << EOF
#!/usr/bin/env bash
cd "${dest}"
exec ./venv/bin/python3 fuxploider.py "\$@"
EOF
        chmod +x "${KON_BIN}/fuxploider"
        _ok "git: fuxploider → ${KON_BIN}/fuxploider"
    fi
}

function install_patator() {
    install_apt libmariadb-dev
    install_apt libcurl4-openssl-dev
    install_apt libssl-dev
    install_apt ldap-utils
    install_apt libpq-dev
    install_apt ike-scan
    install_git patator https://github.com/lanjelot/patator.git
    local dest="${KON_SRC}/patator"
    if [[ -d "${dest}" ]]; then
        python3 -m venv --system-site-packages "${dest}/venv" >/dev/null 2>&1
        echo 'setuptools<82' > "${dest}/build-constraints.txt"
        [[ -f "${dest}/requirements.txt" ]] && \
            "${dest}/venv/bin/pip" install -q --no-cache-dir \
                --build-constraint "${dest}/build-constraints.txt" \
                -r "${dest}/requirements.txt" 2>/dev/null
        local patator_script="${dest}/patator.py"
        [[ ! -f "${patator_script}" ]] && \
            patator_script="${dest}/src/patator/patator.py"
        cat > "${KON_BIN}/patator.py" << EOF
#!/usr/bin/env bash
exec "${dest}/venv/bin/python3" "${patator_script}" "\$@"
EOF
        chmod +x "${KON_BIN}/patator.py"
        ln -sf "${KON_BIN}/patator.py" "${KON_BIN}/patator"
        _ok "git: patator → ${KON_BIN}/patator"
    fi
}

# ── CMS scanners ─────────────────────────────────────────────────────────────
function install_joomscan() {
    install_git joomscan https://github.com/rezasp/joomscan
    local dest="${KON_SRC}/joomscan"
    if [[ -d "${dest}" ]]; then
        cat > "${KON_BIN}/joomscan" << EOF
#!/usr/bin/env bash
exec perl "${dest}/joomscan.pl" "\$@"
EOF
        chmod +x "${KON_BIN}/joomscan"
        _ok "git: joomscan → ${KON_BIN}/joomscan"
    fi
}

function install_wpscan() {
    colorecho "Installing wpscan"

    source /usr/local/rvm/scripts/rvm 2>/dev/null || true

    rvm use "${KON_RUBY_VERSION}@wpscan" --create >/dev/null 2>&1

    install_apt ruby-dev
    install_apt libxml2-dev
    install_apt libxslt1-dev
    install_apt build-essential
    install_apt libcurl4-openssl-dev
    install_apt libssl-dev
    install_apt zlib1g-dev

    gem install -q bundler >/dev/null 2>&1

    gem install -q wpscan >/dev/null 2>&1 \
        && _ok "gem: wpscan [gemset:wpscan]" \
        || {
            _err "gem: wpscan [gemset:wpscan]"
            colorecho "Intentando instalar wpscan via bundle..."
            git clone -q --depth 1 https://github.com/wpscanteam/wpscan.git /tmp/wpscan-src >/dev/null 2>&1
            (
                cd /tmp/wpscan-src
                bundle install >/dev/null 2>&1
                gem build wpscan.gemspec >/dev/null 2>&1
                gem install wpscan-*.gem >/dev/null 2>&1
            )
            rm -rf /tmp/wpscan-src
        }

    rvm use "${KON_RUBY_VERSION}@default" >/dev/null 2>&1

    cat > "${KON_BIN}/wpscan" << EOF
#!/usr/bin/env bash
source /usr/local/rvm/scripts/rvm 2>/dev/null
rvm use ${KON_RUBY_VERSION}@wpscan >/dev/null 2>&1
exec wpscan "\$@"
EOF
    chmod +x "${KON_BIN}/wpscan"

    if "${KON_BIN}/wpscan" --help >/dev/null 2>&1; then
        _ok "wpscan: instalado correctamente → ${KON_BIN}/wpscan"
    else
        _err "wpscan: verificación falló"
    fi
}

function install_droopescan() {
    colorecho "Installing droopescan"

    if command -v pipx >/dev/null 2>&1; then
        pipx install --system-site-packages git+https://github.com/droope/droopescan.git >/dev/null 2>&1 \
            && _ok "pipx: droopescan" || _err "pipx: droopescan"
    else
        _err "pipx: no disponible"
    fi

    pip3 install -q --no-cache-dir --break-system-packages git+https://github.com/droope/droopescan.git >/dev/null 2>&1 \
        && _ok "pip: droopescan" || {
            _err "pip: droopescan"
            return 1
        }

    if command -v droopescan >/dev/null 2>&1; then
        _ok "droopescan: instalado correctamente"
    else
        local droopescan_bin
        droopescan_bin=$(find /usr/local/bin /root/.local/bin /usr/bin -name "droopescan" 2>/dev/null | head -1)
        if [[ -n "${droopescan_bin}" ]]; then
            ln -sf "${droopescan_bin}" "${KON_BIN}/droopescan"
            _ok "droopescan: symlink creado → ${KON_BIN}/droopescan"
        else
            _err "droopescan: no se encontró el binario"
            return 1
        fi
    fi

    if droopescan --help >/dev/null 2>&1 || "${KON_BIN}/droopescan" --help >/dev/null 2>&1; then
        _ok "droopescan: verificación OK"
    else
        _err "droopescan: verificación falló"
        return 1
    fi
}

function install_drupwn() {
    colorecho "Installing drupwn con parche para Python 3.13"

    local dest="${KON_SRC}/drupwn"

    if [[ ! -d "${dest}" ]]; then
        git clone -q --depth 1 https://github.com/immunIT/drupwn "${dest}" >/dev/null 2>&1 \
            && _ok "git: drupwn → ${dest}" || { _err "git: drupwn"; return 1; }
    else
        _info "skip: drupwn (already exists)"
    fi

    if [[ -d "${dest}/venv" ]]; then
        rm -rf "${dest}/venv"
    fi

    python3 -m venv "${dest}/venv" >/dev/null 2>&1 \
        && _ok "venv: drupwn" || { _err "venv: drupwn"; return 1; }

    "${dest}/venv/bin/pip" install -q --no-cache-dir --upgrade pip >/dev/null 2>&1
    "${dest}/venv/bin/pip" install -q --no-cache-dir setuptools wheel >/dev/null 2>&1 \
        && _ok "pip: setuptools/wheel" || _err "pip: setuptools/wheel"

    local site_packages
    site_packages=$("${dest}/venv/bin/python3" -c "import site; print(site.getsitepackages()[0])")
    if [[ ! -d "${site_packages}/pkg_resources" ]]; then
        "${dest}/venv/bin/pip" install -q --no-cache-dir --force-reinstall setuptools >/dev/null 2>&1
        _info "pkg_resources forzado"
    fi

    while IFS= read -r -d '' init_file; do
        cp "${init_file}" "${init_file}.bak"
        cat > "${init_file}" << 'EOF'
# Parcheado para Python 3.13: namespace package implicito (PEP 420),
# no requiere pkg_resources.declare_namespace()
EOF
        _ok "patch: ${init_file#${dest}/}"
    done < <(grep -rlZ "declare_namespace" "${dest}" --include="__init__.py" 2>/dev/null)

    local script="${dest}/drupwn"
    if [[ -f "${script}" ]]; then
        sed -i 's|#!/usr/bin/env python|#!/usr/bin/env python3|' "${script}"
        _ok "patch: drupwn shebang"
    fi

    cat > "${dest}/requirements-fixed.txt" << 'EOF'
requests>=2.25.0
beautifulsoup4>=4.9.0
lxml>=4.6.0
colorama>=0.4.0
EOF

    "${dest}/venv/bin/pip" install -q --no-cache-dir -r "${dest}/requirements-fixed.txt" 2>/dev/null \
        && _ok "pip: requirements fixed" || _err "pip: requirements fixed"

    (cd "${dest}" && "${dest}/venv/bin/pip" install -q --no-cache-dir -e . 2>/dev/null) \
        && _ok "pip: drupwn (editable)" || _err "pip: drupwn (editable)"

    cat > "${KON_BIN}/drupwn" << EOF
#!/usr/bin/env bash
export PYTHONPATH="${site_packages}:\$PYTHONPATH"
exec "${dest}/venv/bin/python3" "${dest}/drupwn" "\$@"
EOF
    chmod +x "${KON_BIN}/drupwn"

    if "${KON_BIN}/drupwn" --help >/dev/null 2>&1; then
        _ok "drupwn: instalado correctamente"
        _info "Uso: drupwn --target http://target.com --mode enum"
        _info "      drupwn --target http://target.com --mode exploit"
    else
        _err "drupwn: verificación falló"
        _info "Mostrando error:"
        "${KON_BIN}/drupwn" --help 2>&1 | head -10
    fi
}

function install_cmsmap() {
    # CODE-CHECK-WHITELIST=add-aliases
    colorecho "Installing CMSmap"

    local dest="${KON_SRC}/cmsmap"

    if [[ -d "${dest}" ]]; then
        _info "cmsmap repo ya existe, eliminando antes de re-clonar"
        rm -rf "${dest}"
    fi
    _run_logged "git: cmsmap" git clone -q --depth 1 https://github.com/Dionach/CMSmap.git "${dest}" \
        || return 1

    local _p _stale
    IFS=':' read -ra _path_dirs <<< "${PATH}"
    for _p in "${_path_dirs[@]}"; do
        _stale="${_p}/cmsmap"
        if [[ -f "${_stale}" || -L "${_stale}" ]]; then
            _info "eliminando binario suelto: ${_stale}"
            rm -f "${_stale}"
        fi
    done
    pipx uninstall cmsmap >/dev/null 2>&1
    rm -rf /root/.local/share/pipx/venvs/cmsmap

    python3 -m venv "${dest}/venv" \
        && _ok "venv: cmsmap" || { _err "venv: cmsmap"; return 1; }

    _run_logged "pip: upgrade pip/setuptools/wheel" \
        "${dest}/venv/bin/pip" install --no-cache-dir --upgrade pip setuptools wheel \
        || return 1

    if [[ -f "${dest}/requirements.txt" ]]; then
        _run_logged "pip: requirements.txt" \
            "${dest}/venv/bin/pip" install --no-cache-dir -r "${dest}/requirements.txt"
    fi

    _run_logged "pip: cmsmap" \
        "${dest}/venv/bin/pip" install --no-cache-dir "${dest}" \
        || return 1

    local venv_py="${dest}/venv/bin/python3"
    if "${venv_py}" -c "from cmsmap.main import main" 2>/dev/null; then
        cat > "${KON_BIN}/cmsmap" << EOF
#!/usr/bin/env bash
exec "${venv_py}" -c "import sys; from cmsmap.main import main; sys.exit(main())" "\$@"
EOF
        chmod +x "${KON_BIN}/cmsmap"
        _ok "cmsmap: wrapper creado en ${KON_BIN}/cmsmap"
    else
        _err "cmsmap: el módulo 'cmsmap.main' no es importable en el venv"
        "${venv_py}" -c "from cmsmap.main import main" 2>&1 | sed 's/^/    /'
        return 1
    fi

    local conf
    conf=$(compgen -G "${dest}/venv/lib/python3*/site-packages/cmsmap/cmsmap.conf" | head -n1)
    if [[ -n "${conf}" && -f "${conf}" ]]; then
        sed -i 's/wordlist =  wordlist\/rockyou.txt/wordlist =  \/usr\/share\/wordlists\/rockyou.txt/' "${conf}"
        sed -i 's/edbpath = \/usr\/share\/exploitdb/edbpath = \/opt\/tools\/exploitdb/' "${conf}"
        sed -i 's/edbtype = apt/edbtype = git/' "${conf}"
        _ok "patch: cmsmap.conf (${conf})"
    else
        _err "cmsmap.conf no encontrado, no se pudo parchear"
        _info "buscando cmsmap.conf en ${dest}:"
        find "${dest}" -iname "cmsmap.conf" 2>&1
    fi

    if "${KON_BIN}/cmsmap" --help >/dev/null 2>&1; then
        _ok "cmsmap: instalado correctamente"
    else
        _err "cmsmap: verificación falló"
        "${KON_BIN}/cmsmap" --help 2>&1 | head -10
    fi
}

function install_moodlescan() {
    install_git moodlescan https://github.com/inc0d3/moodlescan.git
    local dest="${KON_SRC}/moodlescan"
    if [[ -d "${dest}" ]]; then
        python3 -m venv --system-site-packages "${dest}/venv" >/dev/null 2>&1
        [[ -f "${dest}/requirements.txt" ]] && \
            venv_pip "${dest}" -r "${dest}/requirements.txt"
        (cd "${dest}" && ./venv/bin/python3 moodlescan.py -a >/dev/null 2>&1) || true
        cat > "${KON_BIN}/moodlescan.py" << EOF
#!/usr/bin/env bash
exec "${dest}/venv/bin/python3" "${dest}/moodlescan.py" "\$@"
EOF
        chmod +x "${KON_BIN}/moodlescan.py"
        ln -sf "${KON_BIN}/moodlescan.py" "${KON_BIN}/moodlescan"
        _ok "git: moodlescan → ${KON_BIN}/moodlescan"
    fi
}

# ── SSL/TLS ──────────────────────────────────────────────────────────────────
function install_testssl() {
    install_apt bsdmainutils
    install_git testssl https://github.com/drwetter/testssl.sh.git
    link_bin testssl.sh "${KON_SRC}/testssl/testssl.sh"
    ln -sf "${KON_BIN}/testssl.sh" "${KON_BIN}/testssl"
    _ok "bin: testssl alias → ${KON_BIN}/testssl"
}

function install_sslscan() {
    local tmp_dir
    tmp_dir=$(mktemp -d)
    git clone -q --depth 1 https://github.com/rbsec/sslscan.git "${tmp_dir}" >/dev/null 2>&1 \
        && _ok "git: sslscan (tmp)" || { _err "git: sslscan"; return; }
    (cd "${tmp_dir}" && make static >/dev/null 2>&1)
    if [[ -f "${tmp_dir}/sslscan" ]]; then
        mv "${tmp_dir}/sslscan" "${KON_BIN}/sslscan"
        chmod +x "${KON_BIN}/sslscan"
        _ok "bin: sslscan → ${KON_BIN}/sslscan"
    else
        _err "sslscan: make static falló"
    fi
    rm -rf "${tmp_dir}"
}

# ── Recon / discovery ────────────────────────────────────────────────────────
function install_cloudfail() {
    colorecho "Installing CloudFail"

    local dest="${KON_SRC}/CloudFail"

    if [[ -d "${dest}" ]]; then
        _info "CloudFail repo ya existe, eliminando antes de re-clonar"
        rm -rf "${dest}"
    fi
    _run_logged "git: CloudFail" git clone -q --depth 1 https://github.com/m0rtem/CloudFail "${dest}" \
        || return 1

    python3 -m venv "${dest}/venv" \
        && _ok "venv: cloudfail" || { _err "venv: cloudfail"; return 1; }

    _run_logged "pip: upgrade pip" \
        "${dest}/venv/bin/pip" install --no-cache-dir --upgrade pip

    _run_logged "pip: requirements.txt" \
        "${dest}/venv/bin/pip" install --no-cache-dir -r "${dest}/requirements.txt" \
        || return 1

    _run_logged "pip: upgrade urllib3/certifi/chardet" \
        "${dest}/venv/bin/pip" install --no-cache-dir --upgrade urllib3 certifi chardet idna

    cat > "${KON_BIN}/cloudfail" << EOF
#!/usr/bin/env bash
exec "${dest}/venv/bin/python3" "${dest}/cloudfail.py" "\$@"
EOF
    chmod +x "${KON_BIN}/cloudfail"
    _ok "cloudfail: wrapper creado en ${KON_BIN}/cloudfail"

    if "${KON_BIN}/cloudfail" --help >/dev/null 2>&1; then
        _ok "cloudfail: instalado correctamente"
    else
        _err "cloudfail: verificación falló"
        "${KON_BIN}/cloudfail" --help 2>&1 | head -10
    fi
}

function install_oneforall() {
    colorecho "Installing OneForAll"

    local dest="${KON_SRC}/OneForAll"

    if [[ -d "${dest}" ]]; then
        _info "OneForAll repo ya existe, eliminando antes de re-clonar"
        rm -rf "${dest}"
    fi

    _run_logged "git: OneForAll" git clone -q --depth 1 https://github.com/shmilylty/OneForAll.git "${dest}" \
        || return 1

    python3 -m venv "${dest}/venv" \
        && _ok "venv: oneforall" || { _err "venv: oneforall"; return 1; }

    _run_logged "pip: upgrade pip/setuptools/wheel" \
        "${dest}/venv/bin/pip" install --no-cache-dir --upgrade pip setuptools wheel

    _run_logged "pip: requirements.txt" \
        "${dest}/venv/bin/pip" install --no-cache-dir -r "${dest}/requirements.txt" \
        || return 1

    local sitepkg
    sitepkg=$("${dest}/venv/bin/python3" -c "import sysconfig; print(sysconfig.get_path('purelib'))")
    cat > "${sitepkg}/pipes.py" << 'EOF'
"""Shim de compatibilidad: el modulo `pipes` fue removido en Python 3.13.
python-fire (dependencia de OneForAll) todavia hace `import pipes` y usa
`pipes.quote`, equivalente a `shlex.quote`."""
from shlex import quote
EOF
    _ok "shim: pipes -> shlex (compat Python 3.13)"

    cat > "${KON_BIN}/oneforall" << EOF
#!/usr/bin/env bash
cd "${dest}" && exec "${dest}/venv/bin/python3" "${dest}/oneforall.py" "\$@"
EOF
    chmod +x "${KON_BIN}/oneforall"
    _ok "oneforall: wrapper creado en ${KON_BIN}/oneforall"

    if "${KON_BIN}/oneforall" check >/dev/null 2>&1; then
        _ok "oneforall: instalado correctamente"
    else
        _err "oneforall: verificación falló"
        "${KON_BIN}/oneforall" check 2>&1 | head -10
    fi
}

function install_corscanner() {
    install_git corscanner https://github.com/chenjj/CORScanner.git
    local dest="${KON_SRC}/corscanner"
    if [[ -d "${dest}" ]]; then
        python3 -m venv --system-site-packages "${dest}/venv" >/dev/null 2>&1
        venv_pip "${dest}" gevent
        [[ -f "${dest}/requirements.txt" ]] && \
            venv_pip "${dest}" -r "${dest}/requirements.txt"
        cat > "${KON_BIN}/cors_scan" << EOF
#!/usr/bin/env bash
exec "${dest}/venv/bin/python3" "${dest}/cors_scan.py" "\$@"
EOF
        chmod +x "${KON_BIN}/cors_scan"
        _ok "git: corscanner → ${KON_BIN}/cors_scan"
    fi
}

function install_hakrawler() {
    install_go hakrawler github.com/hakluke/hakrawler@latest
}

function install_linkfinder() {
    install_git linkfinder https://github.com/GerbenJavado/LinkFinder.git
    local dest="${KON_SRC}/linkfinder"
    if [[ -d "${dest}" ]]; then
        python3 -m venv --system-site-packages "${dest}/venv" >/dev/null 2>&1
        venv_pip "${dest}" jsbeautifier
        [[ -f "${dest}/requirements.txt" ]] && \
            venv_pip "${dest}" -r "${dest}/requirements.txt"
        cat > "${KON_BIN}/linkfinder.py" << EOF
#!/usr/bin/env bash
exec "${dest}/venv/bin/python3" "${dest}/linkfinder.py" "\$@"
EOF
        chmod +x "${KON_BIN}/linkfinder.py"
        ln -sf "${KON_BIN}/linkfinder.py" "${KON_BIN}/linkfinder"
        _ok "git: linkfinder → ${KON_BIN}/linkfinder"
    fi
}

function install_gau() {
    install_go gau github.com/lc/gau/v2/cmd/gau@latest
}

function install_hakrevdns() {
    install_go hakrevdns github.com/hakluke/hakrevdns@latest
}

function install_anew() {
    install_go anew github.com/tomnomnom/anew@latest
}

function install_robotstester() {
    pip3 install -q --no-cache-dir --break-system-packages \
        "git+https://github.com/p0dalirius/robotstester" >/dev/null 2>&1 \
        && _ok "pip: robotstester" || _err "pip: robotstester"
}

function install_jsluice() {
    install_go jsluice github.com/BishopFox/jsluice/cmd/jsluice@latest
}

function install_subzy() {
    install_go subzy github.com/PentestPad/subzy@latest
}

function install_urldedupe() {
    local tmp_dir
    tmp_dir=$(mktemp -d)
    git clone -q --depth 1 https://github.com/ameenmaali/urldedupe.git "${tmp_dir}" >/dev/null 2>&1 \
        && _ok "git: urldedupe (tmp)" || { _err "git: urldedupe"; return; }
    (cd "${tmp_dir}" && cmake CMakeLists.txt >/dev/null 2>&1 && make >/dev/null 2>&1)
    if [[ -f "${tmp_dir}/urldedupe" ]]; then
        mv "${tmp_dir}/urldedupe" "${KON_BIN}/urldedupe"
        chmod +x "${KON_BIN}/urldedupe"
        _ok "bin: urldedupe → ${KON_BIN}/urldedupe"
    else
        _err "urldedupe: make falló"
    fi
    rm -rf "${tmp_dir}"
}

# ── Misc / utilidades HTTP ───────────────────────────────────────────────────
function install_timing_attack() {
    install_gem timing_attack timing_attack
}

function install_updog() {
    pip3 install -q --no-cache-dir --break-system-packages updog >/dev/null 2>&1 \
        && _ok "pip: updog" || _err "pip: updog"
}

function install_wuzz() {
    install_go wuzz github.com/asciimoo/wuzz@latest
}

function install_curlie() {
    local arch="amd64"
    [[ $(uname -m) == "aarch64" ]] && arch="arm64"
    local url
    url=$(curl -s "https://api.github.com/repos/rs/curlie/releases/latest" \
        | grep "browser_download_url.*curlie.*linux.*${arch}.*tar.gz" \
        | grep -o 'https://[^"]*' | head -1)
    curl -sL -o /tmp/curlie.tar.gz "${url}"
    tar -xzf /tmp/curlie.tar.gz -C /tmp curlie >/dev/null 2>&1
    rm -f /tmp/curlie.tar.gz
    if [[ -f /tmp/curlie ]]; then
        mv /tmp/curlie "${KON_BIN}/curlie"
        chmod +x "${KON_BIN}/curlie"
        _ok "bin: curlie → ${KON_BIN}/curlie"
    else
        _err "bin: curlie"
    fi
}

# ── JWT ──────────────────────────────────────────────────────────────────────
function install_jwt_tool() {
    install_git jwt_tool https://github.com/ticarpi/jwt_tool
    local dest="${KON_SRC}/jwt_tool"
    if [[ -d "${dest}" ]]; then
        python3 -m venv --system-site-packages "${dest}/venv" >/dev/null 2>&1
        venv_pip "${dest}" ratelimit
        [[ -f "${dest}/requirements.txt" ]] && \
            venv_pip "${dest}" -r "${dest}/requirements.txt"
        "${dest}/venv/bin/python3" "${dest}/jwt_tool.py" >/dev/null 2>&1 || :
        if [[ -f /root/.jwt_tool/jwtconf.ini ]]; then
            sed -i 's/^proxy = 127.0.0.1:8080/#proxy = 127.0.0.1:8080/' /root/.jwt_tool/jwtconf.ini
            sed -i "s|^wordlist = jwt-common.txt|wordlist = ${dest}/jwt-common.txt|" /root/.jwt_tool/jwtconf.ini
            sed -i "s|^commonHeaders = common-headers.txt|commonHeaders = ${dest}/common-headers.txt|" /root/.jwt_tool/jwtconf.ini
            sed -i "s|^commonPayloads = common-payloads.txt|commonPayloads = ${dest}/common-payloads.txt|" /root/.jwt_tool/jwtconf.ini
        fi
        cat > "${KON_BIN}/jwt_tool.py" << EOF
#!/usr/bin/env bash
exec "${dest}/venv/bin/python3" "${dest}/jwt_tool.py" "\$@"
EOF
        chmod +x "${KON_BIN}/jwt_tool.py"
        ln -sf "${KON_BIN}/jwt_tool.py" "${KON_BIN}/jwt_tool"
        _ok "git: jwt_tool → ${KON_BIN}/jwt_tool"
    fi
}

function install_token_exploiter() {
    # CODE-CHECK-WHITELIST=add-aliases,add-history
    colorecho "Installing Token Exploiter"

    _ensure_pipx || return 1

    local log rc
    log=$(pipx install --system-site-packages git+https://github.com/psyray/token-exploiter 2>&1)
    rc=$?
    if [[ ${rc} -eq 0 ]]; then
        _ok "pipx: token-exploiter"
    else
        _err "pipx: token-exploiter (rc=${rc})"
        echo "----- output -----"
        echo "${log}"
        echo "-------------------"
        return 1
    fi

    if command -v token-exploiter >/dev/null 2>&1; then
        _ok "token-exploiter: instalado correctamente"
    else
        _err "token-exploiter: verificación falló (binario no encontrado en PATH)"
        pipx list 2>&1 | grep -A3 -i "token-exploiter" || true
    fi
}

# ── Deserialización / RCE ────────────────────────────────────────────────────
function install_ysoserial() {
    local dest="${KON_SRC}/ysoserial"
    mkdir -p "${dest}"
    curl -sL -o "${dest}/ysoserial.jar" \
        "https://github.com/frohoff/ysoserial/releases/latest/download/ysoserial-all.jar" \
        && _ok "src: ysoserial.jar" || { _err "src: ysoserial.jar"; return; }
    cat > "${KON_BIN}/ysoserial" << EOF
#!/usr/bin/env bash
exec java -jar "${dest}/ysoserial.jar" "\$@"
EOF
    chmod +x "${KON_BIN}/ysoserial"
    _ok "bin: ysoserial → ${KON_BIN}/ysoserial"
}

function install_phpggc() {
    install_git phpggc https://github.com/ambionics/phpggc.git
    link_bin phpggc "${KON_SRC}/phpggc/phpggc"
}

function install_symfony-exploits() {
    install_git symfony-exploits https://github.com/ambionics/symfony-exploits
    local dest="${KON_SRC}/symfony-exploits"
    if [[ -d "${dest}" ]]; then
        python3 -m venv --system-site-packages "${dest}/venv" >/dev/null 2>&1
        venv_pip "${dest}" requests
        cat > "${KON_BIN}/secret_fragment_exploit.py" << EOF
#!/usr/bin/env bash
exec "${dest}/venv/bin/python3" "${dest}/secret_fragment_exploit.py" "\$@"
EOF
        chmod +x "${KON_BIN}/secret_fragment_exploit.py"
        _ok "git: symfony-exploits → ${KON_BIN}/secret_fragment_exploit.py"
    fi
}

function install_php_filter_chain_generator() {
    install_git php_filter_chain_generator \
        https://github.com/synacktiv/php_filter_chain_generator.git
    link_bin php_filter_chain_generator.py \
        "${KON_SRC}/php_filter_chain_generator/php_filter_chain_generator.py"
}

function install_kraken() {
    install_git kraken https://github.com/kraken-ng/Kraken.git
    local dest="${KON_SRC}/kraken"
    if [[ -d "${dest}" ]]; then
        python3 -m venv --system-site-packages "${dest}/venv" >/dev/null 2>&1
        venv_pip "${dest}" jsonschema validators
        [[ -f "${dest}/requirements.txt" ]] && \
            venv_pip "${dest}" -r "${dest}/requirements.txt"
        cat > "${KON_BIN}/kraken" << EOF
#!/usr/bin/env bash
exec "${dest}/venv/bin/python3" "${dest}/kraken.py" "\$@"
EOF
        chmod +x "${KON_BIN}/kraken"
        _ok "git: kraken → ${KON_BIN}/kraken"
    fi
}

# ── HTTP methods / smuggling / bypass ───────────────────────────────────────
function install_httpmethods() {
    install_git httpmethods https://github.com/ShutdownRepo/httpmethods
    local dest="${KON_SRC}/httpmethods"
    if [[ -d "${dest}" ]]; then
        python3 -m venv --system-site-packages "${dest}/venv" >/dev/null 2>&1
        venv_pip "${dest}" requests
        [[ -f "${dest}/requirements.txt" ]] && \
            venv_pip "${dest}" -r "${dest}/requirements.txt"
        cat > "${KON_BIN}/httpmethods" << EOF
#!/usr/bin/env bash
exec "${dest}/venv/bin/python3" "${dest}/httpmethods.py" "\$@"
EOF
        chmod +x "${KON_BIN}/httpmethods"
        _ok "git: httpmethods → ${KON_BIN}/httpmethods"
    fi
}

function install_h2csmuggler() {
    install_git h2csmuggler https://github.com/BishopFox/h2csmuggler
    local dest="${KON_SRC}/h2csmuggler"
    if [[ -d "${dest}" ]]; then
        python3 -m venv --system-site-packages "${dest}/venv" >/dev/null 2>&1
        venv_pip "${dest}" h2
        cat > "${KON_BIN}/h2csmuggler.py" << EOF
#!/usr/bin/env bash
exec "${dest}/venv/bin/python3" "${dest}/h2csmuggler.py" "\$@"
EOF
        chmod +x "${KON_BIN}/h2csmuggler.py"
        ln -sf "${KON_BIN}/h2csmuggler.py" "${KON_BIN}/h2csmuggler"
        _ok "git: h2csmuggler → ${KON_BIN}/h2csmuggler"
    fi
}

function install_smuggler() {
    install_git smuggler https://github.com/defparam/smuggler.git
    local dest="${KON_SRC}/smuggler"
    if [[ -d "${dest}" ]]; then
        python3 -m venv --system-site-packages "${dest}/venv" >/dev/null 2>&1
        cat > "${KON_BIN}/smuggler.py" << EOF
#!/usr/bin/env bash
exec "${dest}/venv/bin/python3" "${dest}/smuggler.py" "\$@"
EOF
        chmod +x "${KON_BIN}/smuggler.py"
        ln -sf "${KON_BIN}/smuggler.py" "${KON_BIN}/smuggler"
        _ok "git: smuggler → ${KON_BIN}/smuggler"
    fi
}

function install_byp4xx() {
    install_go byp4xx github.com/lobuhi/byp4xx@latest
}

# ── App servers ──────────────────────────────────────────────────────────────
function install_tomcatwardeployer() {
    install_git tomcatwardeployer https://github.com/mgeeky/tomcatWarDeployer.git
    local dest="${KON_SRC}/tomcatwardeployer"
    if [[ -d "${dest}" ]]; then
        python3 -m venv --system-site-packages "${dest}/venv" >/dev/null 2>&1
        venv_pip "${dest}" mechanize
        [[ -f "${dest}/requirements.txt" ]] && \
            venv_pip "${dest}" -r "${dest}/requirements.txt"
        cat > "${KON_BIN}/tomcatWarDeployer" << EOF
#!/usr/bin/env bash
exec "${dest}/venv/bin/python3" "${dest}/tomcatWarDeployer.py" "\$@"
EOF
        chmod +x "${KON_BIN}/tomcatWarDeployer"
        _ok "git: tomcatwardeployer → ${KON_BIN}/tomcatWarDeployer"
    fi
}

# ── Suites de testing de APIs ────────────────────────────────────────────────
function install_soapui() {
    local dest="${KON_SRC}/soapui"
    mkdir -p "${dest}"
    curl -sL "https://dl.eviware.com/soapuios/5.7.0/SoapUI-5.7.0-linux-bin.tar.gz" \
        -o /tmp/SoapUI.tar.gz
    tar -xf /tmp/SoapUI.tar.gz -C "${dest}" --strip-components=1 >/dev/null 2>&1
    rm -f /tmp/SoapUI.tar.gz
    link_bin soapui "${dest}/bin/soapui.sh"
}

# ── Git leaks ────────────────────────────────────────────────────────────────
function install_git-dumper() {
    # CODE-CHECK-WHITELIST=add-aliases
    colorecho "Installing git-dumper"

    _ensure_pipx || return 1

    local log rc
    log=$(pipx install --system-site-packages git-dumper 2>&1)
    rc=$?
    if [[ ${rc} -eq 0 ]]; then
        _ok "pipx: git-dumper"
    else
        _err "pipx: git-dumper (rc=${rc})"
        echo "----- output -----"
        echo "${log}"
        echo "-------------------"
        return 1
    fi

    if command -v git-dumper >/dev/null 2>&1; then
        _ok "git-dumper: instalado correctamente"
    else
        _err "git-dumper: verificación falló (binario no encontrado en PATH)"
        pipx list 2>&1 | grep -A3 -i "git-dumper" || true
    fi
}

function install_gittools() {
    install_git gittools https://github.com/internetwache/GitTools.git
    local finder="${KON_SRC}/gittools/Finder"
    local extractor="${KON_SRC}/gittools/Extractor"
    local dumper="${KON_SRC}/gittools/Dumper"
    if [[ -d "${finder}" ]]; then
        python3 -m venv --system-site-packages "${finder}/venv" >/dev/null 2>&1
        [[ -f "${finder}/requirements.txt" ]] && \
            "${finder}/venv/bin/pip" install -q --no-cache-dir \
                -r "${finder}/requirements.txt" 2>/dev/null
        cat > "${KON_BIN}/gitfinder.py" << EOF
#!/usr/bin/env bash
exec "${finder}/venv/bin/python3" "${finder}/gitfinder.py" "\$@"
EOF
        chmod +x "${KON_BIN}/gitfinder.py"
        ln -sf "${KON_BIN}/gitfinder.py" "${KON_BIN}/gitfinder"
    fi
    [[ -f "${extractor}/extractor.sh" ]] && link_bin extractor.sh "${extractor}/extractor.sh"
    [[ -f "${dumper}/gitdumper.sh" ]]    && link_bin gitdumper.sh "${dumper}/gitdumper.sh"
    _ok "git: gittools → ${KON_BIN}"
}

# ── XXE ──────────────────────────────────────────────────────────────────────
function install_xxeinjector() {
    curl -sL https://raw.githubusercontent.com/enjoiz/XXEinjector/refs/heads/master/XXEinjector.rb \
        -o "${KON_BIN}/XXEinjector.rb" \
        && chmod +x "${KON_BIN}/XXEinjector.rb" \
        && _ok "bin: XXEinjector.rb → ${KON_BIN}/XXEinjector.rb" \
        || _err "bin: XXEinjector"
}

# ── Recursive scanner ────────────────────────────────────────────────────────
function install_bbot() {
    # CODE-CHECK-WHITELIST=add-aliases
    colorecho "Installing BBOT"

    _ensure_pipx || return 1

    local log rc
    log=$(pipx install --system-site-packages bbot 2>&1)
    rc=$?
    if [[ ${rc} -eq 0 ]]; then
        _ok "pipx: bbot"
    else
        _err "pipx: bbot (rc=${rc})"
        echo "----- output -----"
        echo "${log}"
        echo "-------------------"
        return 1
    fi

    if command -v bbot >/dev/null 2>&1; then
        _ok "bbot: instalado correctamente"
    else
        _err "bbot: verificación falló (binario no encontrado en PATH)"
        pipx list 2>&1 | grep -A3 -i "bbot" || true
    fi
}

# ── Package runner ───────────────────────────────────────────────────────────
function package_web() {
    echo ""
    echo -e "\033[0;36m[*] ── WEB ──\033[0m"

    install_rvm
    install_pyenv
    set_env

    install_web_apt_tools

    install_weevely
    install_whatweb

    install_kiterunner
    install_dirsearch

    install_ssrfmap
    install_gopherus
    install_nosqlmap

    install_xsstrike
    install_xspear
    install_xsser

    install_xsrfprobe
    install_bolt

    install_kadimus
    install_fuxploider
    install_patator

    install_joomscan
    install_wpscan
    install_droopescan
    install_drupwn
    install_cmsmap
    install_moodlescan

    install_testssl
    install_sslscan

    install_cloudfail
    install_oneforall
    install_corscanner
    install_hakrawler
    install_linkfinder
    install_gau
    install_hakrevdns
    install_anew
    install_robotstester
    install_jsluice
    install_subzy
    install_urldedupe

    install_timing_attack
    install_updog
    install_wuzz
    install_curlie

    install_jwt_tool
    install_token_exploiter

    install_ysoserial
    install_phpggc
    install_symfony-exploits
    install_php_filter_chain_generator
    install_kraken

    install_httpmethods
    install_h2csmuggler
    install_smuggler
    install_byp4xx

    install_tomcatwardeployer

    install_git-dumper
    install_gittools

    install_xxeinjector

    install_bbot
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    package_web
fi
