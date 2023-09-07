#!/bin/sh

. /lib/functions.sh
. /lib/functions/system.sh

get_model_name () {
	cat /proc/device-tree/compatible | tr -s '\000' '\n' | head -n 1
}

get_parser_fn () {
	local brd=$(get_model_name)
	local brdm=${brd//,/__}
	echo "${brdm//-/_}"
}

get_mtd_cstr () {
	local mtdname="$1"
	local offset=$(($2))
	local part
	local mac_dirty
	
	part=$(find_mtd_part "$mtdname")

	if [ -z "$part" ]; then
		echo "get_mtd_cstr: partition $mtdname not found!" >&2
		return
	fi

	if [ -z "$offset" ]; then
		echo "get_mtd_cstr: offset missing" >&2
		return
	fi

	cstring=$(dd if="$part" skip="$offset" count=1 bs=32b iflag=skip_bytes 2>/dev/null | tr -s '\000' '\n' | head -n1)

	echo $cstring
}

set_factory_root_password () {
	factory_root_password=$1
	root_shadow=$(cat /etc/shadow | grep '^root' | cut -d ':' -f 2)
	if [ "x$root_shadow" == "x" -a "x$factory_root_password" != "x" ] ; then
		echo -e "$factory_root_password\n$factory_root_password" | passwd root
	fi
}

check_config () {
	local verbose=${1}
	wlan_country="JP"
	wlan_enc="psk2"

	local model_name=$(get_model_name)
	local parser=$(get_parser_fn)

	[ $verbose ] && echo "Model name: ${model_name}"

	. "/tmp/${model_name}.sh"

	[ $verbose ] && echo "Parser function name: ${parser}"

	set -e

	$parser

	[ $verbose ] && echo "Hostname: ${hostname}"
	[ $verbose ] && echo "WiFi 2.4GHz radio #${wlan_phy_id}"
	[ $verbose ] && echo "WiFi 2.4GHz SSID: ${wlan_ssid}"
	if [[ ! -z "${wlan_5ghz_ssid}" ]] ; then
		[ $verbose ] && echo "WiFi 5GHz radio #${wlan_5ghz_phy_id}"
		[ $verbose ] && echo "WiFi 5GHz SSID: ${wlan_5ghz_ssid}"
	fi
	if [[ ! -z "${serial_number}" ]] ; then
		[ $verbose ] && echo "Serial number: ${serial_number}"
	fi

    if [[ -z $hostname || -z $wlan_ssid || -z $wlan_phy_id || -z $wlan_key || -z $root_password ]] ; then
        echo "Some requires variables are not defined"
        exit 1
    fi

    if [[ ! -z $wlan_5ghz_ssid ]] ; then
        if [[ -z $wlan_5ghz_phy_id ]] ; then
            echo "Some requires variables are not defined"
            exit 2
        fi
    fi

}


show_config () {
	local model_name=$(get_model_name)
	local parser=$(get_parser_fn)

	echo "Model name: ${model_name}"

	. "/tmp/${model_name}.sh"

	echo "Parser function name: ${parser}"

	set -e

	$parser

	echo "Hostname: ${hostname}"
	echo "WiFi SSID: ${wlan_ssid}"
	if [[ ! -z "${wlan_5ghz_ssid}" ]] ; then
		echo "WiFi 5GHz SSID: ${wlan_5ghz_ssid}"
	fi
	if [[ ! -z "${serial_number}" ]] ; then
		echo "Serial number: ${serial_number}"
	fi
}

get_device_config () {

	model_name=$(get_model_name)

	. "/tmp/${model_name}.sh"

	local parser=$(get_parser_fn)

	$parser
}

apply_factory_defaults_ () {
	wlan_country="JP"
	wlan_enc="psk2"
	wlan_2ghz_id=0
	wlan_5ghz_id=1

	local model_name=$(get_model_name)

	local parser=$(get_parser_fn)

	case $board in
	beeline,smartbox-turbo-plus)
		
		wlan_ssid=$(mtd_get_cstring factory 0x21080)
		if [ "$wlan_ssid" != "${wlan_ssid#Beeline}" ] ; then
			wlan_key=$(mtd_get_cstring factory 0x210a0)

			wlan_5ghz_ssid="${wlan_ssid:0:8}5${wlan_ssid:9}"
			hostname="${wlan_ssid:0:8}${wlan_ssid:11}"

			serial_number=$(mtd_get_cstring factory 0x21010)
			root_password="$serial_number"
		else
			wlan_ssid=
		fi
		;; # beeline,smartbox-turbo-plus
	xiaomi,ax3600)
	# qcom,ipq807x-ac04) # xiaomi openwrt board id
		
		wlan_2ghz_id=2

		local offset="0x4"

		while true ;  do
			local kv=$(mtd_get_cstring bdata "$offset")
			[[ ! -z "$kv" ]] || break
			local k="${kv%=*}"
			local v="${kv#*=}"
			if [[ "$k" == "SN" ]] ; then
				serial_number="$v"
				root_password="$v"
				wlan_key="$v"

			elif [[ "$k" == "wl0_ssid" ]] ; then
				wlan_5ghz_ssid="$v"
			elif [[ "$k" == "wl1_ssid" ]] ; then
				wlan_ssid="$v"
				hostname="$v"
				uci set wireless.@wifi-iface[0].ssid=${v}_IoT
			elif [[ "$k" == "CountryCode" ]] ; then
				wlan_country="$v"
			fi
			offset=$(( $offset + ${#kv} + 1 ))
		done
		;; # xiaomi,ax3600
	dynalink,dl-wrx36)
		
		# iw phy0 info | egrep '\* 5\d\d\d MHz'
		wlan_2ghz_id=2

		wlan_ssid=$(mtd_get_cstring "0:art" 0x301C0)
		if [ "$wlan_ssid" != "${wlan_ssid#Dynalink}" ] ; then
			wlan_key=$(mtd_get_cstring "0:art" 0x30200)

			wlan_5ghz_ssid=$(mtd_get_cstring "0:art" 0x30240)
			hostname="${wlan_ssid:0:11}"

			serial_number=$(mtd_get_cstring "0:art" 0x30180)
			root_password=$(mtd_get_cstring "0:art" 0x30628)
		else
			wlan_ssid=
		fi
		;; # dynalink,dl-wrx36
	esac

	if [ ! -z "$wlan_ssid" ] ; then
		uci -q batch << EOI
set wireless.@wifi-device[${wlan_2ghz_id}].disabled='0'
set wireless.@wifi-device[${wlan_2ghz_id}].country='${wlan_country}'

set wireless.@wifi-iface[${wlan_2ghz_id}].ssid='${wlan_ssid}'
set wireless.@wifi-iface[${wlan_2ghz_id}].encryption='${wlan_enc}'
set wireless.@wifi-iface[${wlan_2ghz_id}].key='${wlan_key}'
set wireless.@wifi-iface[${wlan_2ghz_id}].network='lan'

set wireless.@wifi-iface[${wlan_2ghz_id}].ieee80211r='1'
set wireless.@wifi-iface[${wlan_2ghz_id}].mobility_domain='fe24'
set wireless.@wifi-iface[${wlan_2ghz_id}].ft_psk_generate_local='1'
set wireless.@wifi-iface[${wlan_2ghz_id}].reassociation_deadline '20000'
set wireless.@wifi-iface[${wlan_2ghz_id}].ft_over_ds '0'

set wireless.@wifi-device[${wlan_5ghz_id}].disabled='0'
set wireless.@wifi-device[${wlan_5ghz_id}].country='${wlan_country}'

set wireless.@wifi-iface[${wlan_5ghz_id}].ssid='${wlan_5ghz_ssid}'
set wireless.@wifi-iface[${wlan_5ghz_id}].encryption='${wlan_enc}'
set wireless.@wifi-iface[${wlan_5ghz_id}].key='${wlan_key}'
set wireless.@wifi-iface[${wlan_5ghz_id}].network='lan'

set wireless.@wifi-iface[${wlan_5ghz_id}].ieee80211r='1'
set wireless.@wifi-iface[${wlan_5ghz_id}].mobility_domain='fe58'
set wireless.@wifi-iface[${wlan_5ghz_id}].ft_psk_generate_local='1'
set wireless.@wifi-iface[${wlan_5ghz_id}].reassociation_deadline '20000'
set wireless.@wifi-iface[${wlan_5ghz_id}].ft_over_ds '0'

commit wireless
EOI
	fi

	if [ ! -z "$root_password" ] ; then
		set_factory_root_password "$root_password"
	fi
}