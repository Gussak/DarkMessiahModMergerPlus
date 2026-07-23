#!/bin/bash

#LINUX_BASH_SCRIPT_HELPER: 
echo {a..z} {0..9} "- = [ ] \ ' , . / ;" |tr ' ' '\n' |while read str;do echo -n "bind $str; ";done
#ISSUE: bind ";" cant be placed in an alias as there is no escape for ", so this fails: alias gskTmp "bind \";\""

#helper 'q' reload some cfgs
(cd *993*;find -iregex '.*cfg/.*.cfg') |egrep -v 'SUCCESS|game.cfg|/cfg$' |sed -r -e 's@.*/cfg/(.*)[.]cfg$@ exec \1@g' |sort -u |egrep -v 'auto_load_last_quicksave|gskdevhelpDoNotEnable|gskmap_.*|gskShowAllKeyBindings|unlimitededition|pause_after_load' |tr '\n' ';' |sed -r -e 's@.*@alias +gskReloadCfgs "developer 1; & echo ReloadedSomeCFGs; "@g'
