#!/bin/bash
set -euo pipefail
export HOMEBREW_NO_AUTO_UPDATE=1
export HOMEBREW_CACHE=$(pwd)/cache
export HOMEBREW_BUILD_FROM_SOURCE=1
export HOMEBREW_EMIT_URLS_ONLY=1
# because of the preceding environment variable this wil only download sources
bin/brew install $*
