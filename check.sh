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
            -a, --autofix
                Attempt to automatically fix any detected issues

            -f, --force
                Apply and overwrite all fixes, regardless of necessity

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
            autofix="true"
            ;;
        "--force" | "-f" )
            force="true"
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
TARGETDIR="${1}"

start_timestamp=$(date '+%s')
pushd "${TARGETDIR}" >/dev/null 2>&1

# Check if a SHA256 file exists and validate the files
echo "Validating file integrity:" | colorize blue
if compgen -G "*.sha256" >/dev/null 2>&1; then
	sha256sum -c *.sha256 || {
		echo "=> Validation failure <=" | colorize red >&2
		if ${autofix:-"false"} && ! ${force:-"false"}; then
			echo "Aborting: Will not fix unvalidated files unless forced!" | colorize red >&2
			exit 99
		fi
	}

	# TODO: Check if SHA file lists all files
	# TODO: Check if SHA file contains additional files
else
	echo "=> There is no hashfile <=" | colorize red >&2
fi

#
# TODO: Check if filenames are OK: Format %artist%
# TODO: Capitalize all tag names
# TODO: Check if all required tags are present
# TODO: Check if tags are not present multiple times (exceptions: GENRE, possibly ARTIST)
# TODO: Check if all files share the same: ALBUMARTIST, DISCNUMBER, TOTALDISKS, TOTALTRACKS, GENRE, DATE, RECORD_TYPE, PUBLISHER, CATALOG_ID, AUDIO_EXTRACTOR
# TODO: Check if all tag values are in the required format (numbers!)
# TODO: If we have a picture, check if it is present in the FLAC files
#

# Check if ReplayGain tags are present, if not add them
echo "Checking ReplayGain information:" | colorize blue
invalid_replaygain="false"
${__dir}/check_replaygain.sh *.flac || invalid_replaygain="true"
if ${invalid_replaygain:-"false"} && ${autofix:-"false"} || ${force:-"false"}; then
	echo "Adding ReplayGain info:" | colorize blue
	${__dir}/add_replaygain.sh *.flac
fi
metaflac --show-tag=REPLAYGAIN_TRACK_GAIN --show-tag=REPLAYGAIN_ALBUM_GAIN --show-tag=REPLAYGAIN_TRACK_PEAK --show-tag=REPLAYGAIN_ALBUM_PEAK *.flac

# Only allow multiple Tags for "GENRE"

if ${autofix:-"false"} || ${force:-"false"}; then
	echo "Sorting and merging padding:" | colorize blue
	metaflac --sort-padding *.flac
	echo "Done"
fi

# When we are done, check if recreation of the SHA256 file is required
if ! sha256sum -c *.sha256 >/dev/null 2>&1 && ${autofix:-"false"} || ${force:-"false"}; then
	echo "Creating hash file:" | colorize blue
	${__dir}/create_hashfile.sh *.flac
fi

popd >/dev/null 2>&1
echo "Finished in $(duration "${start_timestamp}")" | colorize "green"
