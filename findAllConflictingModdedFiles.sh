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
		if((iCountConflictFl>1));then
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

