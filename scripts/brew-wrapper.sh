#!/bin/bash
set -euo pipefail
set -x
export HOMEBREW_NO_AUTO_UPDATE=1
export HOMEBREW_CACHE=$(pwd)/cache
#export HOMEBREW_BUILD_FROM_SOURCE=1
#export HOMEBREW_DOWNLOAD_ONLY=1
bin/brew $*
tree bin
