get_mtd_offset () {
    echo 0x30100
}

get_oem_data_dynalink__dl_wrx36 () {
# askey__rt5010w_d350_rev0 () { # OEM firmware id
	# local part="0:ART" # OEM firmware partition
	local part="0:art" # mtd17

	# iw phy0 info | egrep '\* 5\d\d\d MHz'
	wlan_phy_id=1
	wlan_5ghz_phy_id=0

	wlan_ssid="$(get_mtd_cstr "$part" 0xC0)"
	if [[ "$wlan_ssid" != "${wlan_ssid#Dynalink}" ]] ; then
		wlan_key="$(get_mtd_cstr "$part" 0x100)"

		wlan_5ghz_ssid="$(get_mtd_cstr "$part" 0x140)"
		hostname="${wlan_ssid:0:11}"

		serial_number="$(get_mtd_cstr "$part" 0x80)"
		root_password="$(get_mtd_cstr "$part" 0x528)"
	else
		wlan_ssid=
	fi
}