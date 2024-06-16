#!/usr/bin/env bash

get_tag_value() {
    (( $# != 2 )) && { echo "usage: ${FUNCNAME} TAGNAME FLACFILE" >&2 ; return 99; }
    metaflac --show-tag="${1}" "${2}" | grep -oP "(?<=${1}=).*"
}

get_artist() {
    (( $# != 1 )) && { echo "usage: ${FUNCNAME} FLACFILE" >&2 ; return 99; }
    get_tag_value "ARTIST" "${1}"
}

get_album_artist() {
    (( $# != 1 )) && { echo "usage: ${FUNCNAME} FLACFILE" >&2 ; return 99; }
    get_tag_value "ALBUMARTIST" "${1}"
}

get_album_title() {
    (( $# != 1 )) && { echo "usage: ${FUNCNAME} FLACFILE" >&2 ; return 99; }
    get_tag_value "ALBUM" "${1}"
}

get_tracknumber() {
    (( $# != 1 )) && { echo "usage: ${FUNCNAME} FLACFILE" >&2 ; return 99; }
    get_tag_value "TRACKNUMBER" "${1}"
}

get_title() {
    (( $# != 1 )) && { echo "usage: ${FUNCNAME} FLACFILE" >&2 ; return 99; }
    get_tag_value "TITLE" "${1}"
}

add_tag() {
    (( $# < 3 )) && { echo "usage: ${FUNCNAME} TAGNAME VALUE FLACFILE..." >&2 ; return 99; }
    metaflac --set-tag="${1^^}=${2}" "${@:3}"
}

replace_tag() {
    (( $# < 3 )) && { echo "usage: ${FUNCNAME} TAGNAME VALUE FLACFILE..." >&2 ; return 99; }
    echo metaflac --remove-tag="${1^^}" --set-tag="${1^^}=${2}" "${@:3}"
}

remove_tag() {
    (( $# < 2 )) && { echo "usage: ${FUNCNAME} TAGNAME FLACFILE.." >&2 ; return 99; }
    metaflac --remove-tag="${1^^}" "${@:2}"
}
