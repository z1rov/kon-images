FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive \
    KON_HOME=/kon \
    KON_ANVIL=/anvil \
    TERM=xterm-256color \
    SHELL=/bin/bash \
    LANG=en_US.UTF-8 \
    GOPATH="/root/go" \
    PATH="${PATH}:/usr/local/go/bin:/root/go/bin:/opt/tools/bin:/usr/local/bin"

#Layer 1: Base APT packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash ca-certificates curl wget git gnupg locate unzip\
    python3 python3-pip iproute2 iputils-ping nano tree\
    dnsutils net-tools procps locales tzdata ntpdate\
    less vim sudo openssh-client \
    build-essential gcc libssl-dev libffi-dev \
    python3-dev \
    krb5-config libkrb5-dev libldap2-dev libsasl2-dev \
    samba-common-bin \
    && locale-gen en_US.UTF-8 \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

#Layer 2: Install Go 1.23.5
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

#Layer 3: ZSH and shell tooling
RUN apt-get update && apt-get install -y --no-install-recommends \
    zsh zsh-syntax-highlighting zsh-autosuggestions fzf \
    powerline fonts-powerline \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

#Layer 4: Oh My Zsh and plugins
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended && \
    git clone https://github.com/zsh-users/zsh-autosuggestions \
        ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions && \
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \
        ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

#Layer 5: Copy common.sh
COPY install/common.sh /kon/install/common.sh
RUN chmod +x /kon/install/common.sh

#Layer 6: Run package_recon
#COPY install/package_recon.sh /kon/install/package_recon.sh
#RUN chmod +x /kon/install/package_recon.sh && \
#   apt-get update && \
#   bash -c 'source /kon/install/common.sh && \
#            source /kon/install/package_recon.sh && \
#            package_recon' && \
#   apt-get clean && rm -rf /var/lib/apt/lists/*

#Layer 7: Run package_wordlists
#COPY install/package_wordlists.sh /kon/install/package_wordlists.sh
#RUN chmod +x /kon/install/package_wordlists.sh && \
#    apt-get update && \
#    bash -c 'source /kon/install/common.sh && \
#             source /kon/install/package_wordlists.sh && \
#             package_wordlists' && \
#    apt-get clean && rm -rf /var/lib/apt/lists/*

#Layer 11: Run package_binaries
COPY install/package_binaries.sh /kon/install/package_binaries.sh
RUN chmod +x /kon/install/package_binaries.sh && \
     apt-get update && \
     bash -c 'source /kon/install/common.sh && \
              source /kon/install/package_binaries.sh && \
              package_binaries' && \
     apt-get clean && rm -rf /var/lib/apt/lists/*

#Layer 8: Run package_ad
#COPY install/package_ad.sh /kon/install/package_ad.sh
#RUN chmod +x /kon/install/package_ad.sh && \
#    apt-get update && \
#    bash -c 'source /kon/install/common.sh && \
#              source /kon/install/package_ad.sh && \
#             package_ad' && \
#    apt-get clean && rm -rf /var/lib/apt/lists/*

#Layer 9: Run package_infra
COPY install/package_infra.sh /kon/install/package_infra.sh
RUN chmod +x /kon/install/package_infra.sh && \
     apt-get update && \
     bash -c 'source /kon/install/common.sh && \
              source /kon/install/package_infra.sh && \
              package_infra' && \
     apt-get clean && rm -rf /var/lib/apt/lists/*

#Layer 10: Run package_web
#COPY install/package_web.sh /kon/install/package_web.sh
#RUN chmod +x /kon/install/package_web.sh && \
#     apt-get update && \
#     bash -c 'source /kon/install/common.sh && \
#              source /kon/install/package_web.sh && \
#              package_web' && \
#     apt-get clean && rm -rf /var/lib/apt/lists/*

#Layer 11: Copy assets and version
COPY assets/ /kon/assets/
COPY version/ /kon/version/

#Layer 12: Copy runtime and zshrc
COPY runtime/ /kon/runtime/
COPY assets/zshrc-kon /root/.zshrc
ENV PATH="${PATH}:/root/.local/bin"

#Layer 13: Set final permissions
RUN find /kon -name "*.sh" -exec chmod +x {} \; && \
    mkdir -p /anvil /opt/tools/bin /opt/tools/src /opt/tools/forja \
             /usr/share/wordlists /usr/share/rules

WORKDIR /anvil
ENTRYPOINT ["/kon/runtime/init.sh"]
