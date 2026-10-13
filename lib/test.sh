#!/usr/bin/env bash

find_mtd_part () {
    echo "test/${model_name}.dump"
}

get_filename_from_model_name () {
	echo "${1//\//-}"
}

prepare_test_for () {

	local model_name="$1"

	local parser_filename="parsers/$(get_filename_from_model_name "$model_name").sh"

	if [[ ! -f "$parser_filename" ]] ; then
		skip "No parser file '$parser_filename'"
		return 1
	else
    	. "$parser_filename"
    fi

	local parser_fn_name="$(get_oem_data_parser "$model_name")"

    if [[ ! -f "$(find_mtd_part "$model_name")" ]] ; then
        skip "Expected dump of partition named $(get_part_name) with offset $(get_mtd_offset) not found"
        return 2
    fi

    . lib/test-parser-overrides.sh

	local fixture_filename="test/${model_name}.fixture"

	if [[ ! -f "$fixture_filename" ]] ; then
		skip "No fixture file '$fixture_filename'"
		return 3
	else
    	. "$fixture_filename"
    fi
	

}
