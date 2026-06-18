#!/usr/bin/env bash
source /kon/install/common.sh

function install_ad_base() {
    install_apt krb5-user
    install_apt krb5-config
    install_apt libkrb5-dev
    install_apt ldap-utils
    install_apt smbclient
    install_apt samba-common-bin
    install_apt samba
    install_apt nbtscan
    install_apt onesixtyone
    install_apt samdump2
    install_apt freerdp2-x11
    install_apt hydra
    install_apt hashcat
    install_apt ncat
    install_apt proxychains4
    install_apt ruby
    install_apt ruby-dev
    install_apt pipx
    install_apt libpcap-dev
    install_apt libmagic1
    install_apt python3-ldap3
    install_apt jq
    install_apt lsof
    install_apt unzip
    install_apt python3-venv
    install_apt python3-pip
}

function install_bloodhound_ce() {
    local BHD_DIR="${KON_SRC}/bhce-src"

    if [[ -d "${BHD_DIR}" ]]; then
        _info "skip: bloodhound-ce.py (already exists)"
    else
        git clone -q --depth 1 --branch bloodhound-ce \
            https://github.com/dirkjanm/BloodHound.py "${BHD_DIR}" >/dev/null 2>&1 \
            || { _err "bloodhound-ce.py: git clone failed"; return 1; }

        python3 -m venv --system-site-packages "${BHD_DIR}/venv" >/dev/null 2>&1
        "${BHD_DIR}/venv/bin/pip3" install -q --no-cache-dir "${BHD_DIR}" >/dev/null 2>&1 \
            || { _err "bloodhound-ce.py: pip install failed"; return 1; }
    fi

    # Wrapper ejecutable: vive en KON_BIN como TODO lo demás, no en /usr/local/bin.
    cat > "${KON_BIN}/bloodhound-ce.py" << EOF
#!/usr/bin/env bash
exec "${BHD_DIR}/venv/bin/bloodhound-ce-python" "\$@"
EOF
    chmod +x "${KON_BIN}/bloodhound-ce.py"

    _ok "bloodhound-ce.py → ${KON_BIN}/bloodhound-ce.py"
}

function install_evil_winrm() {
    gem install evil-winrm >/dev/null 2>&1 \
        && _ok "gem: evil-winrm" || _err "gem: evil-winrm"
}

function install_john() {
    local JOHN_DIR="${KON_SRC}/john"
    local RUN_DIR="${JOHN_DIR}/run"

    if [[ -d "${JOHN_DIR}" ]]; then
        _info "skip: john (already exists)"
    else
        install_apt build-essential
        install_apt libssl-dev
        install_apt zlib1g-dev
        install_apt libbz2-dev
        install_apt libpcap-dev
        install_apt libgmp-dev
        install_apt pkg-config
        install_apt git

        _info "Cloning John the Ripper Jumbo from GitHub..."
        git clone -q --depth 1 https://github.com/openwall/john "${JOHN_DIR}" >/dev/null 2>&1 \
            || { _err "git: john"; return 1; }

        ( cd "${JOHN_DIR}/src" || { _err "cd: john/src"; return 1; }

          _info "Configuring build..."
          ./configure --disable-native-tests >/dev/null 2>&1 \
              || { _err "john: configure failed"; exit 1; }

          _info "Compiling John (this may take a few minutes)..."
          make -sj"$(nproc)" >/dev/null 2>&1 \
              || { _err "john: build failed"; exit 1; }
        ) || return 1
    fi

    # Wrapper principal en KON_BIN (no /usr/local/bin).
    cat > "${KON_BIN}/john" << EOF
#!/usr/bin/env bash
cd "${RUN_DIR}" && exec ./john "\$@"
EOF
    chmod +x "${KON_BIN}/john"

    # Helpers (*2john*, unshadow, unafs, unique) → todos a KON_BIN también.
    local f base
    for f in "${RUN_DIR}"/*2john* "${RUN_DIR}/unshadow" "${RUN_DIR}/unafs" "${RUN_DIR}/unique"; do
        [[ -f "$f" ]] || continue
        base="$(basename "$f")"
        if [[ "$f" == *.py ]]; then
            cat > "${KON_BIN}/${base%.py}" << EOF
#!/usr/bin/env bash
cd "${RUN_DIR}" && exec python3 "$f" "\$@"
EOF
            chmod +x "${KON_BIN}/${base%.py}"
        elif [[ -x "$f" ]]; then
            cat > "${KON_BIN}/$base" << EOF
#!/usr/bin/env bash
cd "${RUN_DIR}" && exec "$f" "\$@"
EOF
            chmod +x "${KON_BIN}/$base"
        fi
    done

    if "${KON_BIN}/john" --help >/dev/null 2>&1; then
        _ok "john: installed jumbo (latest from source) → ${KON_BIN}/john"
        _info "Run 'john --test' to benchmark"
        _info "Run 'john --list=formats' to see available formats"
        _info "Helpers available: ssh2john, zip2john, rar2john, etc. (in ${KON_BIN})"
    else
        _err "john: build finished but binary not found in ${KON_BIN}"
    fi
}

function install_impacket() { install_pip impacket; }

function install_certipy()        { install_pip certipy-ad; }
function install_bloodyad()       { install_pip bloodyAD; }
function install_ldapdomaindump() { install_pip ldapdomaindump; }
function install_ldeep()          { install_pip ldeep; }
function install_mitm6()          { install_pip mitm6; }
function install_adidnsdump()     { install_pip adidnsdump; }
function install_aclpwn() {
    _info "skip: aclpwn (abandoned, py2-only wheel on PyPI, not installable on python3)"
}
function install_coercer()        { install_pip coercer; }
function install_donpapi()        { install_pip donpapi; }
function install_sprayhound()     {
    install_pip sprayhound \
        || _info "note: sprayhound may have broken/frozen deps on current pip/python"
}
function install_smbmap()         { install_pip smbmap; }
function install_pypykatz()       { install_pip pypykatz; }
function install_goldencopy()     { install_pip goldencopy; }
function install_gpp_decrypt()    { install_pip gpp-decrypt; }
function install_roadrecon()      {
    install_pip roadrecon \
        || _info "note: roadrecon may have broken/frozen deps on current pip/python"
}

function install_netexec() {
    pipx install git+https://github.com/Pennyw0rth/NetExec >/dev/null 2>&1 \
        && _ok "pipx: netexec" || _err "pipx: netexec"
}

function install_manspider() {
    install_git manspider https://github.com/blacklanternsecurity/MANSPIDER
    pip3 install -q --no-cache-dir --break-system-packages "${KON_SRC}/manspider" >/dev/null 2>&1 \
        && _ok "pip: manspider" || _err "pip: manspider"
}

function install_enum4linux_ng() {
    install_git enum4linux-ng https://github.com/cddmp/enum4linux-ng
    pip3 install -q --no-cache-dir --break-system-packages "${KON_SRC}/enum4linux-ng" >/dev/null 2>&1 \
        && _ok "pip: enum4linux-ng" || _err "pip: enum4linux-ng"
    link_bin enum4linux-ng "${KON_SRC}/enum4linux-ng/enum4linux-ng.py"
}

function install_pcredz() {
    install_pip Cython
    install_pip python-libpcap
    install_git PCredz https://github.com/lgandx/PCredz
    link_bin Pcredz.py "${KON_SRC}/PCredz/Pcredz"
}

function install_enum4linux() {
    install_git enum4linux https://github.com/CiscoCXSecurity/enum4linux
    link_bin enum4linux "${KON_SRC}/enum4linux/enum4linux.pl"
}

function install_powerview_py() {
    pip3 install -q --no-cache-dir --break-system-packages \
        git+https://github.com/aniqfakhrul/powerview.py >/dev/null 2>&1 \
        && _ok "pip: powerview.py" || _err "pip: powerview.py"
}

function install_pywerview() {
    install_git pywerview https://github.com/the-useless-one/pywerview
    pip3 install -q --no-cache-dir --break-system-packages "${KON_SRC}/pywerview" >/dev/null 2>&1 \
        && _ok "git+pip: pywerview" || _err "pip: pywerview"
}

function install_responder() {
    install_git Responder https://github.com/lgandx/Responder
    link_bin Responder.py "${KON_SRC}/Responder/Responder.py"
}

function install_petitpotam() {
    install_git PetitPotam https://github.com/topotam/PetitPotam
    link_bin PetitPotam.py "${KON_SRC}/PetitPotam/PetitPotam.py"
}

function install_dfscoerce() {
    install_git DFSCoerce https://github.com/Wh04m1001/DFSCoerce
    link_bin dfscoerce.py "${KON_SRC}/DFSCoerce/dfscoerce.py"
}

function install_shadowcoerce() {
    install_git ShadowCoerce https://github.com/ShutdownRepo/ShadowCoerce
    link_bin shadowcoerce.py "${KON_SRC}/ShadowCoerce/shadowcoerce.py"
}

function install_zerologon() {
    install_git zerologon-scan https://github.com/SecuraBV/CVE-2020-1472
    link_bin zerologon-scan.py "${KON_SRC}/zerologon-scan/zerologon_tester.py"
}

function install_noPac() {
    install_git noPac https://github.com/Ridter/noPac
    link_bin noPac.py "${KON_SRC}/noPac/noPac.py"
    link_bin noPac-scanner.py "${KON_SRC}/noPac/scanner.py"
}

function install_pykek() {
    install_git pykek https://github.com/preempt/pykek
    link_bin ms14-068.py "${KON_SRC}/pykek/ms14-068.py"
}

function install_windapsearch() {
    install_git windapsearch https://github.com/ropnop/windapsearch
    link_bin windapsearch.py "${KON_SRC}/windapsearch/windapsearch.py"
}

function install_ldapnomnom() {
    install_git ldapnomnom https://github.com/lkarlslund/ldapnomnom
}

function install_targetedkerberoast() {
    install_git targetedKerberoast https://github.com/ShutdownRepo/targetedKerberoast
    link_bin targetedKerberoast.py "${KON_SRC}/targetedKerberoast/targetedKerberoast.py"
}

function install_krbrelayx() {
    install_git krbrelayx https://github.com/dirkjanm/krbrelayx
    link_bin krbrelayx.py "${KON_SRC}/krbrelayx/krbrelayx.py"
    link_bin dnstool.py "${KON_SRC}/krbrelayx/dnstool.py"
    link_bin printerbug.py "${KON_SRC}/krbrelayx/printerbug.py"
    link_bin addspn.py "${KON_SRC}/krbrelayx/addspn.py"
}

function install_pkinittools() {
    install_git PKINITtools https://github.com/dirkjanm/PKINITtools
    link_bin gettgtpkinit.py "${KON_SRC}/PKINITtools/gettgtpkinit.py"
    link_bin getnthash.py "${KON_SRC}/PKINITtools/getnthash.py"
}

function install_pywhisker() {
    install_git pywhisker https://github.com/ShutdownRepo/pywhisker
    pip3 install -q --no-cache-dir --break-system-packages "${KON_SRC}/pywhisker" >/dev/null 2>&1 \
        && _ok "pip: pywhisker" || _err "pip: pywhisker"
    # El repo es un paquete instalable (pyproject.toml), no un script suelto:
    # pywhisker.py vive dentro de pywhisker/pywhisker/ y usa imports relativos,
    # así que no se puede link_bin directo. pip install ya deja el entry point
    # en /usr/local/bin (scripts dir estándar con --break-system-packages).
    if [[ -f /usr/local/bin/pywhisker ]]; then
        link_bin pywhisker /usr/local/bin/pywhisker
    else
        # Fallback: invocar el paquete como módulo si no se generó entry point.
        cat > "${KON_BIN}/pywhisker" << EOF
#!/usr/bin/env bash
exec python3 -m pywhisker.pywhisker "\$@"
EOF
        chmod +x "${KON_BIN}/pywhisker"
        _ok "bin: pywhisker → ${KON_BIN}/pywhisker (module wrapper)"
    fi
}

function install_gmsadumper() {
    install_git gMSADumper https://github.com/micahvandeusen/gMSADumper
    link_bin gMSADumper.py "${KON_SRC}/gMSADumper/gMSADumper.py"
}

function install_kerbrute()      { install_go kerbrute      github.com/ropnop/kerbrute@latest; }
function install_gosecretsdump() { install_go gosecretsdump github.com/C-Sto/gosecretsdump@latest; }
function install_godap()         { install_go godap          github.com/Macmod/godap@latest; }

function package_ad() {
    echo ""
    echo -e "\033[0;36m[*] ┌┬┬ ACTIVE DIRECTORY ┬┬┐\033[0m"
    install_ad_base
    install_bloodhound_ce
    install_evil_winrm
    install_john
    install_impacket
    install_certipy
    install_bloodyad
    install_ldapdomaindump
    install_ldeep
    install_mitm6
    install_adidnsdump
    install_aclpwn
    install_manspider
    install_coercer
    install_donpapi
    install_sprayhound
    install_smbmap
    install_pypykatz
    install_goldencopy
    install_enum4linux_ng
    install_gpp_decrypt
    install_pcredz
    install_roadrecon
    install_netexec
    install_powerview_py
    install_pywerview
    install_responder
    install_petitpotam
    install_dfscoerce
    install_shadowcoerce
    install_zerologon
    install_noPac
    install_pykek
    install_windapsearch
    install_ldapnomnom
    install_targetedkerberoast
    install_krbrelayx
    install_pkinittools
    install_pywhisker
    install_gmsadumper
    install_enum4linux
    install_kerbrute
    install_gosecretsdump
    install_godap
}
