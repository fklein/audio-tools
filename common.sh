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

[[ -t 1 ]] && istty=true
colorize() {
    local escapecodes
    declare -A escapecodes=(
        # Common
        [reset]=$'\e[0m' [bold]=$'\e[1m' [dim]=$'\e[2m' [italic]=$'\e[3m' [underline]=$'\e[4m'
        [blink]=$'\e[5m' [invert]=$'\e[7m' [invisible]=$'\e[8m' [strikethrough]=$'\e[9m'
        # Text
        [default]=$'\e[39m'
        [black]=$'\e[30m'   [white]=$'\e[97m'
        [gray]=$'\e[90m'    [lightgray]=$'\e[37m'
        [red]=$'\e[31m'     [lightred]=$'\e[91m'
        [green]=$'\e[32m'   [lightgreen]=$'\e[92m'
        [yellow]=$'\e[33m'  [lightyellow]=$'\e[93m'
        [blue]=$'\e[34m'    [lightblue]=$'\e[94m'
        [magenta]=$'\e[35m' [lightmagenta]=$'\e[95m'
        [cyan]=$'\e[36m'    [lightcyan]=$'\e[96m'
        # Background
        [bgdefault]=$'\e[49m'
        [bgblack]=$'\e[40m'     [bgwhite]=$'\e[107m'
        [bggray]=$'\e[100m'     [bglightgray]=$'\e[47m'
        [bgred]='\e[41m'        [bglightred]='\e[101m'
        [bggreen]='\e[42m'      [bglightgreen]='\e[102m'
        [bgyellow]=$'\e[43m'    [bglightyellow]=$'\e[103m'
        [bgblue]='\e[44m'       [bglightblue]='\e[104m'
        [bgmagenta]=$'\e[45m'   [bglightmagenta]=$'\e[105m'
        [bgcyan]=$'\e[46m'      [bglightcyan]=$'\e[106m'
    )
    local fmtseq=$''
    local fmtreset="${escapecodes[reset]}"
    # Parse the format specifiers
    while (( $# > 0 )); do
        [[ "$1" == "--" ]] && { shift ; break ; }
        local format
        for format in ${1//,/ }; do
            if [[ -z "${escapecodes[${format}]+IsSet}" ]]; then
                echo "${FUNCNAME[0]}: unknown format \"${format}\"" >&2
                return 1
            fi
            fmtseq+="${escapecodes[${format}]}"
        done
        shift
    done
	${istty:-false} || { fmtseq='' ; fmtreset='' ; }
    # Print formated text from stdin if no text parameters are given
    if (( $# == 0 )); then
        local stdin
        while read -r stdin; do
            printf "${fmtseq}%s${fmtreset}\n" "${stdin}"
        done
    fi
    # Print formated text parameters
    while (( $# > 0 )); do
        printf "${fmtseq}%s${fmtreset}" "${1}"
        shift
        (( $# > 0 )) && printf " " || printf "\n"
    done
}
