#!/usr/bin/env bash

GREEN='\033[0;32m'; RED='\033[0;31m'; CYAN='\033[0;36m'; DIM='\033[2m'; RESET='\033[0m'

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
    go install "$2" >/dev/null 2>&1 || { _err "go:  $1"; return 1; }
    local gobin="${GOPATH:-/root/go}/bin/$1"
    if [[ -f "${gobin}" ]]; then
        ln -sf "${gobin}" "${KON_BIN}/$1"
    fi
    _ok "go:  $1 → ${KON_BIN}/$1"
}

install_git() {
    local dest="${KON_SRC}/$1"
    if [[ -d "${dest}" ]]; then
        _info "skip: $1 (already exists)"
        return
    fi
    git clone -q --depth 1 "$2" "${dest}" >/dev/null 2>&1 \
        && _ok "git: $1 → ${dest}" || _err "git: $1"
}

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

forja_get() {
    local grupo="$1" url="$2" fname="${3:-$(basename "$url")}"
    local dest_dir="${KON_FORJA}/${grupo}"
    mkdir -p "${dest_dir}"
    curl -sL "${url}" -o "${dest_dir}/${fname}" \
        && _ok "forja: ${grupo}/${fname}" || _err "forja: ${grupo}/${fname}"
}



#!/usr/bin/env bash

KON_RUBY_VERSION="3.2.2"

PYTHON_VERSIONS="2.7.18 3.13.2"

function set_bin_path() {
    colorecho "Adding ${KON_BIN} to PATH"
    export PATH="${KON_BIN}:$PATH"
}

function set_cargo_env() {
    colorecho "Setting cargo environment"
    # shellcheck disable=SC1091
    [[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"
}

function set_ruby_env() {
    colorecho "Setting ruby environment"
    # shellcheck disable=SC1091
    source /usr/local/rvm/scripts/rvm
    rvm use "${KON_RUBY_VERSION}@default" >/dev/null 2>&1
}

function set_python_env() {
    colorecho "Setting pyenv environment"
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="${PYENV_ROOT}/bin:$PATH"
    eval "$(pyenv init --path)"
    eval "$(pyenv init -)"
}

function set_env() {
    colorecho "Setting env (caller)"
    set_bin_path
    set_cargo_env
    set_ruby_env
    set_python_env
}

function install_rvm() {
    colorecho "Installing RVM (Ruby Version Manager)"
    install_apt gnupg2
    install_apt curl

    curl -sSL https://rvm.io/mpapis.asc | gpg --import - >/dev/null 2>&1
    curl -sSL https://rvm.io/pkuczynski.asc | gpg --import - >/dev/null 2>&1

    curl -sSL https://get.rvm.io -o /tmp/rvm-installer.sh
    bash /tmp/rvm-installer.sh stable >/dev/null 2>&1 \
        && _ok "rvm: installer" || { _err "rvm: installer"; return 1; }
    rm -f /tmp/rvm-installer.sh

    # shellcheck disable=SC1091
    source /usr/local/rvm/scripts/rvm

    colorecho "Installing ruby ${KON_RUBY_VERSION} (default gemset)"
    rvm install "${KON_RUBY_VERSION}" >/dev/null 2>&1 \
        && _ok "rvm: ruby ${KON_RUBY_VERSION}" || _err "rvm: ruby ${KON_RUBY_VERSION}"
    rvm use "${KON_RUBY_VERSION}@default" --create >/dev/null 2>&1

    rvm cleanup all >/dev/null 2>&1 || true
}

install_gem() {
    local gemset="$1" pkg="$2" version="${3:-}"
    # shellcheck disable=SC1091
    source /usr/local/rvm/scripts/rvm
    rvm use "${KON_RUBY_VERSION}@${gemset}" --create >/dev/null 2>&1
    if [[ -n "${version}" ]]; then
        gem install -q "${pkg}" -v "${version}" >/dev/null 2>&1 \
            && _ok "gem: ${pkg} (${version}) [gemset:${gemset}]" \
            || _err "gem: ${pkg} (${version}) [gemset:${gemset}]"
    else
        gem install -q "${pkg}" >/dev/null 2>&1 \
            && _ok "gem: ${pkg} [gemset:${gemset}]" \
            || _err "gem: ${pkg} [gemset:${gemset}]"
    fi
    rvm use "${KON_RUBY_VERSION}@default" >/dev/null 2>&1
}

function install_pyenv() {
    colorecho "Installing pyenv"
    install_apt git
    install_apt curl
    install_apt build-essential

    curl -o /tmp/pyenv.run https://pyenv.run
    bash /tmp/pyenv.run >/dev/null 2>&1 \
        && _ok "pyenv: installer" || { _err "pyenv: installer"; return 1; }
    rm -f /tmp/pyenv.run

    set_python_env

    colorecho "Installing build deps for python2/python3 compilation"
    install_apt libssl-dev
    install_apt zlib1g-dev
    install_apt libbz2-dev
    install_apt libreadline-dev
    install_apt libsqlite3-dev
    install_apt libncurses5-dev
    install_apt libncursesw5-dev
    install_apt libffi-dev
    install_apt liblzma-dev

    local v
    for v in $PYTHON_VERSIONS; do
        colorecho "Installing python${v}"
        pyenv install -s "$v" >/dev/null 2>&1 \
            && _ok "pyenv: python${v}" || _err "pyenv: python${v}"
    done

    # shellcheck disable=SC2086
    pyenv global $PYTHON_VERSIONS

    install_apt python3-venv

    _ok "pyenv: global versions set to: ${PYTHON_VERSIONS}"
}

colorecho() {
    echo -e "${CYAN}[*]${RESET} $1"
}

venv_pip() {
    local dest="$1"; shift
    "${dest}/venv/bin/pip" install -q --no-cache-dir "$@" 2>/dev/null \
        && _ok "pip: $*" || _err "pip: $*"
}
