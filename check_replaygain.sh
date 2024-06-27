#!/usr/bin/env bash
set -o errexit
set -o pipefail
# set -o xtrace

readonly __dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly __file="${__dir}/$(basename "${BASH_SOURCE[0]}")"
readonly __base="$(basename "${__file}" .sh)"

. "${__dir}/common.sh"

(( $# < 1 )) && { echo "usage: ${BASH_SOURCE[0]} FLACFILE..." >&2 ; exit 1; }

is_invalid="false"
for flacfile in "${@}"; do
	track_gain=$(get_tag_value REPLAYGAIN_TRACK_GAIN "${flacfile}") || true
	track_peak=$(get_tag_value REPLAYGAIN_TRACK_PEAK "${flacfile}") || true
	album_gain=$(get_tag_value REPLAYGAIN_ALBUM_GAIN "${flacfile}") || true
	album_peak=$(get_tag_value REPLAYGAIN_ALBUM_PEAK "${flacfile}") || true
	# echo "ReplayGain for $flacfile = $track_gain / $album_gain"
	# TODO: check the REPLAYGAIN_ALBUM_GAIN + REPLAYGAIN_ALBUM_PEAK match between all files
	if [[ -z ${track_gain} || -z ${track_peak} || -z ${album_gain} || -z ${album_peak} ]]; then
		is_invalid="true"
		echo "=> ${flacfile}: ReplayGain information is missing or incorrect <=" | colorize red >&2
	fi
done

if ${is_invalid:-"false"}; then
	exit 1
fi