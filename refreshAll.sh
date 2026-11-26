#!/bin/bash

# SPDX-License-Identifier: Apache-2.0

while [[ ! -f "./allMergerScriptsGenericConfig.sh" ]];do pwd;cd ..;done; source "./allMergerScriptsGenericConfig.sh"; FUNCminiModInit "$@"
FUNCrefreshMount
