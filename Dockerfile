FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    gnupg \
    python3 \
    python3-pip \
    python3-venv \
    bubblewrap \
    git \
    xz-utils \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js 20.x from NodeSource
RUN mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key \
       | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" \
       > /etc/apt/sources.list.d/nodesource.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends nodejs \
    && rm -rf /var/lib/apt/lists/*

RUN usermod -l agent ubuntu \
 && groupmod -n agent ubuntu \
 && usermod -d /home/agent -m agent

ENV PS1="[sandbox] \\u@\\h:\\w\\$ "

#RUN useradd -m -u 1000 agent
#USER agentuser
WORKDIR /work

CMD ["bash"]

