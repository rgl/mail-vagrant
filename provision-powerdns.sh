#!/bin/bash
set -eux

config_domain=$(hostname --domain)
config_ip_address=$(hostname -I | awk '{print $2}')

apt-get install -y --no-install-recommends dnsutils

# these anwsers were obtained (after installing pdns-backend-sqlite3) with:
#
#   #sudo debconf-show pdns-backend-sqlite3
#   sudo apt-get install debconf-utils
#   # this way you can see the comments:
#   sudo debconf-get-selections
#   # this way you can just see the values needed for debconf-set-selections:
#   sudo debconf-get-selections | grep -E '^pdns-.+\s+' | sort
debconf-set-selections<<EOF
pdns-backend-sqlite3 pdns-backend-sqlite3/dbconfig-install boolean true
EOF

apt-get install -y --no-install-recommends pdns-backend-sqlite3

# stop pdns before changing the configuration.
systemctl stop pdns

function pdns-set-config {
    local key=$1; shift
    local value=$1; shift
    sed -i -E "s,^(\s*#\s*)?($key\s*)=.+,\2=$value," /etc/powerdns/pdns.conf
}

# recurse queries through the default vagrant environment DNS server.
pdns-set-config recursor 10.0.2.2
# increase the logging level.
# you can see the logs with journalctl --follow -u pdns
#pdns-set-config loglevel 10
#pdns-set-config log-dns-queries yes

# load the $config_domain zone into the database.
zone="
\$TTL 10m
\$ORIGIN $config_domain. ; base domain-name
@               IN      SOA     a.ns    hostmaster (
    2008042800 ; serial number (this number should be increased each time this zone file is changed)
    10m        ; refresh (the polling interval that slave DNS server will query the master for zone changes)
               ; NB the slave will use this value insted of \$TTL when deciding if the zone it outdated
    15m        ; update retry (the slave will retry a zone transfer after a transfer failure)
    3w         ; expire (the slave will ignore this zone if the transfer keeps failing for this long)
    10m        ; minimum (the slave stores negative results for this long)
)
                IN      NS      a.ns
                IN      MX      10 mail
                IN      A       $config_ip_address
mail            IN      A       $config_ip_address
a.ns            IN      A       $config_ip_address
"
zone2sql --zone=<(echo "$zone") --gsqlite | sqlite3 /var/lib/powerdns/pdns.sqlite3

# configure the system resolver to use the local pdns server.
echo 'nameserver 127.0.0.1' >/etc/resolv.conf
echo 'dns-nameservers 127.0.0.1' >>/etc/network/interfaces

# start it up.
systemctl start pdns
