#!/usr/bin/env bash
set -o errexit
set -o pipefail
# set -o xtrace

readonly __dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly __file="${__dir}/$(basename "${BASH_SOURCE[0]}")"
readonly __base="$(basename "${__file}" .sh)"

. "${__dir}/common.sh"

(( $# < 1 )) && { echo "usage: ${BASH_SOURCE[0]} FLACFILE..." >&2 ; exit 1; }

artist=$(get_album_artist "${1}") || { echo "Error: failed to retrieve album artist" >&2 ; exit 98; }
album=$(get_album_title "${1}") || { echo "Error: failed to retrieve album title" >&2 ; exit 99; }
outfile="${artist} -00- ${album}.sha256"
timestamp="$(date +'%A %Y-%m-%d %H:%M:%S')"

[[ -f ${outfile} ]] && mv -f --backup=numbered "${outfile}" "${outfile}.bak"

echo "# Generated on ${timestamp}" > "${outfile}"
sha256sum -b "${@}" >> "${outfile}"
echo "Generated \"${outfile}\""
