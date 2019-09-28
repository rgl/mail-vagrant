#!/bin/bash
set -eux

config_domain=$(hostname --domain)
config_mail_server_fqdn="${1:-mail.example.com}"; shift || true
config_dns_server_ip_address="${1:-192.168.33.254}"; shift || true

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
DNS=$config_dns_server_ip_address
EOF
systemctl restart systemd-resolved

# import the mail server certificate.
cp /vagrant/shared/$config_mail_server_fqdn-crt.pem /usr/local/share/ca-certificates/$config_mail_server_fqdn.crt
openssl x509 -noout -text -in /usr/local/share/ca-certificates/$config_mail_server_fqdn.crt
update-ca-certificates -v

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
# NB addresses of the form [destination] are used to turn off MX lookups.
debconf-set-selections <<EOF
postfix postfix/main_mailer_type select Satellite system
postfix postfix/mailname string $config_domain
postfix postfix/relayhost string [$config_mail_server_fqdn]
EOF
apt-get install -y --no-install-recommends postfix-cdb

# tidy configuration.
postconf -e 'mydestination = '
postconf -e 'inet_protocols = ipv4'

# configure relay.
# NB addresses of the form [destination] are used to turn off MX lookups.
cat >/etc/postfix/sasl_passwd <<EOF
[$config_mail_server_fqdn] relay-satellite@$config_domain:password
EOF
chmod 600 /etc/postfix/sasl_passwd
postmap cdb:/etc/postfix/sasl_passwd # (re)creates /etc/postfix/sasl_passwd.cdb
postconf -e 'smtp_sasl_password_maps = cdb:/etc/postfix/sasl_passwd'
postconf -e 'smtp_sasl_auth_enable = yes'
postconf -e 'smtp_sasl_security_options = noanonymous'
postconf -e 'smtp_use_tls = yes'
postconf -e 'smtp_tls_security_level = secure'
postconf -e 'smtp_tls_CAfile = /etc/ssl/certs/ca-certificates.crt'

# reload configuration.
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
