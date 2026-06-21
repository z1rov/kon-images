#!/usr/bin/env bash
source /kon/install/common.sh
mkdir -p /opt/tools

# Estas herramientas no son repos para clonar (src/) ni paquetes Go (bin/
# directo) — son binarios/scripts sueltos. Todo va a forja/<tool>/ usando
# forja_get cuando es un archivo plano, o curl+unzip/gunzip a mano cuando el
# release viene comprimido (igual que tuvimos que hacer con feroxbuster).
# Solo lo que es nativo de Linux (linpeas, LinEnum, chisel) recibe además un
# symlink en bin/ — lo de Windows (winPEAS, mimikatz, Rubeus, etc.) solo se
# aloja para servirlo a un objetivo, no corre en este contenedor.

# ── Linux privesc ──────────────────────────────────────────────────────────
function install_linpeas() {
    forja_get linpeas \
        "https://github.com/peass-ng/PEASS-ng/releases/latest/download/linpeas.sh" \
        linpeas.sh
    link_bin linpeas.sh "${KON_FORJA}/linpeas/linpeas.sh"
}

function install_linenum() {
    forja_get linenum \
        "https://raw.githubusercontent.com/rebootuser/LinEnum/master/LinEnum.sh" \
        LinEnum.sh
    link_bin LinEnum.sh "${KON_FORJA}/linenum/LinEnum.sh"
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

# ── Herramientas de AD / Kerberos ──────────────────────────────────────────
function install_rubeus() {
    echo -e "  ${CYAN}forja${RESET} rubeus"
    local url
    url=$(curl -s https://api.github.com/repos/GhostPack/Rubeus/releases/latest \
        | grep "browser_download_url.*\.exe\"" \
        | grep -o 'https://[^"]*' | head -1)
    
    if [[ -z "${url}" ]]; then
        # Fallback: usar versión compilada de repositorio alternativo
        url="https://github.com/r3motecontrol/Ghostpack-CompiledBinaries/raw/master/Rubeus.exe"
    fi
    
    forja_get rubeus "${url}" "Rubeus.exe"
}

function install_seatbelt() {
    forja_get seatbelt \
        "https://github.com/r3motecontrol/Ghostpack-CompiledBinaries/raw/master/Seatbelt.exe" \
        "Seatbelt.exe"
}

function install_sharpup() {
    forja_get sharpup \
        "https://github.com/r3motecontrol/Ghostpack-CompiledBinaries/raw/master/SharpUp.exe" \
        "SharpUp.exe"
}

function install_sharpsqlninja() {
    forja_get sharpsqlninja \
        "https://github.com/klezVirus/SharpSQL/releases/latest/download/SharpSQL.exe" \
        "SharpSQL.exe"
}

function install_sharpview() {
    forja_get sharpview \
        "https://github.com/r3motecontrol/Ghostpack-CompiledBinaries/raw/master/SharpView.exe" \
        "SharpView.exe"
}

function install_sharpshooter() {
    forja_get sharpshooter \
        "https://github.com/mdsecactivebreach/SharpShooter/releases/latest/download/SharpShooter.exe" \
        "SharpShooter.exe"
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

# Mirror de binarios ya compilados de GhostPack (Rubeus, Seatbelt, SharpUp) —
# son proyectos de Visual Studio, no hay release oficial precompilado.
function install_ghostpack() {
    local base="https://github.com/r3motecontrol/Ghostpack-CompiledBinaries/raw/master"
    local tool
    for tool in Rubeus Seatbelt SharpUp SharpView; do
        forja_get ghostpack "${base}/${tool}.exe" "${tool}.exe"
    done
}
function install_sharphound() {
    echo -e "  ${CYAN}forja${RESET} sharphound"
    
    local dest_dir="${KON_FORJA}/sharphound"
    mkdir -p "${dest_dir}"
    
    # Usar la URL con redirect (más estable, siempre apunta al último release)
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

function install_winrm() {
    forja_get winrm \
        "https://raw.githubusercontent.com/Hackplayers/PsCabesha-tools/master/Privesc/winRM.ps1" \
        "winRM.ps1"
}

function install_invoke_obfuscation() {
    forja_get invoke-obfuscation \
        "https://raw.githubusercontent.com/danielbohannon/Invoke-Obfuscation/master/Invoke-Obfuscation.psd1" \
        "Invoke-Obfuscation.psd1"
    forja_get invoke-obfuscation \
        "https://raw.githubusercontent.com/danielbohannon/Invoke-Obfuscation/master/Invoke-Obfuscation.psm1" \
        "Invoke-Obfuscation.psm1"
}

# ── Pivoting (binario también usable directo en este contenedor) ───────────
function install_chisel() {
    echo -e "  ${CYAN}forja${RESET} chisel"
    local url
    url=$(curl -s https://api.github.com/repos/jpillora/chisel/releases/latest \
        | grep "browser_download_url.*linux_amd64\.gz\"" \
        | grep -o 'https://[^"]*' | head -1)
    if [[ -z "${url}" ]]; then
        _err "chisel: no release found"
        return
    fi
    local dest_dir="${KON_FORJA}/chisel"
    mkdir -p "${dest_dir}"
    curl -sL "${url}" | gunzip > "${dest_dir}/chisel" 2>/dev/null
    if [[ -s "${dest_dir}/chisel" ]]; then
        chmod +x "${dest_dir}/chisel"
        link_bin chisel "${dest_dir}/chisel"
    else
        _err "forja: chisel"
    fi
}

function install_ligolo() {
    echo -e "  ${CYAN}forja${RESET} ligolo"
    local url
    url=$(curl -s https://api.github.com/repos/nicocha30/ligolo-ng/releases/latest \
        | grep "browser_download_url.*linux_amd64\.tar\.gz\"" \
        | grep -o 'https://[^"]*' | head -1)
    if [[ -z "${url}" ]]; then
        _err "ligolo: no release found"
        return
    fi
    local dest_dir="${KON_FORJA}/ligolo"
    mkdir -p "${dest_dir}"
    curl -sL "${url}" | tar -xz -C "${dest_dir}" 2>/dev/null
    if [[ -f "${dest_dir}/proxy" ]]; then
        chmod +x "${dest_dir}/proxy"
        link_bin ligolo-proxy "${dest_dir}/proxy"
        _ok "forja: ligolo"
    else
        _err "forja: ligolo"
    fi
}

# ── Package runner ──────────────────────────────────────────────────────────
function package_binaries() {
    echo ""
    echo -e "\033[0;36m[*] ┌┬┬ BINARIES ┬┬┐\033[0m"

    # Linux
    install_linpeas
    install_linenum

    # Windows / post-explotación
    install_winpeas
    install_powerup

    # AD / Kerberos / Credenciales
    install_mimikatz
    install_ghostpack
    install_rubeus          # Rubeus específico
    install_seatbelt        # Seatbelt específico
    install_sharpup         # SharpUp específico
    install_sharpsqlninja   # SharpSQL
    install_sharpview       # SharpView
    install_sharpshooter    # SharpShooter

    # BloodHound
    install_sharphound

    # Netcat
    install_ncwin

    # Otras herramientas Windows
    install_plink
    install_putty
    install_winrm
    install_invoke_obfuscation

    echo -e "\033[0;32m[+] └── Binarios instalados correctamente ──┘\033[0m"
}

# Ejecutar la instalación
package_binaries
