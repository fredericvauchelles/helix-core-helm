#!/bin/bash

# Expected files:
# /etc/helix-core-secret/superusername: perforce username with super privileges
# /etc/helix-core-secret/superpassword: password for superuser

# Required environment variables:
# P4PORT: perforce server port
# P4ROOT: root directory of helix server
# NAME: (Optional) name of the service, defaults to p4depot

set -e

export NAME=${NAME:-p4depot};
export DATAVOLUME=/helix-core
export P4USER=$(cat /etc/helix-core-secret/superusername);
export P4PASSWD=$(cat /etc/helix-core-secret/superpassword);

# Relinking /etc/perforce
if [ ! -d $DATAVOLUME/etc ]; then
    echo >&2 "First time installation, copying configuration from /etc/perforce to $DATAVOLUME/etc and relinking"
    mkdir -p $DATAVOLUME/etc
    cp -r /etc/perforce/* $DATAVOLUME/etc/
    FRESHINSTALL=1
fi
mv /etc/perforce /etc/perforce.orig
ln -s $DATAVOLUME/etc /etc/perforce

# This is hardcoded in configure-helix-p4d.sh :(
P4SSLDIR="$P4ROOT/ssl"

# Update right for $P4SSLDIR
for DIR in $P4ROOT $P4SSLDIR; do
    mkdir -m 0700 -p $DIR
    chown perforce:perforce $DIR
done

# Initialize perforce if required
if ! p4dctl list 2>/dev/null | grep -q $NAME; then
    /opt/perforce/sbin/configure-helix-p4d.sh ${NAME} -n -p ${P4PORT} -r ${P4ROOT} -u $P4USER -P $P4PASSWD --unicode --case 0
    touch /helix-core/configure-helix-core
fi

# Initialize p4d service
p4dctl start -t p4d $NAME
if echo "$P4PORT" | grep -q '^ssl:'; then
    p4 trust -y
fi

# Update .p4config
cat > ~perforce/.p4config <<EOF
P4USER=$P4USER
P4PORT=$P4PORT
P4PASSWD=$P4PASSWD
EOF
chmod 0600 ~perforce/.p4config
chown perforce:perforce ~perforce/.p4config

# Get login ticket
p4 login <<EOF
$P4PASSWD
EOF

if [ "$FRESHINSTALL" = "1" ]; then
    ## Load up the default tables
    echo >&2 "First time installation, setting up defaults for p4 user, group and protect tables"
    sed "s/P4USER/$P4USER/" /root/p4-users.txt | p4 user -i
    sed "s/P4USER/$P4USER/" /root/p4-groups.txt | p4 group -i
    sed "s/P4USER/$P4USER/" /root/p4-protect.txt | p4 protect -i
fi

echo "   P4USER=$P4USER (the admin user)"

if [ "$P4PASSWD" == "pass12349ers!" ]; then
    echo -e "\n***** WARNING: USING DEFAULT PASSWORD ******\n"
    echo "Please change as soon as possible:"
    echo "   P4PASSWD=$P4PASSWD"
    echo -e "\n***** WARNING: USING DEFAULT PASSWORD ******\n"
fi

for i in `seq 20`; do
    test -e /var/run/p4d.${NAME}.pid && break
    echo "Wait p4d to start"
    sleep 2
done
tail --pid=$(cat /var/run/p4d.${NAME}.pid) -f /helix-core/logs/*