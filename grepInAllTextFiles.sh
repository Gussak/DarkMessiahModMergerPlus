#!/bin/bash

while [[ ! -f "./allMergerScriptsGenericConfig.sh" ]];do cd ..;done; source "./allMergerScriptsGenericConfig.sh"; FUNCminiModInit "$@"

set -x
(cd "$strPathParent"; egrep "$@" -R "${astrGrepIncludesExt[@]}" *)
