#!/usr/bin/env bash

load ../chunks/oemlib.sh

vendor_name="beeline"
device_name="smartbox-turbo-plus"
model_name="${vendor_name},${device_name}"

load ../lib/test.sh

@test "factory data check for $vendor_name $device_name" {

    prepare_test_for "$model_name"

    set -e

	local parser_fn_name="$(get_oem_data_parser "$model_name")"

    $parser_fn_name

    # TODO: remove or uncomment next line after test pass
    echo "$(wlan_country="US" wlan_enc="psk2" VERBOSE=1 INSECURE=1 check_config)"

    [ "$wlan_ssid" = "$expected_wlan_ssid" ]
    [ "$hostname"  = "$expected_hostname" ]
    [ "$wlan_5ghz_ssid" = "$expected_wlan_5ghz_ssid" ]

    [ "$root_password" = "$expected_root_password" ]
    [ "$serial_number" = "$expected_serial_number" ]
    [ "$wlan_key"      = "$expected_wlan_key" ]

    set +e
}
