#!/usr/bin/env bash
# Author: z1rov

GREEN='\033[0;32m'; RED='\033[0;31m'; CYAN='\033[0;36m'; DIM='\033[2m'; RESET='\033[0m'

KON_TOOLS="/opt/tools"
KON_BIN="${KON_TOOLS}/bin"
KON_SRC="${KON_TOOLS}/src"
KON_FORJA="${KON_TOOLS}/forja"

KON_RUBY_VERSION="3.2.2"
PYTHON_VERSIONS="2.7.18 3.13.2"

mkdir -p "${KON_BIN}" "${KON_SRC}" "${KON_FORJA}"

_ok()       { echo -e "  ${GREEN}[OK]${RESET}    ${DIM}$1${RESET}"; }
_err()      { echo -e "  ${RED}[ERROR]${RESET} $1"; }
_info()     { echo -e "  ${CYAN}[INFO]${RESET}  $1"; }

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

install_gem() {
    local gemset="$1" pkg="$2" version="${3:-}"
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

install_pipx() {
    pipx install -q --system-site-packages "$2" >/dev/null 2>&1 \
        && _ok "pipx: $1" || _err "pipx: $1"
}

link_bin() {
    local name="$1" target="$2"
    if [[ -f "${target}" ]]; then
        ln -sf "${target}" "${KON_BIN}/${name}"
        chmod +x "${target}" 2>/dev/null || true
        _ok "bin: ${name} → ${KON_BIN}/${name}"
    else
        _err "link_bin: ${target} does not exist"
    fi
}

forja_get() {
    local grupo="$1" url="$2" fname="${3:-$(basename "$url")}"
    local dest_dir="${KON_FORJA}/${grupo}"
    mkdir -p "${dest_dir}"
    curl -sL "${url}" -o "${dest_dir}/${fname}" \
        && _ok "forja: ${grupo}/${fname}" || _err "forja: ${grupo}/${fname}"
}

venv_pip() {
    local dest="$1"; shift
    "${dest}/venv/bin/pip" install -q --no-cache-dir "$@" 2>/dev/null \
        && _ok "pip: $*" || _err "pip: $*"
}

venv_pip2() {
    local dest="$1"; shift
    "${dest}/venv/bin/pip" install -q --no-cache-dir "$@" 2>/dev/null
}

pyvenv2_setup() {
    local name="$1" script="$2"
    local dest="${KON_SRC}/${name}"
    if [[ ! -d "${dest}" ]]; then _err "pyvenv2: ${name} (src does not exist)"; return 1; fi
    set_python_env
    local py2_bin
    py2_bin="$(pyenv root)/versions/2.7.18/bin/python2"
    if [[ ! -x "${py2_bin}" ]]; then
        _err "pyvenv2: python2.7.18 not found (run install_pyenv first)"
        return 1
    fi
    "${py2_bin}" -m pip install -q --no-cache-dir virtualenv >/dev/null 2>&1
    "${py2_bin}" -m virtualenv -p "${py2_bin}" "${dest}/venv" >/dev/null 2>&1
    echo "${dest}/venv"
}

_ensure_pipx() {
    export PATH="$HOME/.local/bin:$PATH"

    if command -v pipx >/dev/null 2>&1; then
        return 0
    fi

    _info "pipx not found, attempting to install"

    apt-get update -y >/dev/null 2>&1
    if install_apt pipx && command -v pipx >/dev/null 2>&1; then
        return 0
    fi

    _info "apt failed, trying with pip --user"
    pip3 install -q --no-cache-dir --user pipx >/dev/null 2>&1
    if command -v pipx >/dev/null 2>&1; then
        _ok "pip: pipx (--user)"
        return 0
    fi

    _err "pipx: could not be installed by any method"
    return 1
}

_gh_find_asset() {
    local repo="$1" expr="$2"
    python3 - "${repo}" "${expr}" << 'PYEOF'
import sys, json, urllib.request, ssl

repo = sys.argv[1]
expr = sys.argv[2]

ctx = ssl.create_default_context()
ctx.check_hostname = False
ctx.verify_mode = ssl.CERT_NONE

def fetch(url):
    req = urllib.request.Request(url, headers={"User-Agent": "curl/7.0"})
    with urllib.request.urlopen(req, context=ctx, timeout=15) as r:
        return json.load(r)

endpoints = [
    f"https://api.github.com/repos/{repo}/releases/latest",
    f"https://api.github.com/repos/{repo}/releases?per_page=10",
]

for ep in endpoints:
    try:
        data = fetch(ep)
        releases = data if isinstance(data, list) else [data]
        for release in releases:
            for asset in release.get("assets", []):
                n = asset["name"]
                try:
                    if eval(expr):
                        print(asset["browser_download_url"])
                        sys.exit(0)
                except Exception:
                    pass
    except Exception:
        pass

sys.exit(1)
PYEOF
}

_gh_list_assets() {
    local repo="$1"
    python3 - "${repo}" << 'PYEOF'
import sys, json, urllib.request, ssl
repo = sys.argv[1]
ctx = ssl.create_default_context()
ctx.check_hostname = False
ctx.verify_mode = ssl.CERT_NONE
req = urllib.request.Request(
    f"https://api.github.com/repos/{repo}/releases/latest",
    headers={"User-Agent": "curl/7.0"})
with urllib.request.urlopen(req, context=ctx, timeout=15) as r:
    data = json.load(r)
for a in data.get("assets", []):
    print(a["name"])
PYEOF
}

_run_logged() {
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

function set_bin_path() {
    colorecho "Adding ${KON_BIN} to PATH"
    export PATH="${KON_BIN}:$PATH"
}

function set_cargo_env() {
    colorecho "Setting cargo environment"
    [[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"
}

function set_ruby_env() {
    colorecho "Setting ruby environment"
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

    source /usr/local/rvm/scripts/rvm

    colorecho "Installing ruby ${KON_RUBY_VERSION} (default gemset)"
    rvm install "${KON_RUBY_VERSION}" >/dev/null 2>&1 \
        && _ok "rvm: ruby ${KON_RUBY_VERSION}" || _err "rvm: ruby ${KON_RUBY_VERSION}"
    rvm use "${KON_RUBY_VERSION}@default" --create >/dev/null 2>&1

    rvm cleanup all >/dev/null 2>&1 || true
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

    pyenv global $PYTHON_VERSIONS

    install_apt python3-venv

    _ok "pyenv: global versions set to: ${PYTHON_VERSIONS}"
}

install_rust() {
    if command -v rustc >/dev/null 2>&1; then
        _info "skip: rust (already installed: $(rustc --version))"
        return
    fi
    if [[ -f "${HOME}/.cargo/env" ]]; then
        source "${HOME}/.cargo/env"
        if command -v rustc >/dev/null 2>&1; then
            _info "skip: rust (already installed via rustup: $(rustc --version))"
            return
        fi
    fi
    install_apt curl
    curl -sSf https://sh.rustup.rs -o /tmp/rustup-init.sh \
        || { _err "rust: download rustup-init failed"; return 1; }
    bash /tmp/rustup-init.sh -y --default-toolchain stable --profile minimal >/dev/null 2>&1 \
        && _ok "rust: rustup stable toolchain" \
        || { _err "rust: rustup install failed"; rm -f /tmp/rustup-init.sh; return 1; }
    rm -f /tmp/rustup-init.sh
    source "${HOME}/.cargo/env"
    if command -v rustc >/dev/null 2>&1; then
        _ok "rust: $(rustc --version) → ${HOME}/.cargo/bin"
    else
        _err "rust: install finished but rustc not found on PATH"
        return 1
    fi
}
