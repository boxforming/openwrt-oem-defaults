
# @type {string} wlan_country WiFi country code
wlan_country="ES"

# @type {string} wlan_enc WiFi encryption for all radios https://openwrt.org/docs/guide-user/network/wifi/basic#encryption_modes
wlan_enc="psk2"

# @type {string} [wlan_5ghz_enc] WiFi encryption for 5GHz
wlan_5ghz_enc="sae"

# @type {string} [wlan_6ghz_enc] WiFi encryption for 6GHz
wlan_6ghz_enc="sae"

# @type {0|1} [wlan_roaming=0] 802.11r WiFi roaming https://openwrt.org/docs/guide-user/network/wifi/basic#fast_bss_transition_options_80211r
wlan_roaming=1

# @type {string} [ipv4_address] IPv4 router address for LAN
# ipv4_address="10.10.1.254"

# @type {string} [timezonename] Time zone name
timezonename="Europe/Madrid"

# @type {string} [timezone] Time zone (+802.11v) https://github.com/openwrt/luci/blob/master/modules/luci-lua-runtime/luasrc/sys/zoneinfo/tzdata.lua
timezone="CET-1CEST,M3.5.0,M10.5.0/3"
