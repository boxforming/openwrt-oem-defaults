#!/usr/bin/env bash

load ../chunks/oemlib.sh

load ../lib/test.sh

@test "sanity check: parser function name" {

    local model_name="dynalink,dl-wrx36"

    run get_oem_data_parser "$model_name"

    [ "$output" = "get_oem_data_dynalink__dl_wrx36" ]
}

@test "sanity check: load parser" {

    local model_name="dynalink,dl-wrx36"

    local parser_fn_name="$(get_oem_data_parser "$model_name")"

    local parser_filename="parsers/$(get_filename_from_model_name "$model_name").sh"

    . "$parser_filename"

    set -e

    "$parser_fn_name"

    set +e
}
