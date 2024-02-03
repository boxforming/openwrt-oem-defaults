#!/bin/sh

. /lib/functions.sh
. /lib/functions/system.sh

### placeholder ###

# uncomment lines below and provide proper values:
wlan_country="US"
wlan_enc="psk2"

apply_factory_defaults

if [[ -n $hostname ]] ; then
    uci set system.@system[0].hostname="${hostname}"
    # uci commit system
    echo "${hostname}" > /proc/sys/kernel/hostname
    /etc/init.d/system restart
fi

if [[ -f /usr/bin/wireguard_watchdog ]] ; then
    echo '* * * * * /usr/bin/wireguard_watchdog' >> /etc/crontabs/root
fi

# your custom commands