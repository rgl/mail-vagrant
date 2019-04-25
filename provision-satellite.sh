#!/bin/bash
set -eux

config_domain=$(hostname --domain)
config_mail_ip_address=$1

# update the package cache.
apt-get update

# install vim.
apt-get install -y --no-install-recommends vim
cat >/etc/vim/vimrc.local <<'EOF'
syntax on
set background=dark
set esckeys
set ruler
set laststatus=2
set nobackup
EOF

# change the dns resolver to the mail dns server.
mkdir -p /etc/systemd/resolved.conf.d
cat >/etc/systemd/resolved.conf.d/dns_servers.conf <<EOF
[Resolve]
DNS=$config_mail_ip_address
EOF
systemctl restart systemd-resolved

# install postfix in satellite mode.
#
# these anwsers were obtained (after installing postfix-cdb) with:
#
#   #sudo debconf-show postfix
#   sudo apt-get install debconf-utils
#   # this way you can see the comments:
#   sudo debconf-get-selections
#   # this way you can just see the values needed for debconf-set-selections:
#   sudo debconf-get-selections | grep -E '^postfix\s+' | sort
#
# NB The form [destination] in relayhost turns off MX lookups.
debconf-set-selections <<EOF
postfix postfix/main_mailer_type select Satellite system
postfix postfix/mailname string $config_domain
postfix postfix/relayhost string $config_domain
EOF
apt-get install -y --no-install-recommends postfix-cdb
postconf -e 'mydestination = '
postconf -e 'inet_protocols = ipv4'
systemctl reload postfix

# send test email.
sendmail root <<EOF
Subject: Hello World from `hostname --fqdn` at `date --iso-8601=seconds`

Hello World!
EOF
echo '
check the root email account at the mail server machine
(inside /var/vmail/example.com/alice/new/) to see whether it
received an email from this satellite machine
'
