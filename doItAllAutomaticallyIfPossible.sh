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

while [[ ! -f "./allMergerScriptsGenericConfig.sh" ]];do cd ..;done; source "./allMergerScriptsGenericConfig.sh"; FUNCminiModInit "$@"

#set -x
if true;then
	if [[ "${1-}" == "--help" ]];then #help
		#egrep "[#]help" "./allMergerScriptsGenericConfig.sh" "$0"
		SECFUNCshowHelpV2 "./allMergerScriptsGenericConfig.sh"
		SECFUNCshowHelpV2 "$0"
		exit
	fi

	: ${bBackupFinalMergedFolder:=true} #help
	if $bBackupFinalMergedFolder;then
		if [[ -d "${strMergedModsFolder}" ]];then
			cp -a "${strMergedModsFolder}" "${strMergedModsFolder}.$$.bkp"
			mv -v "${strMergedModsFolder}.$$.bkp/info.json" "${strMergedModsFolder}.$$.bkp/info.json.DISABLED"&&: #this prevents it showing on ModLauncher
			ls -ld "${strMergedModsFolder}" "${strMergedModsFolder}.$$.bkp"
		fi
	fi

	: ${bUpdateTodoList:=true} #help
	if $bUpdateTodoList;then
		./findAllConflictingModdedFiles.sh # checks and updates the TODO list log file
	fi

	function FUNCdoItAll() {
		#local lbJustList=false;if [[ "$1" == --justlist ]];then lbJustList=true;shift;fi
		local lstrWhat="$1";shift
		local lstrComment="$1";shift
		local lastrOpts="$@"
		
		if ! cat findAllConflictingModdedFiles.sh.log |grep "${lstrWhat}";then
			FUNCechoInfo "[Nothing to do for:] work type = '${lstrWhat}'"
			return 0
		fi
		
		FUNCechoInfo "[Review the list above of files to be merged] ${lstrWhat} # ${lstrComment}"
		read -n 1
		
		IFS=$'\n' read -d '' -r -a astrList < <(cat findAllConflictingModdedFiles.sh.log |grep "${lstrWhat}" |sed -r -e 's@(.*) #INFO: .*@\1@g' |sort -u &&:)&&:
		declare -p astrList |sed -r -e "$strSedArrayLn"
	#	for strFl in "${astrList[@]}";do
		for((i=0;i<${#astrList[@]};i++));do
			strFl="${astrList[i]}"
			echo
			
			: ${bClearTerminalOncePerFileMerged:=true} #help good to easily read all the specific file context in case the merger app is called for the user to take action. It will all be logged at final file location.
			if $bClearTerminalOncePerFileMerged;then clear;fi
			
			FUNCechoInfo ">>>>>>>>>>>>>>>>>>>>>>>>>>> [$i/${#astrList[@]}] $strFl <<<<<<<<<<<<<<<<<<<<<<<<<"
			
			#: ${bFollowFolderLayersOrder=false};export bFollowFolderLayersOrder #help for prepareAllModsPatchesForScriptFile.sh
			#: ${bShowFinalComparison=true};export bShowFinalComparison #help for prepareAllModsPatchesForScriptFile.sh
			strFlLog="${strMergedModsFolder}/content/${strFl}.log"
			mkdir -vp "$(dirname "${strFlLog}")" #or tee will fail!
			#declare -p strFlLog
			#echo >"$strFlLog"
			./prepareAllModsPatchesForScriptFile.sh ${lastrOpts[@]} "$strFl" #it is self loggin already now #|tee "$strFlLog"
			FUNCechoInfo "nRet=$?"
		done
	}

	FUNCdoItAll "TODO" ""
	FUNCdoItAll "WARNING" "Re-process the files with warning about changed mod's order and new conflicting mods added? (if not hit Ctrl+C)" --forceRePatch
	
	echo
	cd "$strPathParent";
	strChk="$(egrep "Successfully modified:\s*0" "${strMergedModsFolder}/"* -iRnIa --include="*.log" -c |sed -r "s@${strPathSelf}/@@")"
	if echo "$strChk" |grep -q -v :0;then
		echo "$strChk" |grep -v :0 |sed -r -e 's@(.*)[.]log(:.*)@\1\2@'
		FUNCechoInfo "[WARNING] the above may be a bad thing (found 0 'Successfully modified' requested changes). Better review if the .kvpach.json were really applied for them!"
	fi
	
	FUNCechoInfo "[INFO] You should now run: ./unifiedGameCfg.sh"
fi
