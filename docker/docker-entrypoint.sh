#!/usr/bin/env bash

set -eo pipefail

# We set the bind address here to ensure HiveMQ uses the correct interface. Defaults to using the container hostname (which should be hardcoded in /etc/hosts)
if [[ -z "${HIVEMQ_BIND_ADDRESS}" ]]; then
    echo "Getting bind address from container hostname"
    HIVEMQ_BIND_ADDRESS=$(getent hosts ${HOSTNAME} | grep -v 127.0.0.1 | awk '{ print $1 }' | head -n 1)
    export HIVEMQ_BIND_ADDRESS
else
    echo "HiveMQ bind address was overridden by environment variable (value: ${HIVEMQ_BIND_ADDRESS})"
fi

# Remove allow all extension if applicable
if [[ "${HIVEMQ_ALLOW_ALL_CLIENTS}" != "true" ]]; then
    echo "Disabling allow all extension"
    rm -rf /opt/hivemq/extensions/hivemq-allow-all-extension &>/dev/null || true
fi

echo "setting bind address to ${HIVEMQ_BIND_ADDRESS}"

# Step down from root privilege, only when we're attempting to run HiveMQ though.
if [[ "$1" = "/opt/hivemq/bin/run.sh" && "$(id -u)" = '0' && "${HIVEMQ_NO_ROOT_STEP_DOWN}" != "true" ]]; then
    uid="hivemq"
    gid="hivemq"
    exec_cmd="exec chroot --skip-chdir --userspec=hivemq /"
else
    uid="$(id -u)"
    gid="$(id -g)"
    exec_cmd="exec"
fi

readonly uid
readonly gid
readonly exec_cmd

if [[ "$(id -u)" = "0" ]]; then
    find /opt \! -user "${uid}" -exec chown "${uid}" '{}' + || true
fi

${exec_cmd} "$@"
