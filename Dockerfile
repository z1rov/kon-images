FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive \
    KON_HOME=/kon \
    KON_ANVIL=/anvil \
    TERM=xterm-256color \
    SHELL=/bin/bash \
    LANG=en_US.UTF-8 \
    GOPATH="/root/go" \
    PATH="${PATH}:/usr/local/go/bin:/root/go/bin:/opt/tools/bin:/usr/local/bin"

RUN apt-get update && apt-get install -y --no-install-recommends \
    bash ca-certificates curl wget git gnupg locate unzip\
    python3 python3-pip iproute2 iputils-ping nano tree\
    dnsutils net-tools procps locales tzdata ntpdate\
    less vim sudo openssh-client xclip\
    build-essential gcc libssl-dev libffi-dev \
    python3-dev \
    krb5-config libkrb5-dev libldap2-dev libsasl2-dev \
    samba-common-bin \
    && locale-gen en_US.UTF-8 \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

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

RUN apt-get update && apt-get install -y --no-install-recommends \
    zsh zsh-syntax-highlighting zsh-autosuggestions fzf \
    powerline fonts-powerline \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended && \
    git clone https://github.com/zsh-users/zsh-autosuggestions \
        ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions && \
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \
        ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

COPY install/common.sh /kon/install/common.sh
RUN chmod +x /kon/install/common.sh

COPY install/p_recon.sh /kon/install/p_recon.sh
RUN chmod +x /kon/install/p_recon.sh && apt-get update && bash -c 'source /kon/install/common.sh && source /kon/install/p_recon.sh && p_recon' && apt-get clean && rm -rf /var/lib/apt/lists/*

COPY install/p_wordlists.sh /kon/install/p_wordlists.sh
RUN chmod +x /kon/install/p_wordlists.sh && apt-get update && bash -c 'source /kon/install/common.sh && source /kon/install/p_wordlists.sh && p_wordlists' && apt-get clean && rm -rf /var/lib/apt/lists/*

COPY install/p_binaries.sh /kon/install/p_binaries.sh
RUN chmod +x /kon/install/p_binaries.sh && apt-get update && bash -c 'source /kon/install/common.sh && source /kon/install/p_binaries.sh && p_binaries' && apt-get clean && rm -rf /var/lib/apt/lists/*

COPY install/p_ad.sh /kon/install/p_ad.sh
RUN chmod +x /kon/install/p_ad.sh && apt-get update && bash -c 'source /kon/install/common.sh && source /kon/install/p_ad.sh && p_ad' && apt-get clean && rm -rf /var/lib/apt/lists/*

COPY install/p_web.sh /kon/install/p_web.sh
RUN chmod +x /kon/install/p_web.sh && apt-get update && bash -c 'source /kon/install/common.sh && source /kon/install/p_web.sh && p_web' && apt-get clean && rm -rf /var/lib/apt/lists/*

COPY install/p_infra.sh /kon/install/p_infra.sh
RUN chmod +x /kon/install/p_infra.sh && apt-get update && bash -c 'source /kon/install/common.sh && source /kon/install/p_infra.sh && p_infra' && apt-get clean && rm -rf /var/lib/apt/lists/*

COPY assets/ /kon/assets/
COPY assets/bin/ /opt/tools/bin/
RUN chmod +x /opt/tools/bin/*

COPY version/ /kon/version/

COPY runtime/ /kon/runtime/
COPY assets/zshrc-kon /root/.zshrc
ENV PATH="${PATH}:/root/.local/bin"

RUN find /kon -name "*.sh" -exec chmod +x {} \; && \
    mkdir -p /anvil /opt/tools/bin /opt/tools/src /opt/tools/forja \
             /usr/share/rules

RUN updatedb

WORKDIR /anvil
ENTRYPOINT ["/kon/runtime/init.sh"]
