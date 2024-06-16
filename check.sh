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

        This is a description of this program.

        Parameters are:
            DIRECTORY
                This is a description of the parameter.

        Valid options are:
            -a --autofix
                Attempt to automatically fix any issues
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
opts="avth"
longopts="autofix,verbose,trace,help"
args=$(getopt -n "${__base}" -o "${opts}" -l "${longopts}" -- "${@}") || {
    echo >&2
    show_help >&2
    exit 1
}
eval set -- "${args}"
unset autofix
while true; do
    case "$1" in
        "--")
            shift
            break
            ;;
        "--autofix" | "-a" )
            autofix=true
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

# Only continue, if  the file integrity can be verified
if compgen -G *.sha256 >/dev/null 2>&1; then
	echo $(colorize blue -- "Validating file integrity:")
	sha256sum -c *.sha256
fi

echo $(colorize red -- "Do some stuff ...")
sleep 10

# --autofix

# When we are done, check if recreation of the SHA file is required.
if ! sha256sum -c *.sha256 >/dev/null 2>&1; then
	echo $(colorize blue -- "Creating hash file:")
	${__dir}/create_hashfile.sh *.flac
fi

