FROM debian:bookworm-slim

# ── Environment ─────────────────────────────────────────────────────────
ENV DEBIAN_FRONTEND=noninteractive \
    KON_HOME=/kon \
    KON_ANVIL=/anvil \
    TERM=xterm-256color \
    SHELL=/bin/bash \
    LANG=en_US.UTF-8 \
    GOPATH="/root/go" \
    PATH="${PATH}:/usr/local/go/bin:/root/go/bin:/opt/tools/bin:/usr/local/bin"

# ── [L1] Base APT packages ──────────────────────────────────────────────
# Changes rarely. If it changes, everything rebuilds — acceptable.
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash ca-certificates curl wget git gnupg locate\
    python3 python3-pip iproute2 iputils-ping nano\
    dnsutils net-tools procps locales tzdata \
    less vim sudo openssh-client \
    build-essential gcc libssl-dev libffi-dev \
    python3-dev \
    krb5-config libkrb5-dev libldap2-dev libsasl2-dev \
    samba-common-bin \
    && locale-gen en_US.UTF-8 \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# ── [L2] Official Go 1.23.5 ─────────────────────────────────────────────
# Separated from APT: if Go is updated, the APT packages are not reinstalled.
RUN set -e; \
    GO_VERSION="1.23.5"; \
    ARCH=$(uname -m); \
    case "${ARCH}" in \
        x86_64)  GOARCH="amd64" ;; \
        aarch64) GOARCH="arm64" ;; \
        *)       echo "Unsupported arch: ${ARCH}"; exit 1 ;; \
    esac; \
    curl -fsSL "https://go.dev/dl/go${GO_VERSION}.linux-${GOARCH}.tar.gz" \
        -o /tmp/go.tar.gz; \
    rm -rf /usr/local/go; \
    tar -C /usr/local -xzf /tmp/go.tar.gz; \
    rm /tmp/go.tar.gz; \
    /usr/local/go/bin/go version

# ── [L3] ZSH and shell tooling ──────────────────────────────────────────
# Separated: adjusting the shell should not invalidate Go or base APT.
RUN apt-get update && apt-get install -y --no-install-recommends \
    zsh zsh-syntax-highlighting zsh-autosuggestions fzf \
    powerline fonts-powerline \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# ── [L4] Oh My ZSH and plugins ───────────────────────────────────────────
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended && \
    git clone https://github.com/zsh-users/zsh-autosuggestions \
        ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions && \
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \
        ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

# ── [L5] common.sh ───────────────────────────────────────────────────────
# CRITICAL: it is a dependency of every package_*.sh.
# Being the first one copied, any change to it invalidates everything after it.
# Keeping it stable is the key to the entire granular cache scheme.
COPY install/common.sh /kon/install/common.sh
RUN chmod +x /kon/install/common.sh

# ── [L6] package_recon ───────────────────────────────────────────────────
COPY install/package_recon.sh /kon/install/package_recon.sh
RUN chmod +x /kon/install/package_recon.sh && \
   apt-get update && \
   bash -c 'source /kon/install/common.sh && \
            source /kon/install/package_recon.sh && \
            package_recon' && \
   apt-get clean && rm -rf /var/lib/apt/lists/*

# ── [L7] package_wordlists (DESACTIVADO) ─────────────────────────────────
# More stable: wordlists do not change frequently.
# Placed first among the packages to maximize cache hits.
# COPY install/package_wordlists.sh /kon/install/package_wordlists.sh
# RUN chmod +x /kon/install/package_wordlists.sh && \
#    apt-get update && \
#    bash -c 'source /kon/install/common.sh && \
#             source /kon/install/package_wordlists.sh && \
#             package_wordlists' && \
#    apt-get clean && rm -rf /var/lib/apt/lists/*

# ── [L8] package_ad (DESACTIVADO) ────────────────────────────────────────
# AD tools: stable, but more complex than wordlists.
# COPY install/package_ad.sh /kon/install/package_ad.sh
# RUN chmod +x /kon/install/package_ad.sh && \
#    apt-get update && \
#    bash -c 'source /kon/install/common.sh && \
#             source /kon/install/package_ad.sh && \
#             package_ad' && \
#    apt-get clean && rm -rf /var/lib/apt/lists/*

# ── [L9] package_infra (DESACTIVADO) ─────────────────────────────────────
# Placed last among the packages because it is the one you actively change the most.
# Changing infra only invalidates this layer and assets/runtime L10-L12.
# COPY install/package_infra.sh /kon/install/package_infra.sh
# RUN chmod +x /kon/install/package_infra.sh && \
#     apt-get update && \
#     bash -c 'source /kon/install/common.sh && \
#              source /kon/install/package_infra.sh && \
#              package_infra' && \
#     apt-get clean && rm -rf /var/lib/apt/lists/*



# ── [L10] package_web commented out, structure ready to activate ────────
# COPY install/package_web.sh /kon/install/package_web.sh
# RUN chmod +x /kon/install/package_web.sh && \
#     apt-get update && \
#     bash -c 'source /kon/install/common.sh && \
#              source /kon/install/package_web.sh && \
#              package_web' && \
#     apt-get clean && rm -rf /var/lib/apt/lists/*

# CREAR MAS LAYERS EN CASO SE QUIERA AGREGAR NUEVAS TOOLS COMO 5.1.1.sh o algo asi, juntas como 15 tools nuevas y le metes genarin del futuro

# ── [L11] Assets ──────────────────────────────────────────────────────────
# Separated from install/: changing an alias or the banner does not touch any package.
COPY assets/ /kon/assets/

# ── [L12] Runtime and ZSH config ─────────────────────────────────────────
# The most volatile part: startup scripts and shell configuration.
# By going last, any runtime adjustment does not invalidate any tool layer.
COPY runtime/ /kon/runtime/
COPY assets/zshrc-kon /root/.zshrc
ENV PATH="${PATH}:/root/.local/bin"

# ── [L13] Final permissions and directory structure ─────────────────────
RUN find /kon -name "*.sh" -exec chmod +x {} \; && \
    mkdir -p /anvil /opt/tools/bin /opt/tools/src /opt/tools/forja \
             /usr/share/wordlists /usr/share/rules

WORKDIR /anvil
ENTRYPOINT ["/kon/runtime/init.sh"]
