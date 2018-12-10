#!/bin/bash
set -e

if [ ! -z "${WAIT_INT}" ]; then
  /usr/bin/pipework --wait -i ${WAIT_INT}
fi

USERNAME=${USERNAME:-user}
PASSWORD=${PASSWORD:-pass}
ALLOW=${ALLOW:-*}
VOLUME=${VOLUME:-/data}

if [ "$1" = 'rsync_server' ]; then

    if [ -e "/ssh/authorized_keys" ]; then
        cp /ssh/authorized_keys /root/.ssh/authorized_keys
        chmod 400 /root/.ssh/authorized_keys
        chown root:root /root/.ssh/authorized_keys
    fi
    exec /usr/sbin/sshd &

    echo "root:$PASSWORD" | chpasswd

    echo "$USERNAME:$PASSWORD" > /etc/rsyncd.secrets
    chmod 0400 /etc/rsyncd.secrets

    mkdir -p $VOLUME

    [ -f /etc/rsyncd.conf ] || cat <<EOF > /etc/rsyncd.conf
    pid file = /var/run/rsyncd.pid
    log file = /dev/stdout
    timeout = 300
    max connections = 10
    port = 873

    [data]
        uid = root
        gid = root
        hosts deny = *
        hosts allow = ${ALLOW}
        read only = false
        path = ${VOLUME}
        comment = ${VOLUME} directory
        auth users = ${USERNAME}
        secrets file = /etc/rsyncd.secrets
EOF

    exec /usr/bin/rsync --no-detach --daemon --config /etc/rsyncd.conf "$@"
fi

exec "$@"
