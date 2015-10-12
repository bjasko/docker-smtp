#!/bin/sh

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

VOLUME_BASE=/data/zimbra
S_HOST=smtp
S_DEV=eth0
S_DOMAIN=bug.out.ba
S_HOST_IP=${smtp_ip:-192.168.168.45}
S_DNS_HOST_IP=${dns_lan_ip:-192.168.46.254}


msmtp_client=${msmtp_client:-no}

if [[ "$msmtp_client" == "yes" ]] ; then
   msmtp_vol="-v $(pwd)/msmtprc:/root/.msmtprc"
else
   msmtp_vol=""
fi

mynetworks=${mynetworks:-192.168.45.0/24 192.168.168.0/24 192.168.169.0/24}

is_relayhost=${is_relayhost:-no}
mailrelay=${mailrelay:-[smtp.bih.net.ba]:587}
smtp_user=${smtp_user:-bring.out}
smtp_password=${smtp_password:-test}
relay_domains="out.ba bring.out.ba rama-glas.com rama-glas.ba hano-bih.com hano.ba"
myvirtualdomains=${myvirtualdomains}
myvirtualmail=${myvirtualmail}

# deliver mail for kimtec.ba via smtp.bih.net.ba

transport="kimtec.ba#smtp:[smtp.bih.net.ba]:587
bih.net.ba#smtp:[smtp.bih.net.ba]:587
out.ba#smtp:[192.168.168.24]:25
bring.out.ba#smtp:[smtp-lan.bring.out.ba]:25
hano.ba#smtp:[mail.rama-glas.com]:25
hano-bih.com#smtp:[mail.rama-glas.com]:25
rama-glas.com#smtp:[mail.rama-glas.com]:25
rama-glas.ba#smtp:[mail.rama-glas.com]:25"

sudo ip addr show | grep $S_HOST_IP || \
  sudo ip addr add $S_HOST_IP/24 dev $S_DEV

docker rm -f $S_HOST.$S_DOMAIN

     
docker run -d \
     -v $VOLUME_BASE/$S_HOST.$S_DOMAIN/spool:/var/spool/postfix $msmtp_vol \
     --name $S_HOST.$S_DOMAIN \
     --hostname $S_HOST.$S_DOMAIN \
     --dns $S_DNS_HOST_IP \
     -p $S_HOST_IP:25:25  \
     -e is_relayhost=$is_relayhost \
     -e mailrelay=$mailrelay \
     -e myhostname=$S_HOST.$S_DOMAIN \
     -e mynetworks="$mynetworks" \
     -e myvirtualdomains="$myvirtualdomains" \
     -e myvirtualmail="$myvirtualmail" \
     -e smtp_user=$smtp_user -e smtp_password=$smtp_password \
     -e transport="$transport" -e relay_domains="$relay_domains" \
     -e smtp_ip=$S_HOST_IP \
     smtp
