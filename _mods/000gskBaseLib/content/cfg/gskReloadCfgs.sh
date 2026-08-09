#!/bin/bash

#helper 'q' reload some cfgs
(cd *993*;find -iregex '.*cfg/.*.cfg') |egrep -v 'SUCCESS|game.cfg|/cfg$' |sed -r -e 's@.*/cfg/(.*)[.]cfg$@ exec \1@g' |sort -u |egrep -v 'auto_load_last_quicksave|gskdevhelpDoNotEnable|gskmap_.*|gskShowAllKeyBindings|unlimitededition|pause_after_load|DoNotEnable' |tr '\n' ';' |sed -r -e 's@.*@alias +gskReloadCfgs "gskEchoOn; contimes 50; & echo ReloadedSomeCFGs; "@g'
