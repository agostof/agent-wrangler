#!/usr/bin/env bash
set -euo pipefail

TARGET_USER=agent
TARGET_GROUP=agent
TARGET_HOME=/home/${TARGET_USER}

HOST_UID="${LOCAL_UID:-1000}"
HOST_GID="${LOCAL_GID:-1000}"

CURRENT_UID="$(id -u "${TARGET_USER}")"
CURRENT_GID="$(id -g "${TARGET_USER}")"

# Remap group if needed (-o allows non-unique GID if a system group already uses HOST_GID)
if [ "${CURRENT_GID}" != "${HOST_GID}" ]; then
    groupmod -o -g "${HOST_GID}" "${TARGET_GROUP}" || true
    usermod -g "${HOST_GID}" "${TARGET_USER}" || true
fi

# Remap user if needed (-o allows non-unique UID if a system user already uses HOST_UID)
if [ "${CURRENT_UID}" != "${HOST_UID}" ]; then
    usermod -o -u "${HOST_UID}" -g "${HOST_GID}" "${TARGET_USER}" || true
fi

# Ensure sudo access
usermod -aG sudo "${TARGET_USER}"
echo "${TARGET_USER} ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/${TARGET_USER}"
chmod 0440 "/etc/sudoers.d/${TARGET_USER}"

mkdir -p /projects /work

# Create skeleton directories under /home/agent and fix top-level node ownership
# only if Docker created a missing mountpoint as root (UID 0).
for dir in \
    "${TARGET_HOME}" \
    "${TARGET_HOME}/.config" \
    "${TARGET_HOME}/.cache" \
    "${TARGET_HOME}/.local" \
    "${TARGET_HOME}/.local/share" \
    "${TARGET_HOME}/.local/state" \
    "${TARGET_HOME}/.local/bin" \
    "${TARGET_HOME}/.gemini" \
    /work; do
    mkdir -p "$dir"
    if [ "$(stat -c '%u' "$dir" 2>/dev/null)" = "0" ]; then
        chown "${HOST_UID}:${HOST_GID}" "$dir" || true
    fi
done

# Optional recursive chown flags (disabled by default to avoid touching host-mounted trees)
if [ "${CHOWN_AGENT_HOME:-false}" = "true" ] || [ "${CHOWN_AGENT_HOME:-0}" = "1" ]; then
    chown -R "${HOST_UID}:${HOST_GID}" "${TARGET_HOME}" || true
fi

if [ "${CHOWN_WORK:-false}" = "true" ] || [ "${CHOWN_WORK:-0}" = "1" ]; then
    chown -R "${HOST_UID}:${HOST_GID}" /work || true
fi

export HOME="${TARGET_HOME}"
export USER="${TARGET_USER}"
export LOGNAME="${TARGET_USER}"

if [ "$#" -eq 0 ]; then
    set -- bash
fi

exec gosu "${TARGET_USER}" "$@"
