#!/usr/bin/env bash
set -o errexit
set -o pipefail
# set -o xtrace

readonly __dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly __file="${__dir}/$(basename "${BASH_SOURCE[0]}")"
readonly __base="$(basename "${__file}" .sh)"

(( $# < 1 )) && { echo "usage: ${BASH_SOURCE[0]} FLACFILE..." >&2 ; exit 1; }

metaflac --add-replay-gain "$@"
