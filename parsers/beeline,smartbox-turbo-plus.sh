get_oem_data_beeline__smartbox_turbo_plus () {

	local part="factory"

    wlan_ssid=$(mtd_get_cstring "$part" 0x21080)
	if [ "$wlan_ssid" != "${wlan_ssid#Beeline}" ] ; then
		wlan_key=$(mtd_get_cstring "$part" 0x210a0)

		wlan_5ghz_ssid="${wlan_ssid:0:8}5${wlan_ssid:9}"
		hostname="${wlan_ssid:0:8}${wlan_ssid:11}"

		serial_number=$(mtd_get_cstring "$part" 0x21010)
		root_password="$serial_number"
	else
		wlan_ssid=
	fi
}