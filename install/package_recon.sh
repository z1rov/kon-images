#!/usr/bin/env bash
source /kon/install/common.sh
mkdir -p /opt/tools

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

install_nmap()      { install_apt nmap; }
install_masscan()   { install_apt masscan; }
install_whois()     { install_apt whois; }
install_dnsutils()  { install_apt dnsutils; }
install_netcat()    { install_apt ncat; }
install_jq()        { install_apt jq; }
install_dirb()      { install_apt dirb; }

install_subfinder() { install_go subfinder github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest; }
install_httpx()     { install_go httpx github.com/projectdiscovery/httpx/cmd/httpx@latest; }
install_nuclei()    { install_go nuclei github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest; }
install_dnsx()      { install_go dnsx github.com/projectdiscovery/dnsx/cmd/dnsx@latest; }
install_naabu()     { install_go naabu github.com/projectdiscovery/naabu/v2/cmd/naabu@latest; }
install_katana()    { install_go katana github.com/projectdiscovery/katana/cmd/katana@latest; }
install_tlsx()      { install_go tlsx github.com/projectdiscovery/tlsx/cmd/tlsx@latest; }
install_alterx()    { install_go alterx github.com/projectdiscovery/alterx/cmd/alterx@latest; }
install_ffuf()      { install_go ffuf github.com/ffuf/ffuf/v2@latest; }
install_gobuster()  { install_go gobuster github.com/OJ/gobuster/v3@latest; }
install_amass()     { install_go amass github.com/owasp-amass/amass/v4/...@master; }

install_wafw00f()   { install_pip wafw00f; }
install_arjun()     { install_pip arjun; }

function install_feroxbuster() {
    echo -e "  ${CYAN}bin${RESET} feroxbuster"
    local dest_dir="${KON_SRC}/feroxbuster"
    mkdir -p "${dest_dir}"
    command -v unzip >/dev/null 2>&1 || install_apt unzip

    local url
    url=$(_gh_find_asset "epi052/feroxbuster" "n.endswith('amd64.deb')")
    if [[ -n "${url}" ]]; then
        curl -sL -o "${dest_dir}/feroxbuster.deb" "${url}"
        dpkg -i "${dest_dir}/feroxbuster.deb" >/dev/null 2>&1 \
            || apt-get -f install -y >/dev/null 2>&1
        if command -v feroxbuster >/dev/null 2>&1; then
            ln -sf "$(command -v feroxbuster)" "${KON_BIN}/feroxbuster"
            _ok "deb: feroxbuster → ${KON_BIN}/feroxbuster"
            return
        fi
    fi

    url=$(_gh_find_asset "epi052/feroxbuster" \
        "'x86_64-linux' in n and 'musl' in n and n.endswith('.zip')")
    [[ -z "${url}" ]] && url=$(_gh_find_asset "epi052/feroxbuster" \
        "'x86_64-linux' in n and n.endswith('.zip')")

    if [[ -n "${url}" ]]; then
        curl -sL -o "${dest_dir}/feroxbuster.zip" "${url}"
        unzip -qo "${dest_dir}/feroxbuster.zip" -d "${dest_dir}"
        rm -f "${dest_dir}/feroxbuster.zip"
        if [[ -f "${dest_dir}/feroxbuster" ]]; then
            chmod +x "${dest_dir}/feroxbuster"
            if "${dest_dir}/feroxbuster" --version >/dev/null 2>&1; then
                ln -sf "${dest_dir}/feroxbuster" "${KON_BIN}/feroxbuster"
                _ok "bin: feroxbuster → ${KON_BIN}/feroxbuster"
                return
            fi
        fi
    fi

    _err "feroxbuster: todos los métodos fallaron"
}

function install_rustscan() {
    echo -e "  ${CYAN}bin${RESET} rustscan"
    local dest_dir="${KON_SRC}/rustscan"
    mkdir -p "${dest_dir}"

    local url
    url=$(_gh_find_asset "RustScan/RustScan" \
        "n.endswith('amd64.deb') or ('amd64' in n and n.endswith('.deb'))")
    if [[ -n "${url}" ]]; then
        curl -sL -o "${dest_dir}/rustscan.deb" "${url}"
        dpkg -i "${dest_dir}/rustscan.deb" >/dev/null 2>&1 \
            || apt-get -f install -y >/dev/null 2>&1
        if command -v rustscan >/dev/null 2>&1; then
            ln -sf "$(command -v rustscan)" "${KON_BIN}/rustscan"
            _ok "deb: rustscan → ${KON_BIN}/rustscan"
            return
        fi
    fi

    url=$(_gh_find_asset "RustScan/RustScan" \
        "('x86_64' in n or 'amd64' in n) and 'linux' in n.lower() and not n.endswith('.deb')")
    if [[ -n "${url}" ]]; then
        local fname
        fname=$(basename "${url}")
        curl -sL -o "${dest_dir}/${fname}" "${url}"
        [[ "${fname}" == *.tar.gz ]] && tar -xzf "${dest_dir}/${fname}" -C "${dest_dir}" 2>/dev/null
        [[ "${fname}" == *.zip ]] && unzip -qo "${dest_dir}/${fname}" -d "${dest_dir}" 2>/dev/null
        local bin_path
        bin_path=$(find "${dest_dir}" -type f -name "rustscan" 2>/dev/null | head -1)
        [[ -z "${bin_path}" ]] && bin_path="${dest_dir}/${fname}"
        if [[ -f "${bin_path}" ]]; then
            chmod +x "${bin_path}"
            if "${bin_path}" --version >/dev/null 2>&1; then
                ln -sf "${bin_path}" "${KON_BIN}/rustscan"
                _ok "bin: rustscan → ${KON_BIN}/rustscan"
                return
            fi
        fi
    fi

    url=$(_gh_find_asset "RustScan/RustScan" \
        "'rustscan' in n.lower() and not n.endswith('.deb') and not n.endswith('.sha256')")
    if [[ -n "${url}" ]]; then
        local fname
        fname=$(basename "${url}")
        curl -sL -o "${dest_dir}/${fname}" "${url}"
        [[ "${fname}" == *.tar.gz ]] && tar -xzf "${dest_dir}/${fname}" -C "${dest_dir}" 2>/dev/null
        [[ "${fname}" == *.zip ]] && unzip -qo "${dest_dir}/${fname}" -d "${dest_dir}" 2>/dev/null
        local bin_path
        bin_path=$(find "${dest_dir}" -type f \
            ! -name "*.tar.gz" ! -name "*.zip" ! -name "*.sha256" ! -name "*.deb" \
            2>/dev/null | head -1)
        if [[ -n "${bin_path}" ]]; then
            chmod +x "${bin_path}"
            if "${bin_path}" --version >/dev/null 2>&1; then
                ln -sf "${bin_path}" "${KON_BIN}/rustscan"
                _ok "bin: rustscan → ${KON_BIN}/rustscan"
                return
            fi
        fi
    fi

    _err "rustscan: todos los métodos fallaron"
}

function install_nikto() {
    echo -e "  ${CYAN}git${RESET} nikto"
    local dest="${KON_SRC}/nikto"

    if [[ ! -d "${dest}" ]]; then
        git clone -q --depth 1 "https://github.com/sullo/nikto" "${dest}" \
            || { _err "git: nikto (clone failed)"; return; }
    fi

    command -v perl >/dev/null 2>&1 || install_apt perl
    command -v cpanm >/dev/null 2>&1 || install_apt cpanminus
    cpanm --notest --quiet JSON XML::Writer 2>/dev/null || true

    if [[ -f "${dest}/program/nikto.pl" ]]; then
        chmod +x "${dest}/program/nikto.pl"
        printf '#!/usr/bin/env bash\nexport LC_ALL=C LANG=C\nexec perl "%s/program/nikto.pl" "$@"\n' \
            "${dest}" > "${KON_BIN}/nikto"
        chmod +x "${KON_BIN}/nikto"
        _ok "git: nikto → ${KON_BIN}/nikto"
    else
        _err "git: nikto (nikto.pl not found)"
    fi
}

function install_eyewitness() {
    echo -e "  ${CYAN}git${RESET} EyeWitness"
    local dest="${KON_SRC}/EyeWitness"

    if [[ ! -d "${dest}" ]]; then
        git clone -q --depth 1 "https://github.com/RedSiege/EyeWitness" "${dest}" \
            || { _err "git: EyeWitness (clone failed)"; return; }
    fi

    if [[ -f "${dest}/Python/requirements.txt" ]]; then
        python3 -m pip install -q --no-cache-dir --break-system-packages \
            -r "${dest}/Python/requirements.txt" 2>/dev/null || true
    fi
    for pkg in netaddr selenium fuzzywuzzy python-Levenshtein; do
        python3 -c "import ${pkg//-/_}" 2>/dev/null \
            || python3 -m pip install -q --no-cache-dir --break-system-packages \
                "${pkg}" 2>/dev/null || true
    done

    if [[ -f "${dest}/Python/EyeWitness.py" ]]; then
        printf '#!/usr/bin/env bash\nexec python3 "%s/Python/EyeWitness.py" "$@"\n' \
            "${dest}" > "${KON_BIN}/eyewitness"
        chmod +x "${KON_BIN}/eyewitness"
        _ok "git: EyeWitness → ${KON_BIN}/eyewitness"
    else
        _err "git: EyeWitness (EyeWitness.py not found)"
    fi
}

function package_recon() {
    echo ""
    echo -e "\033[0;36m[*] ┌┬┬ RECON ┬┬┐\033[0m"

    install_nmap
    install_masscan
    install_whois
    install_dnsutils
    install_netcat
    install_jq
    install_dirb

    install_subfinder
    install_httpx
    install_nuclei
    install_dnsx
    install_naabu
    install_katana
    install_tlsx
    install_alterx
    install_ffuf
    install_gobuster
    install_amass

    install_wafw00f
    install_arjun

    install_feroxbuster
    install_rustscan
    install_nikto
    install_eyewitness

    echo -e "\033[0;32m[OK]  RECON package completed${RESET}"
}
