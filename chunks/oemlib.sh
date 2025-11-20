get_model_name () {
	cat /proc/device-tree/compatible | tr -s '\000' '\n' | head -n 1
}

get_model_function_suffix () {
	local suffix="${1:-$(get_model_name)}"
	suffix="${suffix//[\/-]/_}"
	echo "${suffix//,/__}"
}

get_oem_data_parser () {
	echo "get_oem_data_$(get_model_function_suffix "$1")"
}

get_fixup_function () {
	echo "fixup_$(get_model_function_suffix "$1")"
}

get_mtd_offset () {
    echo "0"
}

get_mtd_cstr () {
	local mtdname="$1"
	local base_offset=$(($2))
	local mtd_offset=$(get_mtd_offset "$mtdname")
	local offset=$((mtd_offset + base_offset))
	local limit=$((${3:-32}))
	local part
	local mac_dirty
	
	part="$(find_mtd_part "$mtdname")"

	local cstring="$(dd if="$part" skip="$offset" count="$limit" bs=1 2>/dev/null | tr -s '\000' '\n' 2>/dev/null | head -n1)"

	echo "$cstring"
}

set_factory_root_password () {
	local factory_root_password="$1"
	if [[ -z "$factory_root_password" ]] ; then
		return
	fi
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

gen_wifi_config () {
    local wdevstr="wireless.@wifi-device[$1]"
    local  wifstr="wireless.@wifi-iface[$1]"

    cat << EOI
set ${wdevstr}.disabled='0'
set ${wdevstr}.country='${wlan_country}'

set ${wifstr}.ssid='${2:-$wlan_ssid}'
set ${wifstr}.encryption='${3:-$wlan_enc}'
set ${wifstr}.key='${4:-$wlan_key}'
set ${wifstr}.network='lan'

set ${wifstr}.ieee80211r='${wlan_roaming:-1}'

EOI
}

apply_factory_defaults () {

	if [[ -n $wlan_ssid ]] && uci get "wireless.@wifi-device[${wlan_phy_id}]" && uci get "wireless.@wifi-device[${wlan_phy_id}].disabled" ; then
	    gen_wifi_config "${wlan_phy_id}" "${wlan_ssid}" "${wlan_enc}" "${wlan_key}" | uci -q batch
	fi

	if [[ -n $wlan_5ghz_ssid ]] && uci get "wireless.@wifi-device[${wlan_5ghz_phy_id}]" && uci get "wireless.@wifi-device[${wlan_5ghz_phy_id}].disabled" ; then
	    gen_wifi_config "${wlan_5ghz_phy_id}" "${wlan_5ghz_ssid}" "${wlan_5ghz_enc}" "${wlan_5ghz_key}" | uci -q batch
	fi

	if [[ -n $wlan_6ghz_ssid ]] && uci get "wireless.@wifi-device[${wlan_6ghz_phy_id}]" && uci get "wireless.@wifi-device[${wlan_6ghz_phy_id}].disabled" ; then
	    gen_wifi_config "${wlan_6ghz_phy_id}" "${wlan_6ghz_ssid}" "${wlan_6ghz_enc}" "${wlan_6ghz_key}" | uci -q batch
	fi

	uci commit wireless

	set_factory_root_password "$root_password"

}

apply_fixup () {
    local fixup_function="$(get_fixup_function)"
    if [[ $(type -t $fixup_function || echo fail) == "$fixup_function" ]] ; then
        $fixup_function
    fi
}