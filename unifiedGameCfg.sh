#!/bin/bash

#	BSD 3-Clause License
#
#	Copyright (c) 2026, Gussak
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

source "./allMergerScriptsGenericConfig.sh"

#set -x
if true;then
	if [[ "${1-}" == "--help" ]];then #help
		#egrep "[#]help" "./allMergerScriptsGenericConfig.sh" "$0"
		SECFUNCshowHelpV2 "./allMergerScriptsGenericConfig.sh"
		SECFUNCshowHelpV2 "$0"
		exit
	fi
	
	mapfile -t astrFlInfoList < <(find "${strPathParent}/" -iname "info.json")
	#declare -p astrFlInfoList
	for strFlInfo in "${astrFlInfoList[@]}";do
		echo
		if egrep -q '"game_configs".*[.]cfg"' "$strFlInfo";then #this will match all "...cfg" but will ignored patched files with "...cfg-"
			declare -p strFlInfo
			cp -v "$strFlInfo" "${strFlInfo}.bkp"
			
			mapfile -t lastrCfgsList < <(FUNCjsonGetArray "$strFlInfo" game_configs)
			for((i=0;i<${#lastrCfgsList[@]};i++));do
				lastrCfgsList[$i]="${lastrCfgsList[i]}-" #this is just to break the filename like "...cfg-" preventing it being found, as it will be loaded thru the unified way
			done
			FUNCjsonSetArray "$strFlInfo" game_configs "${lastrCfgsList[@]}"
		fi
		exit
	done
	
	#mapfile -t astrList < <(
		#find "${strPathParent}/" -iname "info.json" -exec egrep "game_configs" '{}' \; \
			#|grep -o '"[^"]*.cfg"' \
			#|egrep -v "unlimitededition.cfg" \
			#|tr -d '"' 
			##|sed -r -e 's@.*@exec &@g'
	#)
	#declare -p astrList
	#for strFlCfg in "${astrList[@]}";do
		#:
	#done
	
	egrep "exec " "${strPathSelf}/_mods/FinalMergedScriptsMaxPriority/content/cfg/game.cfg"
	
fi
