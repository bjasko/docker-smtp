#!/bin/bash

postconf -e myhostname=$myhostname
postconf -F '*/*/chroot = n'

if [[ "$is_relayhost" == "yes" ]] ; then
   postconf -e relayhost=$mailrelay
fi

postconf -e smtp_sasl_auth_enable=yes
postconf -e smtp_sasl_security_options=
postconf -e mydestination="$myhostname, localhost.localdomain, localhost"
postconf -e mynetworks="$mynetworks 127.0.0.0/8 [::1]/128 [fe80::]/64"

postconf -e smtp_sasl_password_maps=hash:/etc/postfix/sasl_passwd
postconf -e transport_maps=hash:/etc/postfix/transport
postconf -e relay_domains=hash:/etc/postfix/relay_domains
#postconf -e  check_sender_access=hash:/etc/postfix/senders

postconf -e smtpd_client_restrictions="permit_mynetworks reject_unknown_helo_hostname reject_unauth_destination"
postconf -e smtpd_sender_restrictions="reject_unknown_sender_domain"

if [[ ! -z $myvirtualmail ]]; then
  postconf -e "virtual_alias_maps=hash:/etc/postfix/virtual"
  postconf -e "virtual_mailbox_domains=$myvirtualdomains" 
  postconf -e smtpd_client_restrictions="permit_mynetworks reject_unauth_destination"
  echo setup virtual maps
  echo "$myvirtualmail" > /etc/postfix/virtual
  postmap /etc/postfix/virtual
fi


if [[ ! -z $mailrelay ]] ; then
  echo setup sasl_passwd
  echo "$mailrelay $smtp_user:$smtp_password" > /etc/postfix/sasl_passwd
  postmap /etc/postfix/sasl_passwd
fi

echo setup relay_domains
rm /etc/postfix/relay_domains
for r in $relay_domains ; do
  echo $r RELAY >> /etc/postfix/relay_domains
done
postmap /etc/postfix/relay_domains

echo setup transport for domains
#bring.out.ba smtp:[smtp.bring.out.ba]:25
rm /etc/postfix/transport
for t in $transport ; do
   domain=`echo $t | awk -F '#' '{print $1}'`
   server=`echo $t | awk -F '#' '{print $2}'`
    
   echo "$domain =>  $server"
   echo "$domain  $server" >> /etc/postfix/transport
done
postmap /etc/postfix/transport

chown postfix:postfix /var/spool/postfix
touch /var/log/mail.log
postfix reload
