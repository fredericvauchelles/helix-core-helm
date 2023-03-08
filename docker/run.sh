#!/usr/bin/with-contenv bash
set -e

# File secrets supersedes env variables secrets
[ -e /etc/helix-core-secret/superuser ] && export P4USER=$(cat /etc/helix-core-secret/superuser);
[ -e /etc/helix-core-secret/superpassword ] && export P4PASSWD=$(cat /etc/helix-core-secret/superpassword);

export NAME="${NAME:-p4depot}"

bash /usr/local/bin/setup-helix-core.sh

sleep 2

exec /usr/bin/tail --pid=$(cat /var/run/p4d.$NAME.pid) -F "$DATAVOLUME/$NAME/logs/log"