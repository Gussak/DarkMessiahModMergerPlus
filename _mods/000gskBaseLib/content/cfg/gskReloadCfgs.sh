#!/bin/bash

#	BSD 3-Clause License
#
#	Copyright (c) 2026, Gussak<https://github.com/Gussak>
#
#	Redistribution and use in source and binary forms, with or without
#	modification, are permitted provided that the following conditions are met:
#
#	1. Redistributions of source code must retain the above copyright notice, this
#		 list of conditions and the following disclaimer.
#
#	2. Redistributions in binary form must reproduce the above copyright notice,
#		 this list of conditions and the following disclaimer in the documentation
#		 and/or other materials provided with the distribution.
#
#	3. Neither the name of the copyright holder nor the names of its
#		 contributors may be used to endorse or promote products derived from
#		 this software without specific prior written permission.
#
#	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
#	AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
#	IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
#	DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
#	FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
#	DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
#	SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
#	CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
#	OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
#	OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


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
	
