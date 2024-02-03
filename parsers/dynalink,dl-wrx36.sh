get_oem_data_dynalink__dl_wrx36 () {
# askey__rt5010w_d350_rev0 () { # OEM firmware id
	# local part="0:ART" # OEM firmware partition
	local part="0:art" # mtd17

	# iw phy0 info | egrep '\* 5\d\d\d MHz'
	wlan_phy_id=2
	wlan_5ghz_phy_id=1

	wlan_ssid="$(get_mtd_cstr "$part" 0x301C0)"
	if [[ "$wlan_ssid" != "${wlan_ssid#Dynalink}" ]] ; then
		wlan_key="$(get_mtd_cstr "$part" 0x30200)"

		wlan_5ghz_ssid="$(get_mtd_cstr "$part" 0x30240)"
		hostname="${wlan_ssid:0:11}"

		serial_number="$(get_mtd_cstr "$part" 0x30180)"
		root_password="$(get_mtd_cstr "$part" 0x30628)"
	else
		wlan_ssid=
	fi
}