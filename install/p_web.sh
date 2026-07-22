#!/usr/bin/env bash
# Author: z1rov

source /z1/install/common.sh
mkdir -p /anvil /opt/tools

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

function install_weevely() {
    install_apt weevely
}

function install_sqlmap() {
    install_apt sqlmap
}

function install_whatweb() {
    local dest="${Z1_SRC}/whatweb"
    rm -rf "${dest}" 2>/dev/null
    git clone -q --depth 1 https://github.com/urbanadventurer/WhatWeb.git "${dest}" \
        && _ok "git: whatweb â†’ ${dest}" || { _err "git: whatweb"; return 1; }
    source /usr/local/rvm/scripts/rvm
    rvm use "${Z1_RUBY_VERSION}@whatweb" --create >/dev/null 2>&1
    gem install -q addressable json rake >/dev/null 2>&1 \
        && _ok "gem: addressable json rake [gemset:whatweb]" \
        || _err "gem: addressable json rake [gemset:whatweb]"
    rvm use "${Z1_RUBY_VERSION}@default" >/dev/null 2>&1
    chmod +x "${dest}/whatweb"
    cat > "${Z1_BIN}/whatweb" << EOF
#!/usr/bin/env bash
source /usr/local/rvm/scripts/rvm 2>/dev/null
rvm use ${Z1_RUBY_VERSION}@whatweb >/dev/null 2>&1
exec ruby "${dest}/whatweb" "\$@"
EOF
    chmod +x "${Z1_BIN}/whatweb"
    _ok "whatweb: wrapper created at ${Z1_BIN}/whatweb"
    if "${Z1_BIN}/whatweb" --version >/dev/null 2>&1; then
        _ok "whatweb: installed successfully"
    else
        _err "whatweb: verification failed"
        "${Z1_BIN}/whatweb" --version 2>&1 | head -10
    fi
}

function install_kiterunner() {
    install_git kiterunner https://github.com/assetnote/kiterunner.git
    local dest="${Z1_SRC}/kiterunner"
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
    local dest="${Z1_SRC}/dirsearch"
    if [[ -d "${dest}" ]]; then
        python3 -m venv --system-site-packages "${dest}/venv" >/dev/null 2>&1
        venv_pip "${dest}" requests
        [[ -f "${dest}/requirements.txt" ]] && \
            venv_pip "${dest}" -r "${dest}/requirements.txt"
        cat > "${Z1_BIN}/dirsearch.py" << EOF
#!/usr/bin/env bash
exec "${dest}/venv/bin/python3" "${dest}/dirsearch.py" "\$@"
EOF
        chmod +x "${Z1_BIN}/dirsearch.py"
        ln -sf "${Z1_BIN}/dirsearch.py" "${Z1_BIN}/dirsearch"
        _ok "git: dirsearch â†’ ${Z1_BIN}/dirsearch"
    fi
}

function install_ssrfmap() {
    install_git ssrfmap https://github.com/swisskyrepo/SSRFmap
    local dest="${Z1_SRC}/ssrfmap"
    if [[ -d "${dest}" ]]; then
        python3 -m venv --system-site-packages "${dest}/venv" >/dev/null 2>&1
        venv_pip "${dest}" requests
        [[ -f "${dest}/requirements.txt" ]] && \
            venv_pip "${dest}" -r "${dest}/requirements.txt"
        cat > "${Z1_BIN}/ssrfmap.py" << EOF
#!/usr/bin/env bash
exec "${dest}/venv/bin/python3" "${dest}/ssrfmap.py" "\$@"
EOF
        chmod +x "${Z1_BIN}/ssrfmap.py"
        ln -sf "${Z1_BIN}/ssrfmap.py" "${Z1_BIN}/ssrfmap"
        _ok "git: ssrfmap â†’ ${Z1_BIN}/ssrfmap"
    fi
}

function install_gopherus() {
    install_git gopherus https://github.com/tarunkant/Gopherus
    local dest="${Z1_SRC}/gopherus"
    if [[ -d "${dest}" ]]; then
        pyvenv2_setup gopherus gopherus.py >/dev/null
        venv_pip2 "${dest}" argparse requests
        cat > "${Z1_BIN}/gopherus.py" << EOF
#!/usr/bin/env bash
exec "${dest}/venv/bin/python" "${dest}/gopherus.py" "\$@"
EOF
        chmod +x "${Z1_BIN}/gopherus.py"
        ln -sf "${Z1_BIN}/gopherus.py" "${Z1_BIN}/gopherus"
        _ok "git: gopherus â†’ ${Z1_BIN}/gopherus (python2.7)"
    fi
}

function install_nosqlmap() {
    install_git nosqlmap https://github.com/codingo/NoSQLMap.git
    local dest="${Z1_SRC}/nosqlmap"
    if [[ -d "${dest}" ]]; then
        pyvenv2_setup nosqlmap nosqlmap.py >/dev/null
        if [[ -f "${dest}/setup.py" ]]; then
            sed -i 's/requests==2\.32\.4/requests==2.27.1/' "${dest}/setup.py"
        fi
        (cd "${dest}" && "${dest}/venv/bin/python" setup.py install >/dev/null 2>&1) || true
        rm -rf "${dest}"/venv/lib/python2.7/site-packages/certifi-2023.5.7-py2.7.egg 2>/dev/null
        venv_pip2 "${dest}" "certifi==2018.10.15"
        cat > "${Z1_BIN}/nosqlmap.py" << EOF
#!/usr/bin/env bash
exec "${dest}/venv/bin/python" "${dest}/nosqlmap.py" "\$@"
EOF
        chmod +x "${Z1_BIN}/nosqlmap.py"
        ln -sf "${Z1_BIN}/nosqlmap.py" "${Z1_BIN}/nosqlmap"
        _ok "git: nosqlmap â†’ ${Z1_BIN}/nosqlmap (python2.7)"
    fi
}

function install_xsstrike() {
    install_git xsstrike https://github.com/s0md3v/XSStrike.git
    local dest="${Z1_SRC}/xsstrike"
    if [[ -d "${dest}" ]]; then
        python3 -m venv --system-site-packages "${dest}/venv" >/dev/null 2>&1
        venv_pip "${dest}" fuzzywuzzy python-Levenshtein
        [[ -f "${dest}/requirements.txt" ]] && \
            venv_pip "${dest}" -r "${dest}/requirements.txt"
        cat > "${Z1_BIN}/xsstrike.py" << EOF
#!/usr/bin/env bash
exec "${dest}/venv/bin/python3" "${dest}/xsstrike.py" "\$@"
EOF
        chmod +x "${Z1_BIN}/xsstrike.py"
        ln -sf "${Z1_BIN}/xsstrike.py" "${Z1_BIN}/xsstrike"
        _ok "git: xsstrike â†’ ${Z1_BIN}/xsstrike"
    fi
}

function install_bolt() {
    install_git bolt https://github.com/s0md3v/Bolt.git
    local dest="${Z1_SRC}/bolt"
    if [[ -d "${dest}" ]]; then
        python3 -m venv --system-site-packages "${dest}/venv" >/dev/null 2>&1
        venv_pip "${dest}" fuzzywuzzy python-Levenshtein
        [[ -f "${dest}/requirements.txt" ]] && \
            venv_pip "${dest}" -r "${dest}/requirements.txt"
        cat > "${Z1_BIN}/bolt" << EOF
#!/usr/bin/env bash
exec "${dest}/venv/bin/python3" "${dest}/bolt.py" "\$@"
EOF
        chmod +x "${Z1_BIN}/bolt"
        _ok "git: bolt â†’ ${Z1_BIN}/bolt"
    fi
}

function install_kadimus() {
    install_apt libcurl4-openssl-dev
    install_apt libpcre3-dev
    install_apt libssh-dev
    install_git kadimus https://github.com/P0cL4bs/Kadimus
    local dest="${Z1_SRC}/kadimus"
    if [[ -d "${dest}" ]]; then
        (cd "${dest}" && make -j >/dev/null 2>&1)
        link_bin kadimus "${dest}/kadimus"
    fi
}

function install_fuxploider() {
    install_git fuxploider https://github.com/almandin/fuxploider.git
    local dest="${Z1_SRC}/fuxploider"
    if [[ -d "${dest}" ]]; then
        python3 -m venv --system-site-packages "${dest}/venv" >/dev/null 2>&1
        venv_pip "${dest}" coloredlogs
        [[ -f "${dest}/requirements.txt" ]] && \
            venv_pip "${dest}" -r "${dest}/requirements.txt"
        cat > "${Z1_BIN}/fuxploider" << EOF
#!/usr/bin/env bash
cd "${dest}"
exec ./venv/bin/python3 fuxploider.py "\$@"
EOF
        chmod +x "${Z1_BIN}/fuxploider"
        _ok "git: fuxploider â†’ ${Z1_BIN}/fuxploider"
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
    local dest="${Z1_SRC}/patator"
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
        cat > "${Z1_BIN}/patator.py" << EOF
#!/usr/bin/env bash
exec "${dest}/venv/bin/python3" "${patator_script}" "\$@"
EOF
        chmod +x "${Z1_BIN}/patator.py"
        ln -sf "${Z1_BIN}/patator.py" "${Z1_BIN}/patator"
        _ok "git: patator â†’ ${Z1_BIN}/patator"
    fi
}

function install_joomscan() {
    install_git joomscan https://github.com/rezasp/joomscan
    local dest="${Z1_SRC}/joomscan"
    if [[ -d "${dest}" ]]; then
        cat > "${Z1_BIN}/joomscan" << EOF
#!/usr/bin/env bash
exec perl "${dest}/joomscan.pl" "\$@"
EOF
        chmod +x "${Z1_BIN}/joomscan"
        _ok "git: joomscan â†’ ${Z1_BIN}/joomscan"
    fi
}

function install_wpscan() {
    source /usr/local/rvm/scripts/rvm 2>/dev/null || true
    rvm use "${Z1_RUBY_VERSION}@wpscan" --create >/dev/null 2>&1
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
            git clone -q --depth 1 https://github.com/wpscanteam/wpscan.git /tmp/wpscan-src >/dev/null 2>&1
            (
                cd /tmp/wpscan-src
                bundle install >/dev/null 2>&1
                gem build wpscan.gemspec >/dev/null 2>&1
                gem install wpscan-*.gem >/dev/null 2>&1
            )
            rm -rf /tmp/wpscan-src
        }
    rvm use "${Z1_RUBY_VERSION}@default" >/dev/null 2>&1
    cat > "${Z1_BIN}/wpscan" << EOF
#!/usr/bin/env bash
source /usr/local/rvm/scripts/rvm 2>/dev/null
rvm use ${Z1_RUBY_VERSION}@wpscan >/dev/null 2>&1
exec wpscan "\$@"
EOF
    chmod +x "${Z1_BIN}/wpscan"
    if "${Z1_BIN}/wpscan" --help >/dev/null 2>&1; then
        _ok "wpscan: installed successfully â†’ ${Z1_BIN}/wpscan"
    else
        _err "wpscan: verification failed"
    fi
}

function install_droopescan() {
    if command -v pipx >/dev/null 2>&1; then
        pipx install --system-site-packages git+https://github.com/droope/droopescan.git >/dev/null 2>&1 \
            && _ok "pipx: droopescan" || _err "pipx: droopescan"
    else
        _err "pipx: not available"
    fi
    pip3 install -q --no-cache-dir --break-system-packages git+https://github.com/droope/droopescan.git >/dev/null 2>&1 \
        && _ok "pip: droopescan" || {
            _err "pip: droopescan"
            return 1
        }
    if command -v droopescan >/dev/null 2>&1; then
        _ok "droopescan: installed successfully"
    else
        local droopescan_bin
        droopescan_bin=$(find /usr/local/bin /root/.local/bin /usr/bin -name "droopescan" 2>/dev/null | head -1)
        if [[ -n "${droopescan_bin}" ]]; then
            ln -sf "${droopescan_bin}" "${Z1_BIN}/droopescan"
            _ok "droopescan: symlink created â†’ ${Z1_BIN}/droopescan"
        else
            _err "droopescan: binary not found"
            return 1
        fi
    fi
    if droopescan --help >/dev/null 2>&1 || "${Z1_BIN}/droopescan" --help >/dev/null 2>&1; then
        _ok "droopescan: verification OK"
    else
        _err "droopescan: verification failed"
        return 1
    fi
}

function install_drupwn() {
    local dest="${Z1_SRC}/drupwn"
    if [[ ! -d "${dest}" ]]; then
        git clone -q --depth 1 https://github.com/immunIT/drupwn "${dest}" >/dev/null 2>&1 \
            && _ok "git: drupwn â†’ ${dest}" || { _err "git: drupwn"; return 1; }
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
        _info "pkg_resources forced reinstall"
    fi
    while IFS= read -r -d '' init_file; do
        cp "${init_file}" "${init_file}.bak"
        cat > "${init_file}" << 'EOF'
# Patched for Python 3.13: implicit namespace package (PEP 420),
# pkg_resources.declare_namespace() not required
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
    cat > "${Z1_BIN}/drupwn" << EOF
#!/usr/bin/env bash
export PYTHONPATH="${site_packages}:\$PYTHONPATH"
exec "${dest}/venv/bin/python3" "${dest}/drupwn" "\$@"
EOF
    chmod +x "${Z1_BIN}/drupwn"
    if "${Z1_BIN}/drupwn" --help >/dev/null 2>&1; then
        _ok "drupwn: installed successfully"
        _info "usage: drupwn --target http://target.com --mode enum"
        _info "       drupwn --target http://target.com --mode exploit"
    else
        _err "drupwn: verification failed"
        "${Z1_BIN}/drupwn" --help 2>&1 | head -10
    fi
}

function install_cmsmap() {
    local dest="${Z1_SRC}/cmsmap"
    if [[ -d "${dest}" ]]; then
        rm -rf "${dest}"
    fi
    _run_logged "git: cmsmap" git clone -q --depth 1 https://github.com/Dionach/CMSmap.git "${dest}" \
        || return 1
    local _p _stale
    IFS=':' read -ra _path_dirs <<< "${PATH}"
    for _p in "${_path_dirs[@]}"; do
        _stale="${_p}/cmsmap"
        if [[ -f "${_stale}" || -L "${_stale}" ]]; then
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
        cat > "${Z1_BIN}/cmsmap" << EOF
#!/usr/bin/env bash
exec "${venv_py}" -c "import sys; from cmsmap.main import main; sys.exit(main())" "\$@"
EOF
        chmod +x "${Z1_BIN}/cmsmap"
        _ok "cmsmap: wrapper created at ${Z1_BIN}/cmsmap"
    else
        _err "cmsmap: module 'cmsmap.main' not importable in venv"
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
        _err "cmsmap.conf not found, could not patch"
        find "${dest}" -iname "cmsmap.conf" 2>&1
    fi
    if "${Z1_BIN}/cmsmap" --help >/dev/null 2>&1; then
        _ok "cmsmap: installed successfully"
    else
        _err "cmsmap: verification failed"
        "${Z1_BIN}/cmsmap" --help 2>&1 | head -10
    fi
}

function install_moodlescan() {
    install_git moodlescan https://github.com/inc0d3/moodlescan.git
    local dest="${Z1_SRC}/moodlescan"
    if [[ -d "${dest}" ]]; then
        python3 -m venv --system-site-packages "${dest}/venv" >/dev/null 2>&1
        [[ -f "${dest}/requirements.txt" ]] && \
            venv_pip "${dest}" -r "${dest}/requirements.txt"
        (cd "${dest}" && ./venv/bin/python3 moodlescan.py -a >/dev/null 2>&1) || true
        cat > "${Z1_BIN}/moodlescan.py" << EOF
#!/usr/bin/env bash
exec "${dest}/venv/bin/python3" "${dest}/moodlescan.py" "\$@"
EOF
        chmod +x "${Z1_BIN}/moodlescan.py"
        ln -sf "${Z1_BIN}/moodlescan.py" "${Z1_BIN}/moodlescan"
        _ok "git: moodlescan â†’ ${Z1_BIN}/moodlescan"
    fi
}

function install_testssl() {
    install_apt bsdmainutils
    install_git testssl https://github.com/drwetter/testssl.sh.git
    link_bin testssl.sh "${Z1_SRC}/testssl/testssl.sh"
    ln -sf "${Z1_BIN}/testssl.sh" "${Z1_BIN}/testssl"
    _ok "bin: testssl alias â†’ ${Z1_BIN}/testssl"
}

function install_sslscan() {
    local tmp_dir
    tmp_dir=$(mktemp -d)
    git clone -q --depth 1 https://github.com/rbsec/sslscan.git "${tmp_dir}" >/dev/null 2>&1 \
        && _ok "git: sslscan (tmp)" || { _err "git: sslscan"; return; }
    (cd "${tmp_dir}" && make static >/dev/null 2>&1)
    if [[ -f "${tmp_dir}/sslscan" ]]; then
        mv "${tmp_dir}/sslscan" "${Z1_BIN}/sslscan"
        chmod +x "${Z1_BIN}/sslscan"
        _ok "bin: sslscan â†’ ${Z1_BIN}/sslscan"
    else
        _err "sslscan: make static failed"
    fi
    rm -rf "${tmp_dir}"
}

function install_cloudfail() {
    local dest="${Z1_SRC}/CloudFail"
    if [[ -d "${dest}" ]]; then
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
    cat > "${Z1_BIN}/cloudfail" << EOF
#!/usr/bin/env bash
exec "${dest}/venv/bin/python3" "${dest}/cloudfail.py" "\$@"
EOF
    chmod +x "${Z1_BIN}/cloudfail"
    _ok "cloudfail: wrapper created at ${Z1_BIN}/cloudfail"
    if "${Z1_BIN}/cloudfail" --help >/dev/null 2>&1; then
        _ok "cloudfail: installed successfully"
    else
        _err "cloudfail: verification failed"
        "${Z1_BIN}/cloudfail" --help 2>&1 | head -10
    fi
}

function install_oneforall() {
    local dest="${Z1_SRC}/OneForAll"
    if [[ -d "${dest}" ]]; then
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
"""Compatibility shim: `pipes` module was removed in Python 3.13.
python-fire (OneForAll dependency) still does `import pipes` and uses
`pipes.quote`, which is equivalent to `shlex.quote`."""
from shlex import quote
EOF
    _ok "shim: pipes -> shlex (Python 3.13 compat)"
    cat > "${Z1_BIN}/oneforall" << EOF
#!/usr/bin/env bash
cd "${dest}" && exec "${dest}/venv/bin/python3" "${dest}/oneforall.py" "\$@"
EOF
    chmod +x "${Z1_BIN}/oneforall"
    _ok "oneforall: wrapper created at ${Z1_BIN}/oneforall"
    if "${Z1_BIN}/oneforall" check >/dev/null 2>&1; then
        _ok "oneforall: installed successfully"
    else
        _err "oneforall: verification failed"
        "${Z1_BIN}/oneforall" check 2>&1 | head -10
    fi
}

function install_corscanner() {
    install_git corscanner https://github.com/chenjj/CORScanner.git
    local dest="${Z1_SRC}/corscanner"
    if [[ -d "${dest}" ]]; then
        python3 -m venv --system-site-packages "${dest}/venv" >/dev/null 2>&1
        venv_pip "${dest}" gevent
        [[ -f "${dest}/requirements.txt" ]] && \
            venv_pip "${dest}" -r "${dest}/requirements.txt"
        cat > "${Z1_BIN}/cors_scan" << EOF
#!/usr/bin/env bash
exec "${dest}/venv/bin/python3" "${dest}/cors_scan.py" "\$@"
EOF
        chmod +x "${Z1_BIN}/cors_scan"
        _ok "git: corscanner â†’ ${Z1_BIN}/cors_scan"
    fi
}

function install_hakrawler() {
    install_go hakrawler github.com/hakluke/hakrawler@latest
}

function install_linkfinder() {
    install_git linkfinder https://github.com/GerbenJavado/LinkFinder.git
    local dest="${Z1_SRC}/linkfinder"
    if [[ -d "${dest}" ]]; then
        python3 -m venv --system-site-packages "${dest}/venv" >/dev/null 2>&1
        venv_pip "${dest}" jsbeautifier
        [[ -f "${dest}/requirements.txt" ]] && \
            venv_pip "${dest}" -r "${dest}/requirements.txt"
        cat > "${Z1_BIN}/linkfinder.py" << EOF
#!/usr/bin/env bash
exec "${dest}/venv/bin/python3" "${dest}/linkfinder.py" "\$@"
EOF
        chmod +x "${Z1_BIN}/linkfinder.py"
        ln -sf "${Z1_BIN}/linkfinder.py" "${Z1_BIN}/linkfinder"
        _ok "git: linkfinder â†’ ${Z1_BIN}/linkfinder"
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
        mv "${tmp_dir}/urldedupe" "${Z1_BIN}/urldedupe"
        chmod +x "${Z1_BIN}/urldedupe"
        _ok "bin: urldedupe â†’ ${Z1_BIN}/urldedupe"
    else
        _err "urldedupe: make failed"
    fi
    rm -rf "${tmp_dir}"
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
        mv /tmp/curlie "${Z1_BIN}/curlie"
        chmod +x "${Z1_BIN}/curlie"
        _ok "bin: curlie â†’ ${Z1_BIN}/curlie"
    else
        _err "bin: curlie"
    fi
}

function install_jwt_tool() {
    install_git jwt_tool https://github.com/ticarpi/jwt_tool
    local dest="${Z1_SRC}/jwt_tool"
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
        cat > "${Z1_BIN}/jwt_tool.py" << EOF
#!/usr/bin/env bash
exec "${dest}/venv/bin/python3" "${dest}/jwt_tool.py" "\$@"
EOF
        chmod +x "${Z1_BIN}/jwt_tool.py"
        ln -sf "${Z1_BIN}/jwt_tool.py" "${Z1_BIN}/jwt_tool"
        _ok "git: jwt_tool â†’ ${Z1_BIN}/jwt_tool"
    fi
}

function install_token_exploiter() {
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
        echo "------------------"
        return 1
    fi
    if command -v token-exploiter >/dev/null 2>&1; then
        _ok "token-exploiter: installed successfully"
    else
        _err "token-exploiter: binary not found in PATH"
        pipx list 2>&1 | grep -A3 -i "token-exploiter" || true
    fi
}

function install_ysoserial() {
    local dest="${Z1_SRC}/ysoserial"
    mkdir -p "${dest}"
    curl -sL -o "${dest}/ysoserial.jar" \
        "https://github.com/frohoff/ysoserial/releases/latest/download/ysoserial-all.jar" \
        && _ok "src: ysoserial.jar" || { _err "src: ysoserial.jar"; return; }
    cat > "${Z1_BIN}/ysoserial" << EOF
#!/usr/bin/env bash
exec java -jar "${dest}/ysoserial.jar" "\$@"
EOF
    chmod +x "${Z1_BIN}/ysoserial"
    _ok "bin: ysoserial â†’ ${Z1_BIN}/ysoserial"
}

function install_phpggc() {
    install_git phpggc https://github.com/ambionics/phpggc.git
    link_bin phpggc "${Z1_SRC}/phpggc/phpggc"
}

function install_symfony-exploits() {
    install_git symfony-exploits https://github.com/ambionics/symfony-exploits
    local dest="${Z1_SRC}/symfony-exploits"
    if [[ -d "${dest}" ]]; then
        python3 -m venv --system-site-packages "${dest}/venv" >/dev/null 2>&1
        venv_pip "${dest}" requests
        cat > "${Z1_BIN}/secret_fragment_exploit.py" << EOF
#!/usr/bin/env bash
exec "${dest}/venv/bin/python3" "${dest}/secret_fragment_exploit.py" "\$@"
EOF
        chmod +x "${Z1_BIN}/secret_fragment_exploit.py"
        _ok "git: symfony-exploits â†’ ${Z1_BIN}/secret_fragment_exploit.py"
    fi
}

function install_php_filter_chain_generator() {
    install_git php_filter_chain_generator \
        https://github.com/synacktiv/php_filter_chain_generator.git
    link_bin php_filter_chain_generator.py \
        "${Z1_SRC}/php_filter_chain_generator/php_filter_chain_generator.py"
}

function install_kraken() {
    install_git kraken https://github.com/kraken-ng/Kraken.git
    local dest="${Z1_SRC}/kraken"
    if [[ -d "${dest}" ]]; then
        python3 -m venv --system-site-packages "${dest}/venv" >/dev/null 2>&1
        venv_pip "${dest}" jsonschema validators
        [[ -f "${dest}/requirements.txt" ]] && \
            venv_pip "${dest}" -r "${dest}/requirements.txt"
        cat > "${Z1_BIN}/kraken" << EOF
#!/usr/bin/env bash
exec "${dest}/venv/bin/python3" "${dest}/kraken.py" "\$@"
EOF
        chmod +x "${Z1_BIN}/kraken"
        _ok "git: kraken â†’ ${Z1_BIN}/kraken"
    fi
}

function install_httpmethods() {
    install_git httpmethods https://github.com/ShutdownRepo/httpmethods
    local dest="${Z1_SRC}/httpmethods"
    if [[ -d "${dest}" ]]; then
        python3 -m venv --system-site-packages "${dest}/venv" >/dev/null 2>&1
        venv_pip "${dest}" requests
        [[ -f "${dest}/requirements.txt" ]] && \
            venv_pip "${dest}" -r "${dest}/requirements.txt"
        cat > "${Z1_BIN}/httpmethods" << EOF
#!/usr/bin/env bash
exec "${dest}/venv/bin/python3" "${dest}/httpmethods.py" "\$@"
EOF
        chmod +x "${Z1_BIN}/httpmethods"
        _ok "git: httpmethods â†’ ${Z1_BIN}/httpmethods"
    fi
}

function install_h2csmuggler() {
    install_git h2csmuggler https://github.com/BishopFox/h2csmuggler
    local dest="${Z1_SRC}/h2csmuggler"
    if [[ -d "${dest}" ]]; then
        python3 -m venv --system-site-packages "${dest}/venv" >/dev/null 2>&1
        venv_pip "${dest}" h2
        cat > "${Z1_BIN}/h2csmuggler.py" << EOF
#!/usr/bin/env bash
exec "${dest}/venv/bin/python3" "${dest}/h2csmuggler.py" "\$@"
EOF
        chmod +x "${Z1_BIN}/h2csmuggler.py"
        ln -sf "${Z1_BIN}/h2csmuggler.py" "${Z1_BIN}/h2csmuggler"
        _ok "git: h2csmuggler â†’ ${Z1_BIN}/h2csmuggler"
    fi
}

function install_smuggler() {
    install_git smuggler https://github.com/defparam/smuggler.git
    local dest="${Z1_SRC}/smuggler"
    if [[ -d "${dest}" ]]; then
        python3 -m venv --system-site-packages "${dest}/venv" >/dev/null 2>&1
        cat > "${Z1_BIN}/smuggler.py" << EOF
#!/usr/bin/env bash
exec "${dest}/venv/bin/python3" "${dest}/smuggler.py" "\$@"
EOF
        chmod +x "${Z1_BIN}/smuggler.py"
        ln -sf "${Z1_BIN}/smuggler.py" "${Z1_BIN}/smuggler"
        _ok "git: smuggler â†’ ${Z1_BIN}/smuggler"
    fi
}

function install_byp4xx() {
    install_go byp4xx github.com/lobuhi/byp4xx@latest
}

function install_tomcatwardeployer() {
    install_git tomcatwardeployer https://github.com/mgeeky/tomcatWarDeployer.git
    local dest="${Z1_SRC}/tomcatwardeployer"
    if [[ -d "${dest}" ]]; then
        python3 -m venv --system-site-packages "${dest}/venv" >/dev/null 2>&1
        venv_pip "${dest}" mechanize
        [[ -f "${dest}/requirements.txt" ]] && \
            venv_pip "${dest}" -r "${dest}/requirements.txt"
        cat > "${Z1_BIN}/tomcatWarDeployer" << EOF
#!/usr/bin/env bash
exec "${dest}/venv/bin/python3" "${dest}/tomcatWarDeployer.py" "\$@"
EOF
        chmod +x "${Z1_BIN}/tomcatWarDeployer"
        _ok "git: tomcatwardeployer â†’ ${Z1_BIN}/tomcatWarDeployer"
    fi
}

function install_git-dumper() {
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
        echo "------------------"
        return 1
    fi
    if command -v git-dumper >/dev/null 2>&1; then
        _ok "git-dumper: installed successfully"
    else
        _err "git-dumper: binary not found in PATH"
        pipx list 2>&1 | grep -A3 -i "git-dumper" || true
    fi
}

function install_gittools() {
    install_git gittools https://github.com/internetwache/GitTools.git
    local finder="${Z1_SRC}/gittools/Finder"
    local extractor="${Z1_SRC}/gittools/Extractor"
    local dumper="${Z1_SRC}/gittools/Dumper"
    if [[ -d "${finder}" ]]; then
        python3 -m venv --system-site-packages "${finder}/venv" >/dev/null 2>&1
        [[ -f "${finder}/requirements.txt" ]] && \
            "${finder}/venv/bin/pip" install -q --no-cache-dir \
                -r "${finder}/requirements.txt" 2>/dev/null
        cat > "${Z1_BIN}/gitfinder.py" << EOF
#!/usr/bin/env bash
exec "${finder}/venv/bin/python3" "${finder}/gitfinder.py" "\$@"
EOF
        chmod +x "${Z1_BIN}/gitfinder.py"
        ln -sf "${Z1_BIN}/gitfinder.py" "${Z1_BIN}/gitfinder"
    fi
    [[ -f "${extractor}/extractor.sh" ]] && link_bin extractor.sh "${extractor}/extractor.sh"
    [[ -f "${dumper}/gitdumper.sh" ]]    && link_bin gitdumper.sh "${dumper}/gitdumper.sh"
    _ok "git: gittools â†’ ${Z1_BIN}"
}

function install_xxeinjector() {
    curl -sL https://raw.githubusercontent.com/enjoiz/XXEinjector/refs/heads/master/XXEinjector.rb \
        -o "${Z1_BIN}/XXEinjector.rb" \
        && chmod +x "${Z1_BIN}/XXEinjector.rb" \
        && _ok "bin: XXEinjector.rb â†’ ${Z1_BIN}/XXEinjector.rb" \
        || _err "bin: XXEinjector"
}

function install_bbot() {
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
        echo "------------------"
        return 1
    fi
    if command -v bbot >/dev/null 2>&1; then
        _ok "bbot: installed successfully"
    else
        _err "bbot: binary not found in PATH"
        pipx list 2>&1 | grep -A3 -i "bbot" || true
    fi
}

function p_web() {
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
    install_sqlmap

    install_xsstrike
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
    install_jsluice
    install_subzy
    install_urldedupe

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
