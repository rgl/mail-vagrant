#!/bin/bash
set -eux

config_domain=$(hostname --domain)

# these anwsers were obtained (after installing postfix-cdb) with:
#
#   #sudo debconf-show postfix
#   sudo apt-get install debconf-utils
#   # this way you can see the comments:
#   sudo debconf-get-selections
#   # this way you can just see the values needed for debconf-set-selections:
#   sudo debconf-get-selections | grep -E '^postfix\s+' | sort
debconf-set-selections<<EOF
postfix postfix/main_mailer_type select Internet Site
postfix postfix/mailname string $config_domain
EOF

apt-get install -y --no-install-recommends postfix-cdb

# stop postfix before we configure it.
systemctl stop postfix

# add the user that will manage all the virtual mailboxes.
addgroup vmail
adduser --disabled-login --ingroup vmail --no-create-home --home /var/vmail --gecos '' vmail
# create the virtual mailboxes store.
# NB Postfix will automatically create the needed directories/files/maildirs under /var/vmail.
install -d -o vmail -g vmail -m 700 /var/vmail

# set virtual domains.
cat >/etc/postfix/virtual_mailbox_domains <<EOF
$config_domain                  20080428
EOF

# mailboxes.
mailboxes='
alice
bob
carol
dave
eve
frank
grace
henry
'

# set controlled envelope senders.
for mailbox in $mailboxes; do
cat >>/etc/postfix/controlled_envelope_senders <<EOF
$mailbox@$config_domain         $mailbox@$config_domain
EOF
done

# set physical mailboxes.
for mailbox in $mailboxes; do
cat >>/etc/postfix/virtual_mailbox_maps <<EOF
$mailbox@$config_domain         $config_domain/$mailbox/
EOF
done

# set aliases.
cat >/etc/postfix/virtual_alias_maps <<EOF
root@$config_domain             alice@$config_domain
abuse@$config_domain            alice@$config_domain
postmaster@$config_domain       alice@$config_domain
hostmaster@$config_domain       alice@$config_domain
mailer-daemon@$config_domain    alice@$config_domain
EOF

# rebuild the maps.
postmap cdb:/etc/postfix/controlled_envelope_senders    # (re)creates /etc/postfix/controlled_envelope_senders.cdb
postmap cdb:/etc/postfix/virtual_mailbox_domains        # (re)creates /etc/postfix/virtual_mailbox_domains.cdb
postmap cdb:/etc/postfix/virtual_mailbox_maps           # (re)creates /etc/postfix/virtual_mailbox_maps.cdb
postmap cdb:/etc/postfix/virtual_alias_maps             # (re)creates /etc/postfix/virtual_alias_maps.cdb

# update postfix configuration.
postconf -e 'compatibility_level = 2'
postconf -e 'mydestination = localhost'
postconf -e 'smtpd_sender_login_maps = cdb:/etc/postfix/controlled_envelope_senders'
postconf -e 'virtual_mailbox_domains = cdb:/etc/postfix/virtual_mailbox_domains'
postconf -e 'virtual_mailbox_maps = cdb:/etc/postfix/virtual_mailbox_maps'
postconf -e 'virtual_alias_maps = cdb:/etc/postfix/virtual_alias_maps'
postconf -e 'virtual_mailbox_base = /var/vmail'
postconf -e 'virtual_minimum_uid = 1000'
postconf -e "virtual_uid_maps = static:`id -u vmail`"
postconf -e "virtual_gid_maps = static:`id -g vmail`"
postconf -e 'smtpd_banner = $myhostname ESMTP'
postconf -e 'smtpd_sasl_authenticated_header = yes'
cat <<'EOF' >>/etc/postfix/main.cf
smtpd_sender_restrictions =
    reject_non_fqdn_sender,
    reject_unknown_sender_domain,
    permit_sasl_authenticated,
    reject

smtpd_recipient_restrictions =
    reject_non_fqdn_recipient,
    reject_invalid_hostname,
    reject_unauth_destination,
    reject_sender_login_mismatch,
    permit_mynetworks,
    permit_sasl_authenticated,
    reject_unknown_client

smtpd_data_restrictions =
    reject_multi_recipient_bounce

strict_rfc821_envelopes = yes
smtpd_helo_required = yes
disable_vrfy_command = yes
EOF

# start postfix.
systemctl start postfix
