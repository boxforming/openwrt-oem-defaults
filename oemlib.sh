#!/bin/sh

. /lib/functions.sh
. /lib/functions/system.sh

get_model_name () {
	cat /proc/device-tree/compatible | tr -s '\000' '\n' | head -n 1
}

get_oem_data_parser () {
	local brd=$(get_model_name)
	brd=${brd//,/__}
	brd=${brd//\//_}
	echo "get_oem_data_${brd//-/_}"
}

get_mtd_cstr () {
	local mtdname="$1"
	local offset=$(($2))
	local limit=$((${3:-32}))
	local part
	local mac_dirty
	
	part=$(find_mtd_part "$mtdname")

	if [[ -z $part ]]; then
		echo "get_mtd_cstr: partition $mtdname not found!" >&2
		return
	fi

	if [[ -z $offset ]]; then
		echo "get_mtd_cstr: offset missing" >&2
		return
	fi

	cstring=$(dd if="$part" skip="$offset" count=1 bs="$limit" iflag=skip_bytes 2>/dev/null | tr -s '\000' '\n' | head -n1)

	echo $cstring
}

set_factory_root_password () {
	factory_root_password=$1
	root_shadow=$(cat /etc/shadow | grep '^root' | cut -d ':' -f 2)
	if [ "x$root_shadow" == "x" -a "x$factory_root_password" != "x" ] ; then
		echo -e "$factory_root_password\n$factory_root_password" | passwd root
	fi
}

get_device_oem_data () {

	model_name=$(get_model_name)

	local parser=$(get_oem_data_parser)

	if [[ $(type -t $parser || echo fail) != "$parser" ]] ; then
		. "/tmp/${model_name//\//-}.sh"
	fi

	set -e

	$parser

	set +e
}

apply_factory_defaults () {

	if [[ ! -z $wlan_ssid ]] && uci get "wireless.@wifi-device[${wlan_phy_id}]" && uci get "wireless.@wifi-device[${wlan_phy_id}].disabled" ; then
		uci -q batch << EOI
set wireless.@wifi-device[${wlan_phy_id}].disabled='0'
set wireless.@wifi-device[${wlan_phy_id}].country='${wlan_country}'

set wireless.@wifi-iface[${wlan_phy_id}].ssid='${wlan_ssid}'
set wireless.@wifi-iface[${wlan_phy_id}].encryption='${wlan_enc}'
set wireless.@wifi-iface[${wlan_phy_id}].key='${wlan_key}'
set wireless.@wifi-iface[${wlan_phy_id}].network='lan'

set wireless.@wifi-iface[${wlan_phy_id}].ieee80211r='1'
EOI
	fi

	if [[ ! -z $wlan_5ghz_ssid ]] && uci get "wireless.@wifi-device[${wlan_5ghz_phy_id}]" && uci get "wireless.@wifi-device[${wlan_5ghz_phy_id}].disabled" ; then
		uci -q batch << EOI
set wireless.@wifi-device[${wlan_5ghz_phy_id}].disabled='0'
set wireless.@wifi-device[${wlan_5ghz_phy_id}].country='${wlan_country}'

set wireless.@wifi-iface[${wlan_5ghz_phy_id}].ssid='${wlan_5ghz_ssid}'
set wireless.@wifi-iface[${wlan_5ghz_phy_id}].encryption='${wlan_5ghz_enc:-$wlan_enc}'
set wireless.@wifi-iface[${wlan_5ghz_phy_id}].key='${wlan_5ghz_key:-$wlan_key}'
set wireless.@wifi-iface[${wlan_5ghz_phy_id}].network='lan'

set wireless.@wifi-iface[${wlan_5ghz_phy_id}].ieee80211r='1'
EOI
	fi

	# uci commit wireless

	if [[ ! -z $root_password ]] ; then
		set_factory_root_password "$root_password"
	fi

	if [[ ! -z $hostname ]] ; then
		uci set system.@system[0].hostname="${hostname}"
		# uci commit system
		echo "${hostname}" > /proc/sys/kernel/hostname
		/etc/init.d/system restart
	fi


}


# we probably don't need that for 802.11r
# set wireless.@wifi-iface[${wlan_phy_id}].mobility_domain='fe24'
# set wireless.@wifi-iface[${wlan_phy_id}].ft_psk_generate_local='1'
# set wireless.@wifi-iface[${wlan_phy_id}].reassociation_deadline '20000'
# set wireless.@wifi-iface[${wlan_phy_id}].ft_over_ds '0'

info () {
	[ $VERBOSE ] && echo "$1"
}

insecure () {
	[ $VERBOSE ] && [ $INSECURE ] && echo "$1"
}

check_config () {

	set -u

	info "WiFi regulatory country/domain: ${wlan_country}"

	info "Model name: ${model_name}"

	insecure "Root password: ${root_password}"

	info "Hostname: ${hostname}"

	info "WiFi radio #${wlan_phy_id}:"
	info "WiFi SSID: ${wlan_ssid} [${wlan_enc}]"
	insecure "WiFi key: ${wlan_key}"

	if [[ ! -z $wlan_5ghz_ssid ]] ; then
		info "WiFi 5GHz radio #${wlan_5ghz_phy_id}"
		info "WiFi 5GHz SSID: ${wlan_5ghz_ssid} [${wlan_5ghz_enc:-$wlan_enc}]"
		insecure "WiFi 5GHz key: ${wlan_5ghz_key:-$wlan_key}"
	fi
	if [[ ! -z $serial_number ]] ; then
		info "Serial number: ${serial_number}"
	fi

	set +u

}
