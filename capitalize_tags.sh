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
	# We must use process substitution for this loop (instead of a pipe).
	# Otherwise the "continue" will not work, since the pipe runs in a subprocess.
	tempfile=$(mktemp)
    while read -r tagline; do
		if [[ "${tagline}" == *=*  ]]; then
			tagname="${tagline%%=*}"
			tagvalue="${tagline#*=}"
			printf '%s=%s\n' "${tagname@U}" "${tagvalue}" >> "${tempfile}"
		else
			echo "${flacfile}: Unable to process multiline tag \"${tagname}\"" | colorize red >&2
			rm -f "${tempfile}" || true
			continue 2
		fi
    done < <(metaflac --export-tags-to=- "${flacfile}")
	echo "${flacfile}: Rewriting capitalized tags ..."
	metaflac --remove-all-tags --import-tags-from="${tempfile}" "${flacfile}"
	rm -f "${tempfile}" || true
done
