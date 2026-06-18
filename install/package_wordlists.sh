#!/usr/bin/env bash
source /kon/install/common.sh

function install_crunch() { install_apt crunch; }
function install_cupp()   { install_apt cupp; }

function install_seclists() {
    [[ -d "/opt/lists/seclists" ]] && { _info "skip: seclists"; return; }
    mkdir -p /opt/lists
    git clone -q --depth 1 --single-branch --branch master \
        https://github.com/danielmiessler/SecLists.git /opt/lists/seclists >/dev/null 2>&1 \
        || { _err "git: seclists"; return; }
    # Extraer rockyou
    tar -xf /opt/lists/seclists/Passwords/Leaked-Databases/rockyou.txt.tar.gz \
        -C /opt/lists/ 2>/dev/null || true
    # Symlinks en lugares comunes
    ln -sf /opt/lists/seclists /usr/share/seclists 2>/dev/null || true
    mkdir -p /usr/share/wordlists
    ln -sf /opt/lists/seclists  /usr/share/wordlists/seclists 2>/dev/null || true
    ln -sf /opt/lists/rockyou.txt /usr/share/wordlists/rockyou.txt 2>/dev/null || true
    _ok "git: seclists → /opt/lists/seclists"
}

function install_onelistforall() {
    mkdir -p /opt/lists
    wget -q https://raw.githubusercontent.com/six2dez/OneListForAll/main/onelistforallmicro.txt \
        -O /opt/lists/onelistforallmicro.txt \
        && _ok "wget: onelistforallmicro.txt" || _err "wget: onelistforallmicro"
    wget -q https://raw.githubusercontent.com/six2dez/OneListForAll/main/onelistforallshort.txt \
        -O /opt/lists/onelistforallshort.txt \
        && _ok "wget: onelistforallshort.txt" || _err "wget: onelistforallshort"
}

function install_username_anarchy() {
    install_git username-anarchy https://github.com/urbanadventurer/username-anarchy
    ln -sf /opt/tools/src/username-anarchy/username-anarchy /usr/local/bin/username-anarchy 2>/dev/null || true
    _ok "username-anarchy → /usr/local/bin/username-anarchy"
}

function install_cewl() {
    install_apt cewl 2>/dev/null || {
        install_apt ruby ruby-dev
        gem install cewl >/dev/null 2>&1 \
            && _ok "gem: cewl" || _err "gem: cewl"
    }
}

function install_rules() {
    mkdir -p /opt/rules

    local rules=(
        "https://github.com/NSAKEY/nsa-rules/raw/refs/heads/master/_NSAKEY.v2.dive.rule"
        "https://github.com/praetorian-inc/Hob0Rules/raw/refs/heads/master/d3adhob0.rule"
        "https://github.com/stealthsploit/OneRuleToRuleThemStill/raw/refs/heads/main/OneRuleToRuleThemStill.rule"
    )

    for url in "${rules[@]}"; do
        local name
        name=$(basename "${url}")
        wget -q "${url}" -O "/opt/rules/${name}" \
            && _ok "wget: ${name}" || _err "wget: ${name}"
    done
}

function package_wordlists() {
    echo ""
    echo -e "\033[0;36m[*] ┌┬┬ WORDLISTS ┬┬┐\033[0m"
    install_crunch
    install_cupp
    install_cewl
    install_seclists
    install_onelistforall
    install_username_anarchy
    install_rules
}
