#!/bin/bash
set -eux

config_domain=$(hostname --domain)
config_ip_address=$(hostname -I | awk '{print $2}')
config_satellite_ip_address=$1

# update the package cache.
apt-get update

#
# provision the DNS server.
# see http://www.thekelleys.org.uk/dnsmasq/docs/setup.html
# see http://www.thekelleys.org.uk/dnsmasq/docs/dnsmasq-man.html

default_dns_resolver=$(systemd-resolve --status | awk '/DNS Servers: /{print $3}') # recurse queries through the default vagrant environment DNS server.
apt-get install -y --no-install-recommends dnsutils dnsmasq
systemctl stop systemd-resolved
systemctl disable systemd-resolved
cat >/etc/dnsmasq.d/local.conf <<EOF
no-hosts
mx-host=$config_domain,mail.$config_domain
host-record=$config_domain,$config_ip_address
host-record=mail.$config_domain,$config_ip_address
host-record=satellite.$config_domain,$config_satellite_ip_address
server=$default_dns_resolver
EOF
rm /etc/resolv.conf
echo 'nameserver 127.0.0.1' >/etc/resolv.conf
echo 'dns-nameservers 127.0.0.1' >>/etc/network/interfaces
systemctl restart dnsmasq

# use it.
dig $config_domain
dig mx $config_domain
dig -x $config_ip_address
