#!/bin/sh -x

printenv

if [ "x${SP_HOSTNAME}" = "x" ]; then
   SP_HOSTNAME="`hostname`"
fi

if [ "x${SP_CONTACT}" = "x" ]; then
   SP_CONTACT="info@${SP_HOSTNAME}"
fi

if [ "x${SP_ABOUT}" = "x" ]; then
   SP_ABOUT="/about"
fi

if [ "x${SP_METADATAFEED}" = "x" ]; then
   SP_METADATAFEED="http://mds.swamid.se/"
fi

if [ "x${DEFAULT_LOGIN}" = "x" ]; then
   DEFAULT_LOGIN="seamless-access" 
fi

export KEYDIR=/etc/shibboleth/certs
if [ ! -f "$KEYDIR/sp-signing-key.pem" -o ! -f "$KEYDIR/sp-encrypt-key.pem" ]; then
	shib-keygen -o $KEYDIR -n sp-signing
	shib-keygen -o $KEYDIR -n sp-encrypt
fi

envsubst < /tmp/shibboleth2.xml > /etc/shibboleth/shibboleth2.xml
augtool -s --noautoload --noload <<EOF
set /augeas/load/xml/lens "Xml.lns"
set /augeas/load/xml/incl "/etc/shibboleth/shibboleth2.xml"
load
defvar si /files/etc/shibboleth/shibboleth2.xml/SPConfig/ApplicationDefaults/Sessions/SessionInitiator[#attribute/id="$DEFAULT_LOGIN"]
set \$si/#attribute/isDefault "true"
EOF


echo "----"
cat /etc/shibboleth/shibboleth2.xml
echo "----"
cat /etc/apache2/sites-available/default-ssl.conf

if [ ! -f "/etc/dehydrated/cert.pem" -o ! -f "/etc/dehydrated/privkey.pem" ]; then
	echo "Can't find cert.pem and privkey.pem in /etc/dehydrated"
fi

service shibd start &
rm -f /var/run/apache2/apache2.pid
a2enmod rewrite
env APACHE_LOCK_DIR=/var/lock/apache2 APACHE_RUN_DIR=/var/run/apache2 APACHE_PID_FILE=/var/run/apache2/apache2.pid APACHE_RUN_USER=www-data APACHE_RUN_GROUP=www-data APACHE_LOG_DIR=/var/log/apache2 apache2 -DFOREGROUND
