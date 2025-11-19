get_mtd_offset () {
    echo "0x21000"
}

get_oem_data_beeline__smartbox_turbo_plus () {

	local part="Factory" # mtd2

	wlan_phy_id=0
	wlan_5ghz_phy_id=1

	wlan_ssid="$(get_mtd_cstr "$part" 0x80)"
	if [ "$wlan_ssid" != "${wlan_ssid#Beeline}" ] ; then
		wlan_key="$(get_mtd_cstr "$part" 0xa0)"

		wlan_5ghz_ssid="${wlan_ssid:0:8}5${wlan_ssid:9}"
		hostname="${wlan_ssid:0:8}${wlan_ssid:11}"

		serial_number="$(get_mtd_cstr "$part" 0x10)"
		root_password="$serial_number"
	else
		wlan_ssid=
	fi
}
