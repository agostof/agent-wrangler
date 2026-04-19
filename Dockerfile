FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV PS1="[sandbox] \\u@\\h:\\w\\$ "

RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    ca-certificates \
    curl \
    git \
    gnupg \
    passwd \
    sudo \
    gosu \
    python3 \
    python3-pip \
    python3-venv \
    bubblewrap \
    nodejs \
    npm \
    ssh \
 && rm -rf /var/lib/apt/lists/*



# Install nvm globally, outside mounted home
ENV NVM_DIR=/usr/local/nvm
RUN mkdir -p "$NVM_DIR" \
 && curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash \
 && . "$NVM_DIR/nvm.sh" \
 && nvm install 22 \
 && nvm alias default 22 \
 && nvm use 22 \
 && node -v \
 && npm -v

# Make node/npm/npx available globally, even in non-interactive shells
ENV PATH=/usr/local/nvm/versions/node/v22.*/bin:$PATH

RUN usermod -l agent ubuntu \
 && groupmod -n agent ubuntu \
 && usermod -d /home/agent -m agent

RUN mkdir -p /work /projects /opt/agent
COPY docker-entrypoint.sh /opt/agent/docker-entrypoint.sh
RUN chmod +x /opt/agent/docker-entrypoint.sh

WORKDIR /work

ENTRYPOINT ["/opt/agent/docker-entrypoint.sh"]
CMD ["bash"]
