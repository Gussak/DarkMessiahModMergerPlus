#!/bin/bash
while [[ ! -f "./allMergerScriptsGenericConfig.sh" ]];do pwd;cd ..;done; source "./allMergerScriptsGenericConfig.sh"; FUNCminiModInit "$@"
FUNCrefreshMount
