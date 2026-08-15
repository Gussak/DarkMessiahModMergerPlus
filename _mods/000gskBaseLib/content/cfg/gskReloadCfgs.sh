#!/bin/bash

#TODO: initial alias selections could all be in a new cfg file that would not be part of the loaded ones like ..._AliasSelectorsInitializer.cfg

astrSkip=(
	"auto_load_last_quicksave"
	"gskdevhelpDoNotEnable"
	"gskmap_.*"
	"gskShowAllKeyBindings"
	"unlimitededition"
	"pause_after_load"
	"DoNotEnable"
	"_AliasSelectorsInitializer.cfg"
); strSkipRegex="$(echo "${astrSkip[@]}" |tr ' ' '|')"; declare -p strSkipRegex

#helper 'q' reload some cfgs
while ! cd *GSK_ModMerger_AndMiniMods*;do cd ..;done
(find -iregex '.*cfg/.*.cfg') \
	|egrep -v 'SUCCESS|game.cfg|/cfg$' \
	|sed -r -e 's@.*/cfg/(.*)[.]cfg$@ exec \1@g' \
	|sort -u \
	|egrep -v "${strSkipRegex}" \
	|tr '\n' ';' \
	|sed -r -e 's@.*@alias +gskReloadCfgs "gskEchoOn; contimes 50; & echo ReloadedSomeCFGs; "@g' \
	|sed -r -e "s@.*@& // AUTO GENERATED WITH: $(basename "$0")@g" 
	
