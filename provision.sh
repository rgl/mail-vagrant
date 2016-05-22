#!/bin/bash
set -eux

config_domain=$(hostname --domain)

apt-get install -y --no-install-recommends vim
cat >/etc/vim/vimrc.local <<'EOF'
syntax on
set background=dark
set esckeys
set ruler
set laststatus=2
set nobackup
autocmd BufNewFile,BufRead Vagrantfile set ft=ruby
EOF

# install nginx to host the Thunderbird Autoconfiguration xml file.
# thunderbird will make a request alike:
#   GET /.well-known/autoconfig/mail/config-v1.1.xml?emailaddress=alice%40example.com
# see https://wiki.mozilla.org/Thunderbird:Autoconfiguration:ConfigFileFormat
# see https://developer.mozilla.org/en-US/docs/Mozilla/Thunderbird/Autoconfiguration
# see https://developer.mozilla.org/en-US/docs/Mozilla/Thunderbird/Autoconfiguration/FileFormat/HowTo
apt-get install -y --no-install-recommends nginx
cp -R /vagrant/public/{.well-known,*} /var/www/html
find /var/www/html \
    -type f \
    -not \( \
        -name '*.png' \
    \) \
    -exec sed -i -E "s,@@config_domain@@,$config_domain,g" {} \;

# send a test email from the command line.
echo Hello World | sendmail alice
# dump the received email directly from the server store.
sleep 2; cat /var/vmail/$config_domain/alice/new/*.mail

# send a test email from alice to bob.
python3 /var/www/html/examples/python/smtp/send-mail/example.py
# dump the received email directly from the server store.
sleep 2; cat /var/vmail/$config_domain/bob/new/*.mail

# send an authenticated test email from bob to alice.
python3 /var/www/html/examples/python/smtp/send-mail-with-authentication/example.py
# dump the received email directly from the server store.
sleep 2; cat /var/vmail/$config_domain/alice/new/*.mail

# list the messages on the alice imap account.
python3 /var/www/html/examples/python/imap/list-mail/example.py

# print software versions.
dpkg-query -f '${Package} ${Version}\n' -W pdns-server
dpkg-query -f '${Package} ${Version}\n' -W postfix
dpkg-query -f '${Package} ${Version}\n' -W dovecot-imapd

# list the DNS zone.
pdnsutil list-all-zones
pdnsutil check-zone $config_domain
pdnsutil list-zone $config_domain

# query for all records.
dig any $config_domain
dig any ruilopes.com
