#!/bin/bash

# SPDX-License-Identifier: Apache-2.0

while [[ ! -f "./allMergerScriptsGenericConfig.sh" ]];do cd ..;done; source "./allMergerScriptsGenericConfig.sh"; FUNCminiModInit "$@"

if [[ "${1-}" == "--help" ]];then #help
	#egrep "[#]help" "./allMergerScriptsGenericConfig.sh" "$0"
	SECFUNCshowHelpV2 "./allMergerScriptsGenericConfig.sh"
	SECFUNCshowHelpV2 "$0"
	exit
fi

strRegex2=""
strRegex1=""
for strKGMRF in "${astrKnownGameModRelativeFolders[@]}";do
	if [[ -n "${strRegex1}" ]];then strRegex1+="|";fi
	if [[ -n "${strRegex2}" ]];then strRegex2+="|";fi
	strRegex1+="/${strKGMRF}"
	strRegex2+=".*/${strKGMRF}/.*"
done
if $bVerbose;then declare -p strRegex1 strRegex2;fi

#### easy find problems in mods
find -L "${strGameInstallMainFolder}"* -mindepth 1 -maxdepth 1 -type d |egrep -vi "${strDownloadedModFilesRel}|${strDisabledTmpTestFolderRel}|ModLauncher|AdvancedSDK|OverlayFSworkDirDontTouchThis|/mm|/_mods|${strRegex1}|IGNORE_LAYER|${strWriteLayer}|${strVanillaLayer}|${strMergedModsFolder}"&&:
FUNCechoInfo "[INFO] The above helps detect badly installed mods where their readme tells to move the folder(s) of their root into a sub folder tree."
echo

####################################
FUNCechoInfo "[INFO] find all text and script files only from mod folders" 
IFS=$'\n' read -d '' -r -a astrList < <(find -L "${strGameInstallMainFolder}"* -type f -iregex "$strScriptsExtRegexEsc" \
	|egrep -vi "(${strGameInstallMainFolder}/|${strWriteLayer}|${strVanillaLayer}|${strMergedModsFolder}|IGNORE_LAYER|.*[.]sh)" \
	|egrep -i  "(.*/_mods/.*/content/.*|${strRegex2})" \
)&&:
: ${strDebugFilter:=""} #help just shows the full list but filtered to easy debug
if [[ -n "$strDebugFilter" ]];then declare -p astrList |sed -r -e "$strSedArrayLn" |egrep "${strDebugFilter}";echo;fi 

####################################
#function FUNCfileRelat() {
	#local lstrFile="$1"
	
	#if [[ "${lstrFile}" =~ .*/_mods/.* ]];then
		#echo "$lstrFile" |sed -r -e 's@.*/_mods/.*/content/(.*)@\1@I'
	#else
		#echo "$lstrFile" |sed -r -e "s@.*/(${strRegexKGMRF})/(.*)@\2@I"
	#fi
#}

echo
FUNCechoInfo "[INFO] showing only relative paths for files"
IFS=$'\n' read -d '' -r -a astrRelativeList < <(
	iCountWorkingAll=0
	for strFile in "${astrList[@]}";do
		#FUNCechoInfo "#$strFile"
		#echo -n . >&2
		echo -ne "${iCountWorkingAll}\r" >&2
		FUNCfileRelat "${strFile}"
		#if [[ "${strFile}" =~ .*/_mods/.* ]];then
			#echo "$strFile" |sed -r -e 's@.*/_mods/.*/content/(.*)@\1@I'
		#else
			#echo "$strFile" |sed -r -e "s@.*/(${strRegexKGMRF})/(.*)@\2@I"
		#fi
		((iCountWorkingAll++))&&:
	done |sort
)&&:
echo

if $bVerbose;then
	declare -p astrRelativeList |sed -r -e 's@[[]@\n[@g';echo
fi

####################################
echo
FUNCechoInfo "[INFO] showing conflicts"
strRelFlPrev=""
iCountConflictFl=1
strFlLog="$(basename "$0").log"
echo -n >"$strFlLog"
#for strRelFl in "${astrRelativeList[@]}";do
nTotPossibilities=${#astrRelativeList[@]}
iCountTODO=0
iCountWarn=0
iCountDone=0
for((i=0;i<nTotPossibilities;i++));do
	strRelFl="${astrRelativeList[i]}"
	
	if [[ "${strRelFlPrev}" == "${strRelFl}" ]];then
		((iCountConflictFl++))&&:
	fi
	
	# show results for previous or last one
	if [[ "${strRelFlPrev}" != "${strRelFl}" ]] || (( i == (nTotPossibilities-1) ));then
		: ${bBloatListToHelpForceCreatePatches=false} #help Always Process Mod Files Even Without mods Conflicts, will always create patches if differ from vanilla
		if((iCountConflictFl>1)) || $bBloatListToHelpForceCreatePatches;then
			strFlSuccessCfgRel="${strRelFlPrev}.SUCCESS.cfg"
			#declare -p strFlSuccessCfgRel
			strFlPatchSuccess="${strMergedModsFolder}/content/${strFlSuccessCfgRel}"
			if $bVerbose;then declare -p strFlPatchSuccess;fi
			if [[ -f "$strFlPatchSuccess" ]];then
				nTotModsMerged="$(cat "$strFlPatchSuccess" |sed -r -e 's@[[]@\n[@g' |egrep -v "^declare" |wc -l)"
				if((nTotModsMerged != iCountConflictFl));then
					strInfo=" <> <> <> [WARNING:] nTotModsMerged=$nTotModsMerged at '$strFlSuccessCfgRel'"
					((iCountWarn++))&&:
				else
					strInfo="(Already patched)"
					((iCountDone++))&&:
				fi
			else
				strInfo="<<<<<<<<<<<< TODO >>>>>>>>>>>>>"
				((iCountTODO++))&&:
			fi

			echo "${strRelFlPrev} #INFO: iCountConflictFl=$iCountConflictFl $strInfo" |tee -a "$strFlLog"
		fi
		iCountConflictFl=1
	fi
	
	strRelFlPrev="${strRelFl}"
done
echo

FUNCechoInfo "[INFO] results saved at: '$strFlLog', now run ./prepareAllModsPatchesForScriptFile.sh <PlaceEachFileFromLogHere>"
declare -p nTotPossibilities iCountTODO iCountWarn iCountDone

