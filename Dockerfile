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

RUN usermod -l agent ubuntu \
 && groupmod -n agent ubuntu \
 && usermod -d /home/agent -m agent

RUN mkdir -p /work /projects /opt/agent
COPY docker-entrypoint.sh /opt/agent/docker-entrypoint.sh
RUN chmod +x /opt/agent/docker-entrypoint.sh

WORKDIR /work

ENTRYPOINT ["/opt/agent/docker-entrypoint.sh"]
CMD ["bash"]
