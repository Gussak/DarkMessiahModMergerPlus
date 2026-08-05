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

#read -p "Press Enter to continue (Ctrl+C to abort)"

if true;then
	while [[ ! -f "./allMergerScriptsGenericConfig.sh" ]];do cd ..;done; source "./allMergerScriptsGenericConfig.sh"; FUNCminiModInit "$@"
	
	: ${strFlGameCfg:=""}
	if ! ls -l "$strFlGameCfg";then
		mapfile -t astrGameCfgFile < <(find ../ -iname "game.cfg" |egrep -v "/dummy/|[.]bkp/|IGNORE_LAYER|/${strGameMainFolderBasename}/|/${strPathMainModFolderBasename}/")
		if((${#astrGameCfgFile[@]} > 1));then
			FUNCechoInfo "Unable to determine the main 'game.cfg' file, please configure it as: export strFlGameCfg='...'"
			exit 1
		else
			strFlGameCfg="${astrGameCfgFile[0]}"
		fi
	fi
	mkdir -vp "${strFinalMergedFolderContent}/cfg/"
	cp -vf "${strFlGameCfg}" "${strFinalMergedFolderContent}/cfg/game.cfg"
	
	mapfile -t astrFlInfoList < <(find -L "${strPathParent}/" -iregex ".*[.]layer.*/info.json" |grep -v IGNORE_LAYER |sort -u)
	#declare -p astrFlInfoList
	lastrCfgsAllList=()
	for strFlInfo in "${astrFlInfoList[@]}";do
		echo
		declare -p strFlInfo
#		if egrep -q '"game_configs".*[.]cfg"' "$strFlInfo";then #this will match all "...cfg" but will ignored patched files with "...cfg-"
		#if egrep -q '"game_configs".*[.]cfg' "$strFlInfo";then
		mapfile -t lastrCfgsList    < <(FUNCjsonGetArray "$strFlInfo" game_configs    )
		mapfile -t lastrCfgsBkpList < <(FUNCjsonGetArray "$strFlInfo" game_configs_bkp)
		declare -p lastrCfgsList lastrCfgsBkpList
		if [[ "${lastrCfgsList[*]}" =~ .*[.]cfg.* ]] || [[ "${lastrCfgsBkpList[*]}" =~ .*[.]cfg.* ]];then
			#if ! egrep -q '"game_configs".*[.]cfg-"' "$strFlInfo";then
			#if [[ ! "${lastrCfgsList[*]}" =~ .*[.]cfg-.* ]];then
			#if ! egrep -q '"game_configs_bkp"' "$strFlInfo";then
			: ${bPatchAllInfoJson:=false} #help This will edit all 'info.json' from all mods. It will move the array inside 'game_configs' into 'game_configs_bkp'. This way, every config file will be loaded thru the order that is configured inside the game.cfg file.
			if $bPatchAllInfoJson;then
				if((${#lastrCfgsBkpList[*]}==0));then
					cp -v "$strFlInfo" "${strFlInfo}.bkp"
					FUNCjsonSetArray "$strFlInfo" game_configs_bkp "${lastrCfgsList[@]}"
					FUNCjsonSetArray "$strFlInfo" game_configs     "" #"${lastrCfgsList[@]}"
				fi
			fi
			
			lastrCfgsAllList+=("${lastrCfgsList[@]}" "${lastrCfgsBkpList[@]}")
			#for((i=0;i<${#lastrCfgsList[@]};i++));do
				#if [[ ! "${lastrCfgsList[i]}" =~ .*[.]cfg-$ ]];then
					#lastrCfgsList[$i]="${lastrCfgsList[i]}-" #this is just to break the filename like "...cfg-" preventing it being found, as it will be loaded thru the unified way
				#fi
			#done
			#declare -p lastrCfgsList
			#FUNCjsonSetArray "$strFlInfo" game_configs "" #"${lastrCfgsList[@]}"
		fi
		#declare -p lastrCfgsAllList;exit
	done
	declare -p lastrCfgsAllList

	echo
	echo "[INFO] EXISTING config files being run at '$strMergedModsFolder'"
	#egrep "exec " "${strPathSelf}/_mods/FinalMergedScriptsMaxPriority/content/cfg/game.cfg"
	egrep "exec " "${strMergedModsFolder}/content/cfg/game.cfg"
	
	echo
	echo "[INFO] (check if the below are missing) append here at a 'content/cfg/game.cfg'. copy from first match found (probably at Overhaul mod)."
	for strFlCfg in "${lastrCfgsAllList[@]}";do
		if [[ "$strFlCfg" =~ ^unlimitededition[.]cfg.* ]];then continue;fi # already at main game.cfg from Overhaul mod
		if [[ "$strFlCfg" =~ ^game[.]cfg.* ]];then continue;fi # prevent recursive crash
		echo "exec ${strFlCfg%-}"
	done
	
	geany --new-instance "${strMergedModsFolder}/content/cfg/game.cfg"
	
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
	

fi

echo "[INFO] the below command will add a debug info in every game.cfg file. Run only once and only if you know what you are doing!"
tail -n 2 $0
#help: clear;find -L ./ -iregex ".*[.]layer.*/game.cfg" -exec bash -c "chmod u+w '{}'; echo -e '\necho \"DEBUG:{}\"' >>'{}'" \;
