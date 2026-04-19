#!/usr/bin/env bash
set -euo pipefail

TARGET_USER=agent
TARGET_GROUP=agent
TARGET_HOME=/home/${TARGET_USER}

HOST_UID="${LOCAL_UID:-1000}"
HOST_GID="${LOCAL_GID:-1000}"

CURRENT_UID="$(id -u "${TARGET_USER}")"
CURRENT_GID="$(id -g "${TARGET_USER}")"

# Remap group if needed
if [ "${CURRENT_GID}" != "${HOST_GID}" ]; then
    if getent group "${HOST_GID}" >/dev/null 2>&1; then
        EXISTING_GROUP="$(getent group "${HOST_GID}" | cut -d: -f1)"
        usermod -g "${HOST_GID}" "${TARGET_USER}" || true
        if [ "${EXISTING_GROUP}" != "${TARGET_GROUP}" ]; then
            groupmod -n "${TARGET_GROUP}" "${EXISTING_GROUP}" || true
        fi
    else
        groupmod -g "${HOST_GID}" "${TARGET_GROUP}" || true
        usermod -g "${HOST_GID}" "${TARGET_USER}" || true
    fi
fi

# Remap user if needed
if [ "${CURRENT_UID}" != "${HOST_UID}" ]; then
    if getent passwd "${HOST_UID}" >/dev/null 2>&1; then
        EXISTING_USER="$(getent passwd "${HOST_UID}" | cut -d: -f1)"
        usermod -l "${TARGET_USER}" "${EXISTING_USER}" || true
        usermod -d "${TARGET_HOME}" -m "${TARGET_USER}" || true
        usermod -u "${HOST_UID}" "${TARGET_USER}" || true
    else
        usermod -u "${HOST_UID}" "${TARGET_USER}" || true
    fi
fi

# Ensure sudo access
usermod -aG sudo "${TARGET_USER}"
echo "${TARGET_USER} ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/${TARGET_USER}"
chmod 0440 "/etc/sudoers.d/${TARGET_USER}"

mkdir -p "${TARGET_HOME}" \
         "${TARGET_HOME}/.config" \
         "${TARGET_HOME}/.cache" \
         "${TARGET_HOME}/.local/share" \
         "${TARGET_HOME}/.local/state" \
         /work \
         /projects

chown -R "${HOST_UID}:${HOST_GID}" "${TARGET_HOME}" || true

export HOME="${TARGET_HOME}"
export USER="${TARGET_USER}"
export LOGNAME="${TARGET_USER}"

if [ "$#" -eq 0 ]; then
    set -- bash
fi

exec gosu "${TARGET_USER}" "$@"

