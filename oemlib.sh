get_model_name () {
	cat /proc/device-tree/compatible | tr -s '\000' '\n' | head -n 1
}

get_oem_data_parser () {
	local brd="${1:-$(get_model_name)}"
	brd="${brd//[\/-]/_}"
	echo "get_oem_data_${brd//,/__}"
}

get_mtd_cstr () {
	local mtdname="$1"
	local offset=$(($2))
	local limit=$((${3:-32}))
	local part
	local mac_dirty
	
	part="$(find_mtd_part "$mtdname")"

	local cstring="$(dd if="$part" skip="$offset" count="$limit" bs=1 2>/dev/null | tr -s '\000' '\n' | head -n1)"

	echo "$cstring"
}

set_factory_root_password () {
	local factory_root_password="$1"
	local root_shadow=$(grep '^root' /etc/shadow | cut -d ':' -f 2)
	if [[ -z $root_shadow ]] && [[ -n $factory_root_password ]] ; then
		echo -e "$factory_root_password\n$factory_root_password" | passwd root
	fi
}

get_device_oem_data () {

	model_name="$(get_model_name)"

	local parser=$(get_oem_data_parser "$model_name")

	set -e

	$parser

	set +e
}

apply_factory_defaults () {

	if [[ -n $wlan_ssid ]] && uci get "wireless.@wifi-device[${wlan_phy_id}]" && uci get "wireless.@wifi-device[${wlan_phy_id}].disabled" ; then
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

	if [[ -n $wlan_5ghz_ssid ]] && uci get "wireless.@wifi-device[${wlan_5ghz_phy_id}]" && uci get "wireless.@wifi-device[${wlan_5ghz_phy_id}].disabled" ; then
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

	uci commit wireless

	if [[ -n $root_password ]] ; then
		set_factory_root_password "$root_password"
	fi

}
