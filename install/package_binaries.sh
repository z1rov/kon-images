#!/usr/bin/env bash
source /kon/install/common.sh
mkdir -p /opt/tools

# Estas herramientas no son repos para clonar (src/) ni paquetes Go (bin/
# directo) — son binarios/scripts sueltos. Todo va a forja/<tool>/ usando
# forja_get cuando es un archivo plano, o curl+unzip/gunzip a mano cuando el
# release viene comprimido (igual que tuvimos que hacer con feroxbuster).
# TODO: Todas las herramientas van a /opt/tools/forja/{tool}/ sin symlinks.

# ── Linux privesc ──────────────────────────────────────────────────────────
function install_linpeas() {
    forja_get linpeas \
        "https://github.com/peass-ng/PEASS-ng/releases/latest/download/linpeas.sh" \
        linpeas.sh
}

function install_linenum() {
    forja_get linenum \
        "https://raw.githubusercontent.com/rebootuser/LinEnum/master/LinEnum.sh" \
        LinEnum.sh
}

function install_pspy() {
    echo -e "  ${CYAN}forja${RESET} pspy"
    local forja_dir="${KON_FORJA}/pspy"
    mkdir -p "${forja_dir}"
    
    # Descargar versiones 32bit y 64bit
    local base_url="https://github.com/DominicBreuker/pspy/releases/latest/download"
    
    # 64bit
    curl -sL -o "${forja_dir}/pspy64" "${base_url}/pspy64" \
        && chmod +x "${forja_dir}/pspy64" \
        || _err "forja: pspy64"
    
    # 32bit
    curl -sL -o "${forja_dir}/pspy32" "${base_url}/pspy32" \
        && chmod +x "${forja_dir}/pspy32" \
        || _err "forja: pspy32"
    
    _ok "forja: pspy"
}

function install_lse() {
    forja_get lse \
        "https://raw.githubusercontent.com/diego-treitos/linux-smart-enumeration/master/lse.sh" \
        lse.sh
}

# ── Windows privesc / post-explotación ──────────────────────────────────────
function install_winpeas() {
    forja_get winpeas \
        "https://github.com/peass-ng/PEASS-ng/releases/latest/download/winPEASx64.exe" \
        winPEASx64.exe
    forja_get winpeas \
        "https://github.com/peass-ng/PEASS-ng/releases/latest/download/winPEASx86.exe" \
        winPEASx86.exe
    forja_get winpeas \
        "https://github.com/peass-ng/PEASS-ng/releases/latest/download/winPEASany.exe" \
        winPEASany.exe
}

function install_powerup() {
    forja_get powersploit \
        "https://raw.githubusercontent.com/PowerShellMafia/PowerSploit/master/Privesc/PowerUp.ps1" \
        PowerUp.ps1
}

# Watson: enumera vulnerabilidades de privesc de Windows por hotfixes
# faltantes (KBs). Complementa a winPEAS/PowerUp con un enfoque distinto
# (parches conocidos en vez de misconfigs). Relevante para PEN-300/OSEP.
function install_watson() {
    forja_get watson \
        "https://github.com/Flangvik/SharpCollection/raw/master/NetFramework_4.7_x64/Watson.exe" \
        "Watson.exe"
}

# SharpBypassUAC: colección de técnicas de bypass de UAC en C#. Módulo de
# privesc avanzado en Windows cubierto en PEN-300/OSEP.
function install_sharpbypassuac() {
    forja_get sharpbypassuac \
        "https://github.com/Flangvik/SharpCollection/raw/master/NetFramework_4.7_x64/SharpBypassUAC.exe" \
        "SharpBypassUAC.exe"
}

# ── Herramientas de AD / Kerberos ──────────────────────────────────────────
#
# NOTA GENERAL (revisión 2026-06-22):
# GhostPack (Certify, Rubeus, Seatbelt, SharpUp, SharpView, SafetyKatz,
# Whisker, ForgeCert, RunasCs, KrbRelayUp, ADCSPwn, SharpSQLPwn...) dejó de
# publicar binarios compilados en sus propios repos / en el mirror clásico
# r3motecontrol/Ghostpack-CompiledBinaries (varias URLs ahí están rotas o
# nunca existieron con esos nombres). La fuente que SÍ mantiene todos estos
# binarios compilados, actualizados y verificados es Flangvik/SharpCollection
# (carpeta NetFramework_4.7_x64). La usamos como fuente única para ese grupo
# de herramientas en vez de mezclar mirrors rotos.
#
# Todas las URLs de SharpCollection en este archivo usan el patrón
# "raw/master/<carpeta>/<tool>.exe" de forma consistente. Evitar el patrón
# "raw/refs/heads/master/..." (funciona vía redirect pero es más frágil e
# inconsistente con el resto del archivo).

function install_rubeus() {
    forja_get rubeus \
        "https://github.com/Flangvik/SharpCollection/raw/master/NetFramework_4.7_x64/Rubeus.exe" \
        "Rubeus.exe"
}

function install_seatbelt() {
    forja_get seatbelt \
        "https://github.com/Flangvik/SharpCollection/raw/master/NetFramework_4.7_x64/Seatbelt.exe" \
        "Seatbelt.exe"
}

function install_sharpup() {
    forja_get sharpup \
        "https://github.com/Flangvik/SharpCollection/raw/master/NetFramework_4.7_x64/SharpUp.exe" \
        "SharpUp.exe"
}

# Antes "sharpsqlninja" / klezVirus/SharpSQL — ese repo no existe. La
# herramienta real de auditoría MSSQL compilada y mantenida en SharpCollection
# se llama SharpSQLPwn.
function install_sharpsqlpwn() {
    forja_get sharpsqlpwn \
        "https://github.com/Flangvik/SharpCollection/raw/master/NetFramework_4.7_x64/SharpSQLPwn.exe" \
        "SharpSQLPwn.exe"
}

function install_sharpview() {
    forja_get sharpview \
        "https://github.com/Flangvik/SharpCollection/raw/master/NetFramework_4.7_x64/SharpView.exe" \
        "SharpView.exe"
}

# SharpShooter NO es un binario .exe — es un framework en Python
# (SharpShooter.py + módulos/templates en CSharpShooter/). Antes se intentaba
# descargar "SharpShooter.exe" desde releases/latest/download, lo cual nunca
# existió (404 permanente). Se instala clonando el repo completo.
function install_sharpshooter() {
    colorecho "Installing SharpShooter"

    local dest="${KON_FORJA}/sharpshooter"
    mkdir -p "${KON_FORJA}"

    if [[ -d "${dest}" ]]; then
        _info "SharpShooter repo ya existe, eliminando antes de re-clonar"
        rm -rf "${dest}"
    fi

    local log rc
    log=$(git clone --depth 1 \
        https://github.com/mdsecactivebreach/SharpShooter "${dest}" 2>&1)
    rc=$?
    if [[ ${rc} -eq 0 ]]; then
        _ok "git: SharpShooter → ${dest}"
    else
        _err "git: SharpShooter (rc=${rc})"
        echo "----- output -----"; echo "${log}" | tail -20; echo "-------------------"
        return 1
    fi

    if [[ -f "${dest}/requirements.txt" ]]; then
        python3 -m pip install -q --no-cache-dir --break-system-packages \
            -r "${dest}/requirements.txt" 2>/dev/null || true
    fi

    if [[ -f "${dest}/SharpShooter.py" ]]; then
        printf '#!/usr/bin/env bash\ncd "%s" && exec python3 SharpShooter.py "$@"\n' \
            "${dest}" > "${KON_BIN}/sharpshooter"
        chmod +x "${KON_BIN}/sharpshooter"
        _ok "git: SharpShooter → ${KON_BIN}/sharpshooter (wrapper python3)"
    else
        _err "git: SharpShooter (SharpShooter.py not found)"
    fi
}

# SharpAppLocker: enumera políticas de AppLocker aplicadas en el equipo.
# Complementa directamente a SharpShooter (--awl wmic/regsvr32) para el
# módulo de Application Whitelisting bypass de PEN-300/OSEP.
function install_sharpapplocker() {
    forja_get sharpapplocker \
        "https://github.com/Flangvik/SharpCollection/raw/master/NetFramework_4.7_x64/SharpAppLocker.exe" \
        "SharpAppLocker.exe"
}

# ── Herramientas AD específicas ─────────────────────────────────────────────

# Antes apuntaba a "GhostPack/KrbRelayUp", repo que no existe. El proyecto
# real es Dec0ne/KrbRelayUp, que tampoco publica binarios en sus propios
# releases (no usa GitHub Releases con assets) — se toma de SharpCollection.
function install_krbrelayup() {
    forja_get krbrelayup \
        "https://github.com/Flangvik/SharpCollection/raw/master/NetFramework_4.7_x64/KrbRelayUp.exe" \
        "KrbRelayUp.exe"
}

function install_certify() {
    forja_get certify \
        "https://github.com/Flangvik/SharpCollection/raw/master/NetFramework_4.7_x64/Certify.exe" \
        "Certify.exe"
}

function install_forgecert() {
    forja_get forgecert \
        "https://github.com/Flangvik/SharpCollection/raw/master/NetFramework_4.7_x64/ForgeCert.exe" \
        "ForgeCert.exe"
}

function install_whisker() {
    forja_get whisker \
        "https://github.com/Flangvik/SharpCollection/raw/master/NetFramework_4.7_x64/Whisker.exe" \
        "Whisker.exe"
}

# PassTheCert: autentica contra LDAP/S usando un certificado (en vez de un
# Kerberos ticket). Pareja natural de Certify/ForgeCert/Whisker para el
# módulo de abuso de AD CS / shadow credentials de OSEP.
function install_passthecert() {
    forja_get passthecert \
        "https://github.com/Flangvik/SharpCollection/raw/master/NetFramework_4.7_x64/PassTheCert.exe" \
        "PassTheCert.exe"
}

# StandIn: enumeración AD multipropósito (gMSA, GPO abuse, computer objects,
# etc). Cubre varios checks puntuales del temario de AD del PEN-300.
function install_standin() {
    forja_get standin \
        "https://github.com/Flangvik/SharpCollection/raw/master/NetFramework_4.7_x64/StandIn.exe" \
        "StandIn.exe"
}

# Antes apuntaba a "Leo4j/ADCSPwn", repo que no existe. El autor original es
# bats3c (MDSec ActiveBreach); SharpCollection no lo trae, así que se usa
# directamente el release v1.0 del repo original.
function install_adcspwn() {
    echo -e "  ${CYAN}forja${RESET} ADCSPwn"
    local forja_dir="${KON_FORJA}/adcspwn"
    mkdir -p "${forja_dir}"

    local url="https://github.com/bats3c/ADCSPwn/releases/download/v1.0/ADCSPwn.exe"
    curl -sL -o "${forja_dir}/ADCSPwn.exe" "${url}" \
        && _ok "forja: ADCSPwn" \
        || _err "forja: ADCSPwn"
}

function install_runascs() {
    forja_get runascs \
        "https://github.com/Flangvik/SharpCollection/raw/master/NetFramework_4.7_x64/RunasCs.exe" \
        "RunasCs.exe"
}

# ADSearch: wrapper de búsquedas LDAP crudas en C# (alternativa ligera a
# SharpView/PowerView para queries puntuales). Antes usaba el patrón de URL
# "raw/refs/heads/master/..." — funcionaba por redirect pero es inconsistente
# con el resto del archivo; normalizado al patrón estándar "raw/master/...".
function install_adsearch() {
    forja_get adsearch \
        "https://github.com/Flangvik/SharpCollection/raw/master/NetFramework_4.7_x64/ADSearch.exe" \
        "ADSearch.exe"
}

# SharpDPAPI: port en C# de las funciones DPAPI de Mimikatz (decripta
# credential blobs, vault, masterkeys, etc). La función ya existía en el
# archivo pero NO estaba siendo llamada desde package_binaries(), por lo que
# nunca se ejecutaba — ese era el motivo real por el que "no se instalaba".
function install_sharpdpapi() {
    forja_get sharpdpapi \
        "https://github.com/Flangvik/SharpCollection/raw/master/NetFramework_4.7_x64/SharpDPAPI.exe" \
        "SharpDPAPI.exe"
}

# NOTA: install_winrm() fue eliminada. El script Privesc/winRM.ps1 del repo
# Hackplayers/PsCabesha-tools ya no existe en el HEAD del repo (fue borrado/
# renombrado en algún commit posterior); no se encontró una fuente
# equivalente confiable para reemplazarlo. Si se necesita en el futuro,
# buscar en el historial de commits del repo o un fork que lo conserve.

function install_adrecon() {
    echo -e "  ${CYAN}forja${RESET} ADRecon"
    local forja_dir="${KON_FORJA}/adrecon"
    mkdir -p "${forja_dir}"
    
    # ADRecon es un script de PowerShell
    local url="https://raw.githubusercontent.com/adrecon/ADRecon/master/ADRecon.ps1"
    curl -sL -o "${forja_dir}/ADRecon.ps1" "${url}" \
        && _ok "forja: ADRecon" \
        || _err "forja: ADRecon"
}

# La v2.4.7 de LaZagne sólo publica un único asset (lazagne.exe, Windows
# x64). Ya no hay binario Linux ni build x86 separado en el release; antes
# se intentaba descargar "lazagne" (linux) y "LaZagne-x86.exe", que dan 404.
function install_lazagne() {
    echo -e "  ${CYAN}forja${RESET} LaZagne"
    local forja_dir="${KON_FORJA}/lazagne"
    mkdir -p "${forja_dir}"

    local url="https://github.com/AlessandroZ/LaZagne/releases/latest/download/lazagne.exe"
    curl -sL -o "${forja_dir}/lazagne.exe" "${url}" \
        && _ok "forja: LaZagne (Windows)" \
        || _err "forja: LaZagne (Windows)"
}

function install_safetykatz() {
    forja_get safetykatz \
        "https://github.com/Flangvik/SharpCollection/raw/master/NetFramework_4.7_x64/SafetyKatz.exe" \
        "SafetyKatz.exe"
}

function install_sqlrecon() {
    echo -e "  ${CYAN}forja${RESET} SQLRecon"
    local forja_dir="${KON_FORJA}/sqlrecon"
    mkdir -p "${forja_dir}"
    
    local url="https://github.com/skahwah/SQLRecon/releases/latest/download/SQLRecon.exe"
    curl -sL -o "${forja_dir}/SQLRecon.exe" "${url}" \
        && _ok "forja: SQLRecon" \
        || _err "forja: SQLRecon"
}

function install_powerupsql() {
    echo -e "  ${CYAN}forja${RESET} PowerUpSQL"
    local forja_dir="${KON_FORJA}/powerupsql"
    mkdir -p "${forja_dir}"
    
    local url="https://raw.githubusercontent.com/NetSPI/PowerUpSQL/master/PowerUpSQL.ps1"
    curl -sL -o "${forja_dir}/PowerUpSQL.ps1" "${url}" \
        && _ok "forja: PowerUpSQL" \
        || _err "forja: PowerUpSQL"
}

# ── Credenciales / Active Directory (binarios compilados) ──────────────────
function install_mimikatz() {
    echo -e "  ${CYAN}forja${RESET} mimikatz"
    local url
    url=$(curl -s https://api.github.com/repos/gentilkiwi/mimikatz/releases/latest \
        | grep "browser_download_url.*\.zip\"" \
        | grep -o 'https://[^"]*' | head -1)
    if [[ -z "${url}" ]]; then
        _err "mimikatz: no release found"
        return
    fi
    local dest_dir="${KON_FORJA}/mimikatz"
    mkdir -p "${dest_dir}"
    curl -sL -o "${dest_dir}/mimikatz.zip" "${url}" \
        && unzip -oq "${dest_dir}/mimikatz.zip" -d "${dest_dir}" \
        && rm -f "${dest_dir}/mimikatz.zip" \
        && _ok "forja: mimikatz" \
        || _err "forja: mimikatz"
}

# Mirror de binarios ya compilados de GhostPack.
# NOTA: r3motecontrol/Ghostpack-CompiledBinaries (el mirror clásico) tiene
# varias URLs rotas a día de hoy. Rubeus/Seatbelt/SharpUp ya se instalan por
# su cuenta arriba desde SharpCollection; esta función queda sólo como
# fallback/alias histórico y usa la misma fuente verificada.
function install_ghostpack() {
    local base="https://github.com/Flangvik/SharpCollection/raw/master/NetFramework_4.7_x64"
    local tool
    for tool in Rubeus Seatbelt SharpUp SharpView; do
        forja_get ghostpack "${base}/${tool}.exe" "${tool}.exe"
    done
}

function install_sharphound() {
    echo -e "  ${CYAN}forja${RESET} sharphound"
    
    local dest_dir="${KON_FORJA}/sharphound"
    mkdir -p "${dest_dir}"
    
    local url="https://github.com/SpecterOps/SharpHound/releases/latest/download/SharpHound_v2.13.0_windows_x86.zip"
    
    echo "  Descargando desde: ${url}"
    curl -sL -o "${dest_dir}/sharphound.zip" "${url}"
    
    if [[ -f "${dest_dir}/sharphound.zip" ]] && [[ -s "${dest_dir}/sharphound.zip" ]]; then
        unzip -oq "${dest_dir}/sharphound.zip" -d "${dest_dir}" \
            && rm -f "${dest_dir}/sharphound.zip" \
            && _ok "forja: sharphound" \
            || _err "forja: sharphound (unzip failed)"
    else
        _err "forja: sharphound (download failed)"
    fi
}

function install_ncwin() {
    forja_get netcat-win \
        "https://github.com/int0x33/nc.exe/raw/master/nc64.exe" nc64.exe
    forja_get netcat-win \
        "https://github.com/int0x33/nc.exe/raw/master/nc.exe" nc.exe
}

# ── Movimiento lateral ───────────────────────────────────────────────────────
# Las herramientas siguientes cubren el módulo de "Lateral Movement" de
# PEN-300/OSEP a través de distintos vectores: WMI, DCOM, PsExec-style (SMB),
# pass-the-hash sobre named pipes, poisoning y abuso de SCCM.

# SharpWMI: ejecución remota de comandos vía WMI (Win32_Process Create).
function install_sharpwmi() {
    forja_get sharpwmi \
        "https://github.com/Flangvik/SharpCollection/raw/master/NetFramework_4.7_x64/SharpWMI.exe" \
        "SharpWMI.exe"
}

# SharpCOM: lateral movement abusando objetos DCOM (MMC20.Application, etc).
function install_sharpcom() {
    forja_get sharpcom \
        "https://github.com/Flangvik/SharpCollection/raw/master/NetFramework_4.7_x64/SharpCOM.exe" \
        "SharpCOM.exe"
}

# SharpMove: lateral movement vía WMI/DCOM/scheduled tasks con soporte para
# pass-the-hash (token manipulation), distinto enfoque a SharpWMI/SharpCOM.
function install_sharpmove() {
    forja_get sharpmove \
        "https://github.com/Flangvik/SharpCollection/raw/master/NetFramework_4.7_x64/SharpMove.exe" \
        "SharpMove.exe"
}

# SharpNamedPipePTH: pass-the-hash a través de named pipe impersonation, sin
# tocar LSASS directamente (evade varias detecciones EDR comunes).
function install_sharpnamedpipepth() {
    forja_get sharpnamedpipepth \
        "https://github.com/Flangvik/SharpCollection/raw/master/NetFramework_4.7_x64/SharpNamedPipePTH.exe" \
        "SharpNamedPipePTH.exe"
}

# Inveigh: poisoning LLMNR/NBNS/mDNS y captura de hashes NTLMv2 (equivalente
# a Responder pero nativo de Windows/.NET). Útil para el módulo de
# Active Directory introductorio / movimiento lateral inicial de OSEP.
function install_inveigh() {
    forja_get inveigh \
        "https://github.com/Flangvik/SharpCollection/raw/master/NetFramework_4.7_x64/Inveigh.exe" \
        "Inveigh.exe"
}

# SharpSCCM: enumeración y abuso de Microsoft Configuration Manager (SCCM)
# para movimiento lateral/recolección de credenciales. Tema avanzado del
# temario de PEN-300/OSEP en entornos enterprise con SCCM desplegado.
function install_sharpsccm() {
    forja_get sharpsccm \
        "https://github.com/Flangvik/SharpCollection/raw/master/NetFramework_4.7_x64/SharpSCCM.exe" \
        "SharpSCCM.exe"
}

# ── Otras herramientas útiles ──────────────────────────────────────────────
function install_plink() {
    forja_get plink \
        "https://the.earth.li/~sgtatham/putty/latest/w64/plink.exe" \
        "plink.exe"
}

function install_putty() {
    forja_get putty \
        "https://the.earth.li/~sgtatham/putty/latest/w64/putty.exe" \
        "putty.exe"
}

function install_invoke_obfuscation() {
    forja_get invoke-obfuscation \
        "https://raw.githubusercontent.com/danielbohannon/Invoke-Obfuscation/master/Invoke-Obfuscation.psd1" \
        "Invoke-Obfuscation.psd1"
    forja_get invoke-obfuscation \
        "https://raw.githubusercontent.com/danielbohannon/Invoke-Obfuscation/master/Invoke-Obfuscation.psm1" \
        "Invoke-Obfuscation.psm1"
}

# ── Pivoting: .exe de Windows para servir a targets ─────────────────────────
function install_chisel_win() {
    echo -e "  ${CYAN}forja${RESET} chisel (windows)"
    local forja_dir="${KON_FORJA}/chisel"
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
        _err "chisel (windows): no se pudo obtener la version del release"
        return
    fi

    local base="https://github.com/jpillora/chisel/releases/download/v${version}"
    local tmp
    tmp=$(mktemp -d)

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

function install_ligolo_win() {
    echo -e "  ${CYAN}forja${RESET} ligolo-ng (windows)"
    local forja_dir="${KON_FORJA}/ligolo"
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
        _err "ligolo-ng (windows): no se pudo obtener la version del release"
        return
    fi

    local base="https://github.com/nicocha30/ligolo-ng/releases/download/v${version}"
    local tmp
    tmp=$(mktemp -d)

    # Windows agent x64
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

    # Windows proxy x64
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

# ── Package runner ──────────────────────────────────────────────────────────
function package_binaries() {
    echo ""
    echo -e "\033[0;36m[*] ┌┬┬ BINARIES ┬┬┐\033[0m"

    # Linux privesc
    install_linpeas
    install_linenum
    install_pspy
    install_lse

    # Windows / post-explotación
    install_winpeas
    install_powerup
    install_watson
    install_sharpbypassuac

    # AD / Kerberos / Credenciales
    install_mimikatz
    install_ghostpack
    install_rubeus
    install_seatbelt
    install_sharpup
    install_sharpsqlpwn
    install_sharpview
    install_sharpshooter
    install_sharpapplocker

    # Herramientas AD específicas
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

    # Credenciales
    install_lazagne
    install_safetykatz

    # SQL
    install_sqlrecon
    install_powerupsql

    # BloodHound
    install_sharphound

    # Netcat
    install_ncwin

    # Movimiento lateral
    install_sharpwmi
    install_sharpcom
    install_sharpmove
    install_sharpnamedpipepth
    install_inveigh
    install_sharpsccm

    # Pivoting (solo .exe Windows)
    install_chisel_win
    install_ligolo_win

    # Otras herramientas Windows
    install_plink
    install_putty
    install_invoke_obfuscation

    echo ""
    echo -e "\033[0;32m[+] └── Todas las herramientas instaladas en /opt/tools/forja/ ──┘\033[0m"
    echo -e "\033[0;36m[*] Estructura:\033[0m"
    ls -la /opt/tools/forja/
}

# Ejecutar la instalación
package_binaries
