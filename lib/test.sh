#!/usr/bin/env bash

find_mtd_part () {
    echo "test/${model_name}.dump"
}

get_filename_from_model_name () {
	echo "${1//\//-}"
}