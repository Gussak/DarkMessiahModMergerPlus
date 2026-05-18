#!/bin/bash

set -Eeu

source "./allMergerScriptsGenericConfig.sh"

set -x
(cd "$strPathParent"; egrep "$@" -R "${astrGrepIncludesExt[@]}" *)
