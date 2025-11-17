get_oem_data_gemtek__w1700k () {

    local part="dsd" # mtd9

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
			root_password="$v"
		elif [[ "$k" == "wifi_passphrase" ]] ; then
			wlan_key="$v"
		elif [[ "$k" == "wifi_ssid" ]] ; then
			wlan_ssid="$v"
			hostname="$v"
		fi
		offset=$(( $offset + ${#kv} + 1 ))
	done
}
