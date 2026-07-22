#!/usr/bin/env bash
# Author: z1rov
source /z1/install/common.sh
mkdir -p /opt/tools

function install_linpeas() {
    forja_get linpeas "https://github.com/peass-ng/PEASS-ng/releases/latest/download/linpeas.sh" linpeas.sh
}

function install_linux_exploit_suggester() {
    forja_get linux-exploit-suggester "https://raw.githubusercontent.com/The-Z-Labs/linux-exploit-suggester/master/linux-exploit-suggester.sh" "linux-exploit-suggester.sh"
}

function install_linenum() {
    forja_get linenum "https://raw.githubusercontent.com/rebootuser/LinEnum/master/LinEnum.sh" LinEnum.sh
}

function install_pspy() {
    local forja_dir="${Z1_FORJA}/pspy"
    mkdir -p "${forja_dir}"
    local base_url="https://github.com/DominicBreuker/pspy/releases/latest/download"
    curl -sL -o "${forja_dir}/pspy64" "${base_url}/pspy64" && chmod +x "${forja_dir}/pspy64" || _err "forja: pspy64"
    curl -sL -o "${forja_dir}/pspy32" "${base_url}/pspy32" && chmod +x "${forja_dir}/pspy32" || _err "forja: pspy32"
    _ok "forja: pspy"
}

function install_lse() {
    forja_get lse "https://raw.githubusercontent.com/diego-treitos/linux-smart-enumeration/master/lse.sh" lse.sh
}

function install_winpeas() {
    forja_get winpeas "https://github.com/peass-ng/PEASS-ng/releases/latest/download/winPEASx64.exe" winPEASx64.exe
    forja_get winpeas "https://github.com/peass-ng/PEASS-ng/releases/latest/download/winPEASx86.exe" winPEASx86.exe
    forja_get winpeas "https://github.com/peass-ng/PEASS-ng/releases/latest/download/winPEASany.exe" winPEASany.exe
}

function install_privesc_check() {
    forja_get privesc-check "https://github.com/itm4n/PrivescCheck/releases/latest/download/PrivescCheck.ps1" "PrivescCheck.ps1"
}

function install_powerup() {
    forja_get powersploit "https://raw.githubusercontent.com/PowerShellMafia/PowerSploit/master/Privesc/PowerUp.ps1" PowerUp.ps1
}

function install_watson() {
    forja_get watson "https://github.com/Flangvik/SharpCollection/raw/master/NetFramework_4.7_x64/Watson.exe" "Watson.exe"
}

function install_sharpbypassuac() {
    forja_get sharpbypassuac "https://github.com/Flangvik/SharpCollection/raw/master/NetFramework_4.7_x64/SharpBypassUAC.exe" "SharpBypassUAC.exe"
}

function install_rubeus() {
    forja_get rubeus "https://github.com/Flangvik/SharpCollection/raw/master/NetFramework_4.7_x64/Rubeus.exe" "Rubeus.exe"
}

function install_seatbelt() {
    forja_get seatbelt "https://github.com/Flangvik/SharpCollection/raw/master/NetFramework_4.7_x64/Seatbelt.exe" "Seatbelt.exe"
}

function install_sharpup() {
    forja_get sharpup "https://github.com/Flangvik/SharpCollection/raw/master/NetFramework_4.7_x64/SharpUp.exe" "SharpUp.exe"
}

function install_sharpsqlpwn() {
    forja_get sharpsqlpwn "https://github.com/Flangvik/SharpCollection/raw/master/NetFramework_4.7_x64/SharpSQLPwn.exe" "SharpSQLPwn.exe"
}

function install_sharpview() {
    forja_get sharpview "https://github.com/Flangvik/SharpCollection/raw/master/NetFramework_4.7_x64/SharpView.exe" "SharpView.exe"
}

function install_sharpshooter() {
    local dest="${Z1_FORJA}/sharpshooter"
    mkdir -p "${Z1_FORJA}"
    if [[ -d "${dest}" ]]; then
        _info "SharpShooter repo already exists, removing before re-cloning"
        rm -rf "${dest}"
    fi
    local log rc
    log=$(git clone --depth 1 https://github.com/mdsecactivebreach/SharpShooter "${dest}" 2>&1)
    rc=$?
    if [[ ${rc} -eq 0 ]]; then
        _ok "git: SharpShooter â†’ ${dest}"
    else
        _err "git: SharpShooter (rc=${rc})"
        return 1
    fi
    if [[ -f "${dest}/requirements.txt" ]]; then
        python3 -m pip install -q --no-cache-dir --break-system-packages -r "${dest}/requirements.txt" 2>/dev/null || true
    fi
    if [[ -f "${dest}/SharpShooter.py" ]]; then
        printf '#!/usr/bin/env bash\ncd "%s" && exec python3 SharpShooter.py "$@"\n' "${dest}" > "${Z1_BIN}/sharpshooter"
        chmod +x "${Z1_BIN}/sharpshooter"
        _ok "git: SharpShooter â†’ ${Z1_BIN}/sharpshooter (wrapper python3)"
    else
        _err "git: SharpShooter (SharpShooter.py not found)"
    fi
}

function install_sharpapplocker() {
    forja_get sharpapplocker "https://github.com/Flangvik/SharpCollection/raw/master/NetFramework_4.7_x64/SharpAppLocker.exe" "SharpAppLocker.exe"
}

function install_krbrelayup() {
    forja_get krbrelayup "https://github.com/Flangvik/SharpCollection/raw/master/NetFramework_4.7_x64/KrbRelayUp.exe" "KrbRelayUp.exe"
}

function install_certify() {
    forja_get certify "https://github.com/Flangvik/SharpCollection/raw/master/NetFramework_4.7_x64/Certify.exe" "Certify.exe"
}

function install_forgecert() {
    forja_get forgecert "https://github.com/Flangvik/SharpCollection/raw/master/NetFramework_4.7_x64/ForgeCert.exe" "ForgeCert.exe"
}

function install_whisker() {
    forja_get whisker "https://github.com/Flangvik/SharpCollection/raw/master/NetFramework_4.7_x64/Whisker.exe" "Whisker.exe"
}

function install_passthecert() {
    forja_get passthecert "https://github.com/Flangvik/SharpCollection/raw/master/NetFramework_4.7_x64/PassTheCert.exe" "PassTheCert.exe"
}

function install_standin() {
    forja_get standin "https://github.com/Flangvik/SharpCollection/raw/master/NetFramework_4.7_x64/StandIn.exe" "StandIn.exe"
}

function install_adcspwn() {
    local forja_dir="${Z1_FORJA}/adcspwn"
    mkdir -p "${forja_dir}"
    curl -sL -o "${forja_dir}/ADCSPwn.exe" "https://github.com/bats3c/ADCSPwn/releases/download/v1.0/ADCSPwn.exe" && _ok "forja: ADCSPwn" || _err "forja: ADCSPwn"
}

function install_runascs() {
    forja_get runascs "https://github.com/Flangvik/SharpCollection/raw/master/NetFramework_4.7_x64/RunasCs.exe" "RunasCs.exe"
}

function install_adsearch() {
    forja_get adsearch "https://github.com/Flangvik/SharpCollection/raw/master/NetFramework_4.7_x64/ADSearch.exe" "ADSearch.exe"
}

function install_sharpdpapi() {
    forja_get sharpdpapi "https://github.com/Flangvik/SharpCollection/raw/master/NetFramework_4.7_x64/SharpDPAPI.exe" "SharpDPAPI.exe"
}

function install_adrecon() {
    local forja_dir="${Z1_FORJA}/adrecon"
    mkdir -p "${forja_dir}"
    curl -sL -o "${forja_dir}/ADRecon.ps1" "https://raw.githubusercontent.com/adrecon/ADRecon/master/ADRecon.ps1" && _ok "forja: ADRecon" || _err "forja: ADRecon"
}

function install_lazagne() {
    local forja_dir="${Z1_FORJA}/lazagne"
    mkdir -p "${forja_dir}"
    curl -sL -o "${forja_dir}/lazagne.exe" "https://github.com/AlessandroZ/LaZagne/releases/latest/download/lazagne.exe" && _ok "forja: LaZagne (Windows)" || _err "forja: LaZagne (Windows)"
}

function install_safetykatz() {
    forja_get safetykatz "https://github.com/Flangvik/SharpCollection/raw/master/NetFramework_4.7_x64/SafetyKatz.exe" "SafetyKatz.exe"
}

function install_sqlrecon() {
    local forja_dir="${Z1_FORJA}/sqlrecon"
    mkdir -p "${forja_dir}"
    curl -sL -o "${forja_dir}/SQLRecon.exe" "https://github.com/skahwah/SQLRecon/releases/latest/download/SQLRecon.exe" && _ok "forja: SQLRecon" || _err "forja: SQLRecon"
}

function install_powerupsql() {
    local forja_dir="${Z1_FORJA}/powerupsql"
    mkdir -p "${forja_dir}"
    curl -sL -o "${forja_dir}/PowerUpSQL.ps1" "https://raw.githubusercontent.com/NetSPI/PowerUpSQL/master/PowerUpSQL.ps1" && _ok "forja: PowerUpSQL" || _err "forja: PowerUpSQL"
}

function install_mimikatz() {
    local url
    url=$(curl -s https://api.github.com/repos/gentilkiwi/mimikatz/releases/latest | grep "browser_download_url.*\.zip\"" | grep -o 'https://[^"]*' | head -1)
    if [[ -z "${url}" ]]; then
        _err "mimikatz: no release found"
        return
    fi
    local dest_dir="${Z1_FORJA}/mimikatz"
    mkdir -p "${dest_dir}"
    curl -sL -o "${dest_dir}/mimikatz.zip" "${url}" && unzip -oq "${dest_dir}/mimikatz.zip" -d "${dest_dir}" && rm -f "${dest_dir}/mimikatz.zip" && _ok "forja: mimikatz" || _err "forja: mimikatz"
}

function install_ghostpack() {
    local base="https://github.com/Flangvik/SharpCollection/raw/master/NetFramework_4.7_x64"
    local tool
    for tool in Rubeus Seatbelt SharpUp SharpView; do
        forja_get ghostpack "${base}/${tool}.exe" "${tool}.exe"
    done
}

function install_sharphound() {
    local dest_dir="${Z1_FORJA}/sharphound"
    mkdir -p "${dest_dir}"
    curl -sL -o "${dest_dir}/sharphound.zip" "https://github.com/SpecterOps/SharpHound/releases/latest/download/SharpHound_v2.13.0_windows_x86.zip"
    if [[ -f "${dest_dir}/sharphound.zip" ]] && [[ -s "${dest_dir}/sharphound.zip" ]]; then
        unzip -oq "${dest_dir}/sharphound.zip" -d "${dest_dir}" && rm -f "${dest_dir}/sharphound.zip" && _ok "forja: sharphound" || _err "forja: sharphound (unzip failed)"
    else
        _err "forja: sharphound (download failed)"
    fi
}

function install_ncwin() {
    forja_get netcat-win "https://github.com/int0x33/nc.exe/raw/master/nc64.exe" nc64.exe
    forja_get netcat-win "https://github.com/int0x33/nc.exe/raw/master/nc.exe" nc.exe
}

function install_sharpwmi() {
    forja_get sharpwmi "https://github.com/Flangvik/SharpCollection/raw/master/NetFramework_4.7_x64/SharpWMI.exe" "SharpWMI.exe"
}

function install_sharpcom() {
    forja_get sharpcom "https://github.com/Flangvik/SharpCollection/raw/master/NetFramework_4.7_x64/SharpCOM.exe" "SharpCOM.exe"
}

function install_sharpmove() {
    forja_get sharpmove "https://github.com/Flangvik/SharpCollection/raw/master/NetFramework_4.7_x64/SharpMove.exe" "SharpMove.exe"
}

function install_sharpnamedpipepth() {
    forja_get sharpnamedpipepth "https://github.com/Flangvik/SharpCollection/raw/master/NetFramework_4.7_x64/SharpNamedPipePTH.exe" "SharpNamedPipePTH.exe"
}

function install_inveigh() {
    forja_get inveigh "https://github.com/Flangvik/SharpCollection/raw/master/NetFramework_4.7_x64/Inveigh.exe" "Inveigh.exe"
}

function install_sharpsccm() {
    forja_get sharpsccm "https://github.com/Flangvik/SharpCollection/raw/master/NetFramework_4.7_x64/SharpSCCM.exe" "SharpSCCM.exe"
}

function install_plink() {
    forja_get plink "https://the.earth.li/~sgtatham/putty/latest/w64/plink.exe" "plink.exe"
}

function install_putty() {
    forja_get putty "https://the.earth.li/~sgtatham/putty/latest/w64/putty.exe" "putty.exe"
}

function install_invoke_obfuscation() {
    forja_get invoke-obfuscation "https://raw.githubusercontent.com/danielbohannon/Invoke-Obfuscation/master/Invoke-Obfuscation.psd1" "Invoke-Obfuscation.psd1"
    forja_get invoke-obfuscation "https://raw.githubusercontent.com/danielbohannon/Invoke-Obfuscation/master/Invoke-Obfuscation.psm1" "Invoke-Obfuscation.psm1"
}

function install_chisel_win() {
    local forja_dir="${Z1_FORJA}/chisel"
    mkdir -p "${forja_dir}"
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
        _err "chisel (windows): could not get release version"
        return
    fi
    local base="https://github.com/jpillora/chisel/releases/download/v${version}"
    local tmp
    tmp=$(mktemp -d)
    curl -sL -o "${tmp}/chisel_windows.zip" "${base}/chisel_${version}_windows_amd64.zip"
    mkdir -p "${tmp}/win"
    unzip -q "${tmp}/chisel_windows.zip" -d "${tmp}/win" 2>/dev/null
    local win_bin
    win_bin=$(find "${tmp}/win" -maxdepth 3 -type f -name "*.exe" | head -1)
    if [[ -n "${win_bin}" ]]; then
        cp "${win_bin}" "${forja_dir}/chisel_windows_amd64.exe"
        _ok "forja: chisel (windows/amd64) â†’ ${forja_dir}/chisel_windows_amd64.exe"
    else
        _err "forja: chisel (windows/amd64) â€” exe not found in zip"
    fi
    rm -rf "${tmp}"
}

function install_ligolo_win() {
    local forja_dir="${Z1_FORJA}/ligolo"
    mkdir -p "${forja_dir}"
    install_apt unzip
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
        _err "ligolo-ng (windows): could not get release version"
        return
    fi
    local base="https://github.com/nicocha30/ligolo-ng/releases/download/v${version}"
    local tmp
    tmp=$(mktemp -d)
    curl -sL -o "${tmp}/agent_windows.zip" "${base}/ligolo-ng_agent_${version}_windows_amd64.zip"
    mkdir -p "${tmp}/agent_win"
    unzip -q "${tmp}/agent_windows.zip" -d "${tmp}/agent_win" 2>/dev/null
    local agent_win
    agent_win=$(find "${tmp}/agent_win" -maxdepth 3 -type f -name "*.exe" | head -1)
    if [[ -n "${agent_win}" ]]; then
        cp "${agent_win}" "${forja_dir}/ligolo-agent_windows_amd64.exe"
        _ok "forja: ligolo-agent (windows/amd64) â†’ ${forja_dir}/ligolo-agent_windows_amd64.exe"
    else
        _err "forja: ligolo-agent (windows/amd64) â€” exe not found in zip"
    fi
    rm -rf "${tmp:?}"/*
    curl -sL -o "${tmp}/proxy_windows.zip" "${base}/ligolo-ng_proxy_${version}_windows_amd64.zip"
    mkdir -p "${tmp}/proxy_win"
    unzip -q "${tmp}/proxy_windows.zip" -d "${tmp}/proxy_win" 2>/dev/null
    local proxy_win
    proxy_win=$(find "${tmp}/proxy_win" -maxdepth 3 -type f -name "*.exe" | head -1)
    if [[ -n "${proxy_win}" ]]; then
        cp "${proxy_win}" "${forja_dir}/ligolo-proxy_windows_amd64.exe"
        _ok "forja: ligolo-proxy (windows/amd64) â†’ ${forja_dir}/ligolo-proxy_windows_amd64.exe"
    else
        _err "forja: ligolo-proxy (windows/amd64) â€” exe not found in zip"
    fi
    rm -rf "${tmp}"
}

function p_binaries() {
    install_linpeas
    install_linenum
    install_pspy
    install_lse
    install_linux_exploit_suggester
    install_winpeas
    install_powerup
    install_watson
    install_sharpbypassuac
    install_privesc_check
    install_mimikatz
    install_ghostpack
    install_rubeus
    install_seatbelt
    install_sharpup
    install_sharpsqlpwn
    install_sharpview
    install_sharpshooter
    install_sharpapplocker
    install_krbrelayup
    install_certify
    install_forgecert
    install_whisker
    install_passthecert
    install_standin
    install_adcspwn
    install_runascs
    install_adrecon
    install_adsearch
    install_sharpdpapi
    install_lazagne
    install_safetykatz
    install_sqlrecon
    install_powerupsql
    install_sharphound
    install_ncwin
    install_sharpwmi
    install_sharpcom
    install_sharpmove
    install_sharpnamedpipepth
    install_inveigh
    install_sharpsccm
    install_chisel_win
    install_ligolo_win
    install_plink
    install_putty
    install_invoke_obfuscation
}
