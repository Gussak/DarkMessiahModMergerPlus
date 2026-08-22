#!/bin/bash

# The Clear BSD License
#
# Copyright (c) 2026, Gussak<https://github.com/Gussak>
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted (subject to the limitations in the disclaimer
# below) provided that the following conditions are met:
#
#      * Redistributions of source code must retain the above copyright notice,
#      this list of conditions and the following disclaimer.
#
#      * Redistributions in binary form must reproduce the above copyright
#      notice, this list of conditions and the following disclaimer in the
#      documentation and/or other materials provided with the distribution.
#
#      * Neither the name of the copyright holder nor the names of its
#      contributors may be used to endorse or promote products derived from this
#      software without specific prior written permission.
#
# NO EXPRESS OR IMPLIED LICENSES TO ANY PARTY'S PATENT RIGHTS ARE GRANTED BY
# THIS LICENSE. THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND
# CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
# PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
# BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER
# IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

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
