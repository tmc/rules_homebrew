#!/bin/bash
set -euo pipefail
brew_binary="${1}"
shift
package="${1}"
shift
output_file="${1}"
shift

cellar_path=$(dirname $(dirname "${brew_binary}"))/Cellar
cache_path=$(pwd)/$(dirname $(dirname "${brew_binary}"))/cache
export HOMEBREW_CACHE="${cache_path}"

export HOMEBREW_NO_AUTO_UPDATE=1
export HOME=$(mktemp -d)
"${brew_binary}" uninstall "${package}" || echo ''
export HOMEBREW_BUILD_FROM_SOURCE=1
"${brew_binary}" install  --display-times --verbose "${package}" || (
    echo 'Falling back to binary build'
    unset HOMEBREW_BUILD_FROM_SOURCE
    "${brew_binary}" install --display-times --verbose "${package}"
)

version=$("${brew_binary}" ls --versions "${package}" | tail -n1 | cut -d' ' -f2)
mkdir -p $(dirname "${output_file}")
#TODO(tmc): consider if this should be pkg_tar in starlark instead.
tar -C "${cellar_path}/${package}/${version}" -cvf "${output_file}" .
