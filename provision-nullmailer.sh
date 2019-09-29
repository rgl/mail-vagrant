#!/bin/bash
set -eux

config_domain=$(hostname --domain)
config_fqdn=$(hostname --fqdn)
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

# trust the mail server CA.
cp /vagrant/shared/tls/example-ca/example-ca-crt.pem /usr/local/share/ca-certificates/example-ca.crt
openssl x509 -noout -text -in /usr/local/share/ca-certificates/example-ca.crt
update-ca-certificates -v

# install nullmailer
# see nullmailer-queue(8)
# see nullmailer-send(8)
# NB if you set adminaddr then all emails will be sent to that email address.
# NB these anwsers were obtained (after installing nullmailer) with:
#       #sudo debconf-show nullmailer
#       sudo apt-get install debconf-utils
#       # this way you can see the comments:
#       sudo debconf-get-selections
#       # this way you can just see the values needed for debconf-set-selections:
#       sudo debconf-get-selections | grep -E '^nullmailer\s+' | sort
debconf-set-selections <<EOF
nullmailer nullmailer/defaultdomain string $config_domain
nullmailer nullmailer/adminaddr string
nullmailer nullmailer/relayhost string $config_mail_server_fqdn smtp port=25 starttls user=relay-nullmailer@$config_domain pass=password
nullmailer shared/mailname string $config_domain
EOF
apt-get install -y --no-install-recommends nullmailer

# patch mailname because, for some reason, debconf set mailname is being ignored.
echo "$config_domain" >/etc/mailname
systemctl restart nullmailer

# send test email to root and grace.
sendmail root <<EOF
Subject: Hello World from $config_fqdn at `date --iso-8601=seconds`

Hello World!
EOF
echo '
check the root email account at the mail server machine
(inside /var/vmail/example.com/alice/new/) to see whether it
received an email from this nullmailer machine
'
sendmail grace <<EOF
Subject: Hello World from $config_fqdn at `date --iso-8601=seconds`

Hello World!
EOF
echo '
check the grace email account at the mail server machine
(inside /var/vmail/example.com/grace/new/) to see whether it
received an email from this nullmailer machine
'
