#!/usr/bin/env bash

GREEN='\033[0;32m'; RED='\033[0;31m'; CYAN='\033[0;36m'; DIM='\033[2m'; RESET='\033[0m'

# ── Estructura canónica de /opt/tools ──────────────────────────────────────
#   /opt/tools/bin/    → symlinks a TODO binario ejecutable listo para usar
#   /opt/tools/src/    → repos git clonados completos (código fuente)
#   /opt/tools/forja/  → binarios sueltos descargados (releases, .exe, 32/64 bit)
# Estas variables las usan install_git / install_go / install_apt internamente.
# Los package_*.sh NO necesitan cambiar: siguen llamando a las mismas funciones.
KON_TOOLS="/opt/tools"
KON_BIN="${KON_TOOLS}/bin"
KON_SRC="${KON_TOOLS}/src"
KON_FORJA="${KON_TOOLS}/forja"

mkdir -p "${KON_BIN}" "${KON_SRC}" "${KON_FORJA}"

_ok()  { echo -e "  ${GREEN}[OK]${RESET}    ${DIM}$1${RESET}"; }
_err() { echo -e "  ${RED}[ERROR]${RESET} $1"; }
_info(){ echo -e "  ${CYAN}[INFO]${RESET}  $1"; }

install_apt() {
    apt-get install -y --no-install-recommends "$1" >/dev/null 2>&1 \
        && _ok "apt: $1" || _err "apt: $1"
}

install_pip() {
    pip3 install -q --no-cache-dir --break-system-packages "$1" >/dev/null 2>&1 \
        && _ok "pip: $1" || _err "pip: $1"
}

install_go() {
    # $1 = nombre del binario, $2 = ruta de import de go
    go install "$2" >/dev/null 2>&1 || { _err "go:  $1"; return 1; }
    # go install deja el binario en $GOPATH/bin (ya está en PATH), pero además
    # dejamos un symlink en bin/ para que TODO lo ejecutable viva en un solo sitio.
    local gobin="${GOPATH:-/root/go}/bin/$1"
    if [[ -f "${gobin}" ]]; then
        ln -sf "${gobin}" "${KON_BIN}/$1"
    fi
    _ok "go:  $1 → ${KON_BIN}/$1"
}

install_git() {
    # $1 = nombre, $2 = url. Clona en src/$1 (no directo en /opt/tools).
    local dest="${KON_SRC}/$1"
    if [[ -d "${dest}" ]]; then
        _info "skip: $1 (already exists)"
        return
    fi
    git clone -q --depth 1 "$2" "${dest}" >/dev/null 2>&1 \
        && _ok "git: $1 → ${dest}" || _err "git: $1"
}

# Crea un symlink ejecutable en bin/ apuntando a algo dentro de src/ o forja/.
# Uso: link_bin <nombre_en_bin> <ruta_absoluta_al_binario_real>
link_bin() {
    local name="$1" target="$2"
    if [[ -f "${target}" ]]; then
        ln -sf "${target}" "${KON_BIN}/${name}"
        chmod +x "${target}" 2>/dev/null || true
        _ok "bin: ${name} → ${KON_BIN}/${name}"
    else
        _err "link_bin: ${target} no existe"
    fi
}

# Descarga un binario suelto (release de GitHub, build, etc.) directo a forja/<grupo>/
# y deja el symlink correspondiente en bin/. Pensado para cosas como mimikatz
# (con build de 32 y 64 bit) que no son un repo git que se clona.
# Uso: forja_get <grupo> <url> [nombre_archivo_destino]
forja_get() {
    local grupo="$1" url="$2" fname="${3:-$(basename "$url")}"
    local dest_dir="${KON_FORJA}/${grupo}"
    mkdir -p "${dest_dir}"
    curl -sL "${url}" -o "${dest_dir}/${fname}" \
        && _ok "forja: ${grupo}/${fname}" || _err "forja: ${grupo}/${fname}"
}
