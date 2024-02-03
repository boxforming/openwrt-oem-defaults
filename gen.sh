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
    oemlib_functions="$(<./oemlib.sh)"

    template="$(<./uci-defaults.sh.template)"

    template_start="${template%### placeholder ###*}"
    template_end="${template#*### placeholder ###}"
    

    if [[ -f "$model" ]] ; then
        device_functions="$(<"$model")"
    elif [[ -f "./parsers/$model.sh" ]] ; then
        device_functions="$(<"./parsers/$model.sh")"
    else
        echo "Error: provide existing parser for model from parsers folder, model '$model' not found"
        exit 2
    fi

    cat > ./uci-defaults.sh << UCI_DEFAULTS
$template_start
$oemlib_functions
$device_functions
$template_end
UCI_DEFAULTS
fi