#!/usr/bin/env bash

command="$1"
model="$2"

if [[ -z $command ]] ; then
    echo "OEM configuration generator. Usage: $0 <command> <model>"
    echo "$0 uci <model> # uci-defaults generator for openwrt firmware selector"
    echo "$0 devcheck <model> # script generator to show configuration from oem data"
    exit 0
fi

if [[ -z $model ]] ; then
    echo "Cannot proceed without model. Usage: $0 <command> <model>"
    exit 1
fi

if [[ "$command" == "uci" ]] ; then
    script_header="$(<./chunks/header.sh)"
    
    oemlib_functions="$(<./chunks/oemlib.sh)"

    params_include="$(<./chunks/params.sh)"

    footer_include="$(<./chunks/uci-defaults.sh)"

    if [[ -f "$model" ]] ; then
        device_functions="$(<"$model")"
    elif [[ -f "./parsers/$model.sh" ]] ; then
        device_functions="$(<"./parsers/$model.sh")"
    else
        echo "Error: provide existing parser for model from parsers folder, model '$model' not found"
        exit 2
    fi

    cat > "./uci-defaults.$model.sh" << UCI_DEFAULTS
$script_header
$oemlib_functions
$device_functions

get_device_oem_data

$params_include
$footer_include
UCI_DEFAULTS
fi