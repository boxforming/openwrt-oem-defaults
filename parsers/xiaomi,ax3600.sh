get_oem_data_xiaomi__ax3600 () {
		
    local part="bdata" # mtd9

    wlan_phy_id=2
    wlan_5ghz_phy_id=1

	local offset="0x4"

	while true ;  do
		local kv="$(get_mtd_cstr "$part" "$offset" 512)"
		[[ -n $kv ]] || break
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
		elif [[ "$k" == "CountryCode" ]] ; then
			wlan_country="$v"
		fi
		offset=$(( $offset + ${#kv} + 1 ))
	done
}

fixup_xiaomi__ax3600 () {
	uci set wireless.@wifi-iface[0].ssid=${wlan_ssid}_IoT
}