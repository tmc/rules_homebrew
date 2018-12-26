#!/bin/bash
set -euo pipefail
brew_binary="${1}"
shift
package="${1}"
shift
output_file="${1}"
shift

set -x
export HOMEBREW_NO_AUTO_UPDATE=1
#export HOME=$(mktemp -d)
export HOME=/tmp/hbtmp
"${brew_binary}" install --display-times --verbose "${package}" || echo 'install "failure'
"${brew_binary}" ls --versions "${package}"
tree > "${output_file}"
