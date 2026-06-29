#!/usr/bin/env bash
# Author: Zirov
source /kon/install/common.sh
mkdir -p /opt/tools

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
    install_apt gcc-mingw-w64-x86-64
}

function install_bloodhound_ce() {
    local BHD_DIR="${KON_SRC}/bhce-src"
    if [[ -d "${BHD_DIR}" ]]; then
        _info "skip: bloodhound-ce.py (already exists)"
    else
        git clone -q --depth 1 --branch bloodhound-ce https://github.com/dirkjanm/BloodHound.py "${BHD_DIR}" >/dev/null 2>&1 || { _err "bloodhound-ce.py: git clone failed"; return 1; }
        python3 -m venv --system-site-packages "${BHD_DIR}/venv" >/dev/null 2>&1
        "${BHD_DIR}/venv/bin/pip3" install -q --no-cache-dir "${BHD_DIR}" >/dev/null 2>&1 || { _err "bloodhound-ce.py: pip install failed"; return 1; }
    fi
    cat > "${KON_BIN}/bloodhound-ce.py" << WRAPPER
#!/usr/bin/env bash
exec "${BHD_DIR}/venv/bin/bloodhound-ce-python" "\$@"
WRAPPER
    chmod +x "${KON_BIN}/bloodhound-ce.py"
    _ok "bloodhound-ce.py → ${KON_BIN}/bloodhound-ce.py"
}

function install_evil_winrm() {
    gem install evil-winrm >/dev/null 2>&1 && _ok "gem: evil-winrm" || _err "gem: evil-winrm"
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
        git clone -q --depth 1 https://github.com/openwall/john "${JOHN_DIR}" >/dev/null 2>&1 || { _err "git: john"; return 1; }
        ( cd "${JOHN_DIR}/src" || { _err "cd: john/src"; return 1; }
          ./configure --disable-native-tests >/dev/null 2>&1 || { _err "john: configure failed"; exit 1; }
          make -sj"$(nproc)" >/dev/null 2>&1 || { _err "john: build failed"; exit 1; }
        ) || return 1
    fi
    cat > "${KON_BIN}/john" << WRAPPER
#!/usr/bin/env bash
cd "${RUN_DIR}" && exec ./john "\$@"
WRAPPER
    chmod +x "${KON_BIN}/john"
    local f base
    for f in "${RUN_DIR}"/*2john* "${RUN_DIR}/unshadow" "${RUN_DIR}/unafs" "${RUN_DIR}/unique"; do
        [[ -f "$f" ]] || continue
        base="$(basename "$f")"
        if [[ "$f" == *.py ]]; then
            cat > "${KON_BIN}/${base%.py}" << WRAPPER
#!/usr/bin/env bash
cd "${RUN_DIR}" && exec python3 "$f" "\$@"
WRAPPER
            chmod +x "${KON_BIN}/${base%.py}"
        elif [[ -x "$f" ]]; then
            cat > "${KON_BIN}/$base" << WRAPPER
#!/usr/bin/env bash
cd "${RUN_DIR}" && exec "$f" "\$@"
WRAPPER
            chmod +x "${KON_BIN}/$base"
        fi
    done
    if "${KON_BIN}/john" --help >/dev/null 2>&1; then
        _ok "john: installed jumbo (latest from source) → ${KON_BIN}/john"
    else
        _err "john: build finished but binary not found in ${KON_BIN}"
    fi
}

function install_impacket()        { install_pip impacket; }
function install_certipy()         { install_pip certipy-ad; }
function install_bloodyad()        { install_pip bloodyAD; }
function install_ldapdomaindump()  { install_pip ldapdomaindump; }
function install_ldeep()           { install_pip ldeep; }
function install_mitm6()           { install_pip mitm6; }
function install_adidnsdump()      { install_pip adidnsdump; }
function install_coercer()         { install_pip coercer; }
function install_donpapi()         { install_pip donpapi; }
function install_smbmap()          { install_pip smbmap; }
function install_pypykatz()        { install_pip pypykatz; }
function install_goldencopy()      { install_pip goldencopy; }
function install_gpp_decrypt()     { install_pip gpp-decrypt; }

function install_aclpwn() {
    _info "skip: aclpwn (abandoned, py2-only wheel on PyPI, not installable on python3)"
}

function install_sprayhound() {
    install_pip sprayhound || _info "note: sprayhound may have broken/frozen deps on current pip/python"
}

function install_roadrecon() {
    install_pip roadrecon || _info "note: roadrecon may have broken/frozen deps on current pip/python"
}

function install_netexec() {
    local NXC_DIR="${KON_SRC}/NetExec"
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
        _err "pipx: netexec (ver output de pipx arriba)"
        return 1
    fi
    local pipx_bin="${HOME}/.local/bin/nxc"
    if [[ -f "${pipx_bin}" ]]; then
        ln -sf "${pipx_bin}" "${KON_BIN}/nxc"
        _ok "bin: nxc → ${KON_BIN}/nxc"
    else
        _err "netexec: nxc binary not found at ${pipx_bin} after pipx install"
        return 1
    fi
}

function install_manspider() {
    install_git manspider https://github.com/blacklanternsecurity/MANSPIDER
    pip3 install -q --no-cache-dir --break-system-packages "${KON_SRC}/manspider" >/dev/null 2>&1 && _ok "pip: manspider" || _err "pip: manspider"
}

function install_enum4linux_ng() {
    install_git enum4linux-ng https://github.com/cddmp/enum4linux-ng
    pip3 install -q --no-cache-dir --break-system-packages "${KON_SRC}/enum4linux-ng" >/dev/null 2>&1 && _ok "pip: enum4linux-ng" || _err "pip: enum4linux-ng"
    link_bin enum4linux-ng "${KON_SRC}/enum4linux-ng/enum4linux-ng.py"
}

function install_pcredz() {
    local PCREDZ_DIR="${KON_SRC}/PCredz"
    install_apt libpcap-dev
    if [[ -d "${PCREDZ_DIR}" ]]; then
        _info "skip: PCredz (already exists)"
    else
        git clone -q --depth 1 https://github.com/lgandx/PCredz "${PCREDZ_DIR}" >/dev/null 2>&1 || { _err "git: PCredz"; return 1; }
        python3 -m venv --system-site-packages "${PCREDZ_DIR}/venv" >/dev/null 2>&1
        "${PCREDZ_DIR}/venv/bin/pip3" install -q --no-cache-dir Cython >/dev/null 2>&1 && _ok "pip: Cython [PCredz venv]" || _err "pip: Cython [PCredz venv]"
        "${PCREDZ_DIR}/venv/bin/pip3" install -q --no-cache-dir pcapy-ng >/dev/null 2>&1 && _ok "pip: pcapy-ng [PCredz venv]" || _err "pip: pcapy-ng [PCredz venv]"
    fi
    cat > "${KON_BIN}/Pcredz" << WRAPPER
#!/usr/bin/env bash
cd "${PCREDZ_DIR}" && exec ./venv/bin/python3 ./Pcredz "\$@"
WRAPPER
    chmod +x "${KON_BIN}/Pcredz"
    if "${KON_BIN}/Pcredz" -h >/dev/null 2>&1; then
        _ok "Pcredz → ${KON_BIN}/Pcredz"
    else
        _err "Pcredz: wrapper created but tool failed to run (check venv deps)"
    fi
}

function install_enum4linux() {
    install_git enum4linux https://github.com/CiscoCXSecurity/enum4linux
    link_bin enum4linux "${KON_SRC}/enum4linux/enum4linux.pl"
}

function install_powerview_py() {
    pip3 install -q --no-cache-dir --break-system-packages git+https://github.com/aniqfakhrul/powerview.py >/dev/null 2>&1 && _ok "pip: powerview.py" || _err "pip: powerview.py"
}

function install_pywerview() {
    install_git pywerview https://github.com/the-useless-one/pywerview
    pip3 install -q --no-cache-dir --break-system-packages "${KON_SRC}/pywerview" >/dev/null 2>&1 && _ok "git+pip: pywerview" || _err "pip: pywerview"
}

function install_responder() {
    local RESP_DIR="${KON_SRC}/Responder"
    install_apt gcc-mingw-w64-x86-64
    if [[ -d "${RESP_DIR}" ]]; then
        _info "skip: Responder (already exists)"
    else
        git clone -q --depth 1 https://github.com/lgandx/Responder "${RESP_DIR}" >/dev/null 2>&1 || { _err "git: Responder"; return 1; }
        python3 -m venv --system-site-packages "${RESP_DIR}/venv" >/dev/null 2>&1
        "${RESP_DIR}/venv/bin/pip3" install -q --no-cache-dir -r "${RESP_DIR}/requirements.txt" >/dev/null 2>&1 && _ok "pip: Responder requirements [venv]" || _err "pip: Responder requirements [venv]"
        "${RESP_DIR}/venv/bin/pip3" install -q --no-cache-dir pycryptodomex six >/dev/null 2>&1 && _ok "pip: pycryptodomex six [Responder venv]" || _err "pip: pycryptodomex six [Responder venv]"
        sed -i 's/ Random/ 1122334455667788/g' "${RESP_DIR}/Responder.conf"
        sed -i "s/files\/AccessDenied.html/\/${RESP_DIR//\//\\/}\/files\/AccessDenied.html/g" "${RESP_DIR}/Responder.conf"
        sed -i "s/files\/BindShell.exe/\/${RESP_DIR//\//\\/}\/files\/BindShell.exe/g" "${RESP_DIR}/Responder.conf"
        sed -i "s/certs\/responder.crt/\/${RESP_DIR//\//\\/}\/certs\/responder.crt/g" "${RESP_DIR}/Responder.conf"
        sed -i "s/certs\/responder.key/\/${RESP_DIR//\//\\/}\/certs\/responder.key/g" "${RESP_DIR}/Responder.conf"
        x86_64-w64-mingw32-gcc "${RESP_DIR}/tools/MultiRelay/bin/Runas.c" -o "${RESP_DIR}/tools/MultiRelay/bin/Runas.exe" -municode -lwtsapi32 -luserenv >/dev/null 2>&1 && _ok "mingw: Runas.exe" || _err "mingw: Runas.exe"
        x86_64-w64-mingw32-gcc "${RESP_DIR}/tools/MultiRelay/bin/Syssvc.c" -o "${RESP_DIR}/tools/MultiRelay/bin/Syssvc.exe" -municode >/dev/null 2>&1 && _ok "mingw: Syssvc.exe" || _err "mingw: Syssvc.exe"
        "${RESP_DIR}/certs/gen-self-signed-cert.sh" >/dev/null 2>&1 && _ok "Responder: self-signed cert" || _err "Responder: self-signed cert"
    fi
    cat > "${KON_BIN}/Responder.py" << WRAPPER
#!/usr/bin/env bash
cd "${RESP_DIR}" && exec ./venv/bin/python3 ./Responder.py "\$@"
WRAPPER
    chmod +x "${KON_BIN}/Responder.py"
    _ok "Responder.py → ${KON_BIN}/Responder.py"
}

function install_petitpotam() {
    local PP_DIR="${KON_SRC}/PetitPotam"
    if [[ -d "${PP_DIR}" ]]; then
        _info "skip: PetitPotam (already exists)"
    else
        git clone -q --depth 1 https://github.com/topotam/PetitPotam "${PP_DIR}" >/dev/null 2>&1 || { _err "git: PetitPotam"; return 1; }
        python3 -m venv --system-site-packages "${PP_DIR}/venv" >/dev/null 2>&1
        "${PP_DIR}/venv/bin/pip3" install -q --no-cache-dir impacket >/dev/null 2>&1 && _ok "pip: impacket [PetitPotam venv]" || _err "pip: impacket [PetitPotam venv]"
    fi
    cat > "${KON_BIN}/PetitPotam.py" << WRAPPER
#!/usr/bin/env bash
cd "${PP_DIR}" && exec ./venv/bin/python3 ./PetitPotam.py "\$@"
WRAPPER
    chmod +x "${KON_BIN}/PetitPotam.py"
    _ok "PetitPotam.py → ${KON_BIN}/PetitPotam.py"
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
    local NOPAC_DIR="${KON_SRC}/noPac"
    if [[ -d "${NOPAC_DIR}" ]]; then
        _info "skip: noPac (already exists)"
    else
        git clone -q --depth 1 https://github.com/Ridter/noPac "${NOPAC_DIR}" >/dev/null 2>&1 || { _err "git: noPac"; return 1; }
        python3 -m venv --system-site-packages "${NOPAC_DIR}/venv" >/dev/null 2>&1
        "${NOPAC_DIR}/venv/bin/pip3" install -q --no-cache-dir -r "${NOPAC_DIR}/requirements.txt" >/dev/null 2>&1 && _ok "pip: noPac requirements [venv]" || _err "pip: noPac requirements [venv]"
    fi
    cat > "${KON_BIN}/noPac.py" << WRAPPER
#!/usr/bin/env bash
cd "${NOPAC_DIR}" && exec ./venv/bin/python3 ./noPac.py "\$@"
WRAPPER
    chmod +x "${KON_BIN}/noPac.py"
    cat > "${KON_BIN}/noPac-scanner.py" << WRAPPER
#!/usr/bin/env bash
cd "${NOPAC_DIR}" && exec ./venv/bin/python3 ./scanner.py "\$@"
WRAPPER
    chmod +x "${KON_BIN}/noPac-scanner.py"
    _ok "noPac.py → ${KON_BIN}/noPac.py"
    _ok "noPac-scanner.py → ${KON_BIN}/noPac-scanner.py"
}

function install_windapsearch() {
    local WDS_DIR="${KON_SRC}/windapsearch"
    install_apt libldap2-dev
    install_apt libsasl2-dev
    if [[ -L "${KON_BIN}/windapsearch.py" ]]; then
        rm -f "${KON_BIN}/windapsearch.py"
    fi
    if [[ -f "${WDS_DIR}/windapsearch.py" ]] && ! head -1 "${WDS_DIR}/windapsearch.py" | grep -q '^#!/usr/bin/env python'; then
        _info "windapsearch: repo source corrupted by previous run, re-cloning"
        rm -rf "${WDS_DIR}"
    fi
    if [[ -d "${WDS_DIR}" ]]; then
        _info "skip: windapsearch (already exists)"
    else
        git clone -q --depth 1 https://github.com/ropnop/windapsearch "${WDS_DIR}" >/dev/null 2>&1 || { _err "git: windapsearch"; return 1; }
        python3 -m venv --system-site-packages "${WDS_DIR}/venv" >/dev/null 2>&1
        if [[ -f "${WDS_DIR}/requirements.txt" ]]; then
            "${WDS_DIR}/venv/bin/pip3" install -q --no-cache-dir -r "${WDS_DIR}/requirements.txt" >/dev/null 2>&1 && _ok "pip: windapsearch requirements.txt [venv]" || _err "pip: windapsearch requirements.txt [venv]"
        else
            "${WDS_DIR}/venv/bin/pip3" install -q --no-cache-dir python-ldap >/dev/null 2>&1 && _ok "pip: python-ldap [venv]" || _err "pip: python-ldap [venv]"
        fi
    fi
    rm -f "${KON_BIN}/windapsearch.py"
    cat > "${KON_BIN}/windapsearch.py" << WRAPPER
#!/usr/bin/env bash
cd "${WDS_DIR}" && exec ./venv/bin/python3 ./windapsearch.py "\$@"
WRAPPER
    chmod +x "${KON_BIN}/windapsearch.py"
    if "${KON_BIN}/windapsearch.py" -h >/tmp/windapsearch_check.log 2>&1; then
        _ok "windapsearch.py → ${KON_BIN}/windapsearch.py"
    else
        _err "windapsearch.py: wrapper created but tool failed to run"
        _info "output:"
        sed 's/^/         /' /tmp/windapsearch_check.log
    fi
    rm -f /tmp/windapsearch_check.log
}

function install_targetedkerberoast() {
    install_git targetedKerberoast https://github.com/ShutdownRepo/targetedKerberoast
    link_bin targetedKerberoast.py "${KON_SRC}/targetedKerberoast/targetedKerberoast.py"
}

function install_krbrelayx() {
    local KRB_DIR="${KON_SRC}/krbrelayx"
    if [[ -d "${KRB_DIR}" ]]; then
        _info "skip: krbrelayx (already exists)"
    else
        git clone -q --depth 1 https://github.com/dirkjanm/krbrelayx "${KRB_DIR}" >/dev/null 2>&1 || { _err "git: krbrelayx"; return 1; }
        python3 -m venv --system-site-packages "${KRB_DIR}/venv" >/dev/null 2>&1
        "${KRB_DIR}/venv/bin/pip3" install -q --no-cache-dir dnspython ldap3 impacket dsinternals >/dev/null 2>&1 && _ok "pip: krbrelayx deps [venv]" || _err "pip: krbrelayx deps [venv]"
    fi
    local script
    for script in krbrelayx dnstool printerbug addspn; do
        cat > "${KON_BIN}/${script}.py" << WRAPPER
#!/usr/bin/env bash
cd "${KRB_DIR}" && exec ./venv/bin/python3 ./${script}.py "\$@"
WRAPPER
        chmod +x "${KON_BIN}/${script}.py"
        _ok "${script}.py → ${KON_BIN}/${script}.py"
    done
}

function install_pkinittools() {
    local PKT_DIR="${KON_SRC}/PKINITtools"
    if [[ -d "${PKT_DIR}" ]]; then
        _info "skip: PKINITtools repo (already exists)"
    else
        git clone -q --depth 1 https://github.com/dirkjanm/PKINITtools "${PKT_DIR}" >/dev/null 2>&1 || { _err "git: PKINITtools"; return 1; }
    fi
    if [[ ! -d "${PKT_DIR}/venv" ]]; then
        python3 -m venv --system-site-packages "${PKT_DIR}/venv" >/dev/null 2>&1
    fi
    "${PKT_DIR}/venv/bin/pip3" install -q --no-cache-dir -r "${PKT_DIR}/requirements.txt" >/dev/null 2>&1 && _ok "pip: PKINITtools requirements [venv]" || _err "pip: PKINITtools requirements [venv]"
    "${PKT_DIR}/venv/bin/pip3" install -q --no-cache-dir --force-reinstall --no-deps "git+https://github.com/wbond/oscrypto.git" >/dev/null 2>&1 && _ok "pip: oscrypto (fix libcrypto, from git) [venv]" || _err "pip: oscrypto (fix libcrypto, from git) [venv]"
    rm -f "${KON_BIN}/gettgtpkinit.py" "${KON_BIN}/getnthash.py"
    cat > "${KON_BIN}/gettgtpkinit.py" << WRAPPER
#!/usr/bin/env bash
cd "${PKT_DIR}" && exec ./venv/bin/python3 ./gettgtpkinit.py "\$@"
WRAPPER
    chmod +x "${KON_BIN}/gettgtpkinit.py"
    cat > "${KON_BIN}/getnthash.py" << WRAPPER
#!/usr/bin/env bash
cd "${PKT_DIR}" && exec ./venv/bin/python3 ./getnthash.py "\$@"
WRAPPER
    chmod +x "${KON_BIN}/getnthash.py"
    _ok "gettgtpkinit.py → ${KON_BIN}/gettgtpkinit.py"
    _ok "getnthash.py → ${KON_BIN}/getnthash.py"
    local test_log="/tmp/pkinittools_check.log"
    if "${KON_BIN}/gettgtpkinit.py" -h >"${test_log}" 2>&1; then
        _ok "self-test: gettgtpkinit.py -h → OK (oscrypto import funciona)"
    else
        if grep -q "LibraryNotFoundError" "${test_log}"; then
            _err "self-test: gettgtpkinit.py sigue roto (oscrypto/libcrypto)"
        else
            _err "self-test: gettgtpkinit.py falló por otro motivo"
        fi
        _info "output:"
        sed 's/^/         /' "${test_log}"
    fi
    rm -f "${test_log}"
}

function install_pywhisker() {
    install_git pywhisker https://github.com/ShutdownRepo/pywhisker
    pip3 install -q --no-cache-dir --break-system-packages "${KON_SRC}/pywhisker" >/dev/null 2>&1 && _ok "pip: pywhisker" || _err "pip: pywhisker"
    if [[ -f /usr/local/bin/pywhisker ]]; then
        link_bin pywhisker /usr/local/bin/pywhisker
    else
        cat > "${KON_BIN}/pywhisker" << WRAPPER
#!/usr/bin/env bash
exec python3 -m pywhisker.pywhisker "\$@"
WRAPPER
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

function p_ad() {
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
    install_windapsearch
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
