#!/bin/bash

# SPDX-License-Identifier: Apache-2.0

while [[ ! -f "./allMergerScriptsGenericConfig.sh" ]];do cd ..;done; source "./allMergerScriptsGenericConfig.sh"; FUNCminiModInit "$@"

#TODO: initial alias selections could all be in a new cfg file that would not be part of the loaded ones like ..._AliasSelectorsInitializer.cfg

strFlCfg="${strPathThisModSubFolderFull}/gskReloadCfgs.cfg"

astrSkip=(
	"auto_load_last_quicksave"
	"gskdevhelpDoNotEnable"
	"gskmap_.*"
	"gskShowAllKeyBindings"
	"unlimitededition"
	"pause_after_load"
	"DoNotEnable"
	"_AliasSelectorsInitializer.cfg"
	"gskBindsDoc"
); strSkipRegex="$(echo "${astrSkip[@]}" |tr ' ' '|')"; declare -p strSkipRegex

#helper 'q' reload some cfgs
while ! cd *GSK_ModMerger_AndMiniMods*;do cd ..;done
(find -type f -iregex '.*cfg/.*.cfg') \
	|egrep -v 'SUCCESS|game.cfg|/cfg$' \
	|sed -r -e 's@.*/cfg/(.*)[.]cfg$@ exec \1@g' \
	|sort -u \
	|egrep -v "${strSkipRegex}" \
	|tr '\n' ';' \
	|sed -r -e 's@.*@alias +gskReloadCfgs "gskEchoOn; contimes 50; & echo ReloadedSomeCFGs; "@g' \
	|sed -r -e "s@.*@& // AUTO GENERATED WITH: $(basename "$0")@g" >"${strFlCfg}"
echo >>"${strFlCfg}"
echo "alias -gskReloadCfgs \"gskEchoOff\"" >>"${strFlCfg}"

cat "${strFlCfg}"
ls -l "${strFlCfg}"
	

FUNCrefreshMount # before changes to detect them in the merged folder!!!
