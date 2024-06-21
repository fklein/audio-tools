#!/usr/bin/env bash
set -o errexit
set -o pipefail
# set -o xtrace

readonly __dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly __file="${__dir}/$(basename "${BASH_SOURCE[0]}")"
readonly __base="$(basename "${__file}" .sh)"

. "${__dir}/common.sh"

# Print a help text for this script.
show_help() {
    local helpstring="\
        usage: $(basename "${__file}") [OPTIONS] DIRECTORY

        Toolchain script for FLAC audio archive. Attempt to detect and possibly fix any
        issues with the FLAC files of a music album.

        Parameters are:
            DIRECTORY
                The album directory to process.

        Valid options are:
            -a --autofix
                Attempt to automatically fix any detected issues

            -v, --verbose
                Enable verbose mode.

            -t, --trace
                Enable trace mode.

            -h, --help
                Print this help text.
    "
    echo "${helpstring}" | sed -r 's/^[[:space:]]{8}//' | sed -r 's/[[:space:]]*$//'
}


# Parse any arguments.
opts="afvth"
longopts="autofix,force,verbose,trace,help"
args=$(getopt -n "${__base}" -o "${opts}" -l "${longopts}" -- "${@}") || {
    echo >&2
    show_help >&2
    exit 1
}
eval set -- "${args}"
unset autofix force
while true; do
    case "$1" in
        "--")
            shift
            break
            ;;
        "--autofix" | "-a" )
            autofix=true
            ;;
        "--force" | "-f" )
            force=true
            ;;
        "--verbose" | "-v" )
            set -o verbose
            ;;
        "--trace" | "-t" )
            set -o xtrace
            ;;
        "--help" | "-h" )
            show_help
            exit 0
            ;;
    esac
    shift
done
if (( $# != 1 )); then
	echo "Error: Invalid parameters specified!" >&2
	show_help >&2
	exit 2
fi
PARAMETERS=("$@")

pushd "$1" >/dev/null 2>&1

# Only continue, if  the file integrity can be verified
echo "Validating file integrity:" | colorize blue
if compgen -G *.sha256 >/dev/null 2>&1; then
	sha256sum -c *.sha256 || {
		echo "=> Validation failure <=" | colorize red >&2
		# exit 99
	}
else
	echo "=> There is no hashfile <=" | colorize red >&2
fi

# Check if ReplayGain tags are present, if not add them
echo "Checking ReplayGain information:" | colorize blue
replay_gain_missing="false"
for flacfile in *.flac; do
	track_gain=$(get_tag_value REPLAYGAIN_TRACK_GAIN "${flacfile}") || true
	track_peak=$(get_tag_value REPLAYGAIN_TRACK_PEAK "${flacfile}") || true
	album_gain=$(get_tag_value REPLAYGAIN_ALBUM_GAIN "${flacfile}") || true
	album_peak=$(get_tag_value REPLAYGAIN_ALBUM_PEAK "${flacfile}") || true
	# echo "ReplayGain for $flacfile = $track_gain / $album_gain"
	if [[ -z ${track_gain} || -z ${track_peak} || -z ${album_gain} || -z ${album_peak} ]]; then
		replay_gain_missing="true"
		echo "=> ${flacfile}: ReplayGain information is missing or incorrect <=" | colorize red >&2
	fi
done
if ${replay_gain_missing} && ${autofix:-false}; then
	echo "Adding ReplayGain info:" | colorize blue
	${__dir}/add_replaygain.sh *.flac
fi
metaflac --show-tag=REPLAYGAIN_TRACK_GAIN --show-tag=REPLAYGAIN_ALBUM_GAIN --show-tag=REPLAYGAIN_TRACK_PEAK --show-tag=REPLAYGAIN_ALBUM_PEAK *.flac

# Only allow multiple Tags for "GENRE"

if ${autofix:-false}; then
	echo "Sorting and merging padding:" | colorize blue
	metaflac --sort-padding *.flac
fi

# When we are done, check if recreation of the SHA file is required.
if ! sha256sum -c *.sha256 >/dev/null 2>&1 && ${autofix:-false}; then
	echo "Creating hash file:" | colorize blue
	${__dir}/create_hashfile.sh *.flac
fi

popd >/dev/null 2>&1
