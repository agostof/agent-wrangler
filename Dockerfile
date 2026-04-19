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
    ssh \
 && rm -rf /var/lib/apt/lists/*

# Install nvm globally, outside mounted home
ENV NVM_DIR=/usr/local/nvm
RUN mkdir -p "$NVM_DIR" \
 && export PROFILE=/dev/null \
 && curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash \
 && . "$NVM_DIR/nvm.sh" \
 && nvm install 22 \
 && nvm alias default 22 \
 && nvm use 22 \
 && NODE_BIN="$(find "$NVM_DIR/versions/node" -mindepth 2 -maxdepth 2 -type d -name bin | sort | tail -n1)" \
 && ln -sf "$NODE_BIN/node" /usr/local/bin/node \
 && ln -sf "$NODE_BIN/npm" /usr/local/bin/npm \
 && ln -sf "$NODE_BIN/npx" /usr/local/bin/npx \
 && node -v \
 && npm -v \
 && npx -v

# uncommet if an upgrade to NPM is needed
# RUN npm install -g npm@11 promise-retry

# Load nvm for interactive shells
RUN printf '%s\n' \
  'export NVM_DIR=/usr/local/nvm' \
  '[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"' \
  > /etc/profile.d/nvm.sh \
 && chmod 644 /etc/profile.d/nvm.sh

RUN usermod -l agent ubuntu \
 && groupmod -n agent ubuntu \
 && usermod -d /home/agent -m agent

RUN mkdir -p /work /projects /opt/agent
COPY docker-entrypoint.sh /opt/agent/docker-entrypoint.sh

COPY scripts/ /tmp/build-scripts/
RUN chmod +x /opt/agent/docker-entrypoint.sh \
 && find /tmp/build-scripts -maxdepth 1 -type f -name '*.sh' -exec chmod +x {} \; \
 && for f in /tmp/build-scripts/*.sh; do \
      [ -e "$f" ] || continue; \
      echo "Running $f"; \
      bash "$f"; \
    done \
 && rm -rf /tmp/build-scripts && rm -rfv /tmp/*

RUN PREFIX="$(npm config get prefix)" \
 && echo "export PATH=$PREFIX/bin:\$PATH" > /etc/profile.d/npm-global.sh \
 && chmod 644 /etc/profile.d/npm-global.sh

RUN PREFIX="$(npm config get prefix)" \
 && echo "export PATH=$PREFIX/bin:\$PATH" >> /etc/bash.bashrc

WORKDIR /work

ENTRYPOINT ["/opt/agent/docker-entrypoint.sh"]
CMD ["bash"]

