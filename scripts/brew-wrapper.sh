#!/bin/bash
set -euo pipefail

test -f ../homebrew/bin/brew || (
    echo ''
    echo 'homebrew has not been fetched. Please run':
    echo '$ bazel fetch @homebrew//...'
    echo ''
	exit 1
)
export HOMEBREW_NO_AUTO_UPDATE=1
export HOMEBREW_CACHE=$(pwd)/../homebrew/cache
#export HOMEBREW_BUILD_FROM_SOURCE=1
#export HOMEBREW_DOWNLOAD_ONLY=1
../homebrew/bin/brew $*
