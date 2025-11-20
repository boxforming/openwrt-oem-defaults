
apply_factory_defaults

if [[ -n $hostname ]] ; then
    uci set system.@system[0].hostname="${hostname}"
    # uci commit system
    echo "${hostname}" > /proc/sys/kernel/hostname
    /etc/init.d/system restart
fi # $hostname

if [[ -f /usr/bin/wireguard_watchdog ]] ; then
    echo '* * * * * /usr/bin/wireguard_watchdog' >> /etc/crontabs/root
fi

if [[ -n $ipv4_address ]] ; then
	uci set network.lan.ipaddr="$ipv4_address"
	uci set network.lan.netmask="${ipv4_netmask:-255.255.255.0}"
	uci commit network
	/etc/init.d/network restart
fi # $ipv4_address

if [[ -n $timezone ]] ; then
    uci set system.@system[0].timezone="$timezone"
    if [[ -n $timezonename ]] ; then
        uci set system.@system[0].zonename="$timezonename"
    fi
fi # $timezone



# your custom commands
