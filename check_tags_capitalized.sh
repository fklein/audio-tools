#!/usr/bin/env bash
set -o errexit
set -o pipefail
# set -o xtrace

readonly __dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly __file="${__dir}/$(basename "${BASH_SOURCE[0]}")"
readonly __base="$(basename "${__file}" .sh)"

. "${__dir}/common.sh"

(( $# < 1 )) && { echo "usage: ${BASH_SOURCE[0]} FLACFILE..." >&2 ; exit 1; }

invalid="false"
for flacfile in "${@}"; do
    metaflac --export-tags-to=- "${flacfile}" | while read -r tagline; do
		[[ "${tagline}" != *=*  ]] && continue
        tagname="${tagline%%=*}"
        tagvalue="${tagline#*=}"
        if [[ "${tagname}" != "${tagname@U}" ]]; then
            invalid="true"
            echo "${flacfile}: Tag \"${tagname}\" is not capitalized" | colorize red >&2
        fi
    done
done

if ${invalid:-"false"}; then
    exit 1
fi