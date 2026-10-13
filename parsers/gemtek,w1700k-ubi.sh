get_mtd_offset () {
    echo 0x400000
}

get_part_name () {
	echo "vendor" # mtd0
}

get_oem_data_gemtek__w1700k_ubi () {

    local part
    part="$(get_part_name)"

    wlan_phy_id=0
    wlan_5ghz_phy_id=1
    wlan_6ghz_phy_id=2

	local offset="0"

	while true ;  do
		local kv="$(get_mtd_cstr "$part" "$offset" 512)"
		[[ -n "$kv" ]] || break
		local k="${kv%=*}"
		local v="${kv#*=}"

		if [[ "$k" == "serial_number" ]] ; then
			serial_number="$v"
		elif [[ "$k" == "admin_password" ]] ; then
			root_password="$(printf '%s\n' "$v" | cut -d '$' -f 3)"
		elif [[ "$k" == "wifi_passphrase" ]] ; then
			wlan_key="$v"
		elif [[ "$k" == "wifi_ssid" ]] ; then
			wlan_ssid="$v"
			wlan_5ghz_ssid="$v"
			wlan_6ghz_ssid="$v"
			hostname="$v"
		fi
		offset=$(( $offset + ${#kv} + 1 ))
	done
}
