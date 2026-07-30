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

export FUNCminiModInit_bConsumeParamHelp=false
while [[ ! -f "./allMergerScriptsGenericConfig.sh" ]];do cd ..;done; source "./allMergerScriptsGenericConfig.sh"; FUNCminiModInit "$@"

#: ${nWaitBeforeExiting:=0} #help
#read -n 1 -p "Press a key to exit..." -t $nWaitBeforeExiting&&:
#: ${bDBGforceHoldOnExit:=false} #help
#if $bDBGforceHoldOnExit;then
	#trap 'read -n 1 -p DebugWaitExit&&:;exit 0' EXIT
#fi
: ${nDBGforceHoldTimeOnExit:=0} #help
if((nDBGforceHoldTimeOnExit > 0));then
	trap "read -n 1 -t $nDBGforceHoldTimeOnExit -p DebugWaitExit${nDBGforceHoldTimeOnExit}s && :; exit 0" EXIT
fi

: ${strExecRobustTextEditorEval:='declare -a astrExecRobustTextEditor=([0]="geany" [1]="--new-instance")'} #help
eval "$strExecRobustTextEditorEval";declare -p astrExecRobustTextEditor

#help USAGE: <strScriptFileRelat>

#bRedoAllFiles=false;
: ${bForceRePatch:=false} #help
while [[ $# -gt 0 ]] && [[ "${1:0:1}" == "-" ]];do # checks if param is set
	if [[ "$1" == "--help" ]];then #help show this help
		#egrep "[#]help" "./allMergerScriptsGenericConfig.sh" "$0" |sed -r -e 's@^[ \t]*@@'
		#SECFUNCshowHelpV2 "./allMergerScriptsGenericConfig.sh"
		#SECFUNCshowHelpV2 "$0"
		FUNCechoInfo "Usage Example: $0 -f <strScriptFileRelat> # see above"
		FUNCexit 0
	elif [[ "$1" == "-f" || "$1" == "--forceRePatch" ]];then #help
		bForceRePatch=true
	#elif [[ "$1" == --redoall ]];then #help REDO the work on all files at the Final merged folder
		#bRedoAllFiles=true
	else
		FUNCechoInfo "[invalid option] '$1'"
		$0 --help #$0 considers ./, works best anyway..
		FUNCexit 1
	fi
	shift&&:
done

: ${strScriptFileRelat:="${1-}"} #help provide a relative path (as mods may implement variants in other sub paths, like arena mod, that shall not affect the main game) ex.: "scripts/spells.txt" will be prepended with "*/" becoming "*/scripts/spells.txt" and matching like _mods folder like ".../content/scripts/spells.txt", main game like ".../mm/scripts/spells.txt"
if [[ -z "$strScriptFileRelat" ]];then FUNCechoInfo "[invalid] strScriptFileRelat='' is empty"; FUNCexit 1;fi
exec > >(tee "$strFinalMergedFolderContent/${strScriptFileRelat}.log") 2>&1

FUNCchkDeps jq colordiff patch

#astrWorkDB=()
#strFlWorkDatabase="$(basename "$0").cfg"
#if [[ -f "$strFlWorkDatabase" ]];then
	#source "$strFlWorkDatabase"
	#if $bVerbose;then declare -p astrWorkDB |sed -r -e "$strSedArrayNumToLn";fi
	#if $bRedoAllFiles;then
		#for strFlWDB in "${astrWorkDB[@]}";do
			#FUNCechoInfo "[WorkDB] '$strFlWDB'"
			#read -n 1&&:
			#bForceRePatch=true "$0" "$strFlWDB"
		#done
		#FUNCexit
	#fi
#fi

: ${bShowDiffPerFile:=false} #help
: ${nFuzzyPatch:=0} #help try nFuzzyPatch=1 This may help to make it easier to provide an initial auto merge? better just review the results...

if $bForceRePatch;then
	FUNCtrash "$strFinalMergedFolderContent/$strScriptFileRelat" "$strFinalMergedFolderContent/${strScriptFileRelat}.SUCCESS.cfg"&&:
fi

if [[ "$strScriptFileRelat" != "gameinfo.txt" ]];then #help is this the only file that ever happens on root mod dir? TODO
	if [[ ! "$strScriptFileRelat" =~ .*/.* ]] || [[ "$strScriptFileRelat" =~ ^[/].* ]];then
		declare -p strScriptFileRelat
		FUNCechoInfo "[Invalid relative file] all text script etc files are relative to some sub directory in vanilla tree. Also do not use absolute file paths."
		FUNCexit 1
	fi
fi
strFindScriptFileRegex=".*/\(${strRegexEscKGMRF}\)/${strScriptFileRelat}\(\.patch\|\.kvpatch\.json\)?\$"
if $bVerbose;then declare -p strFindScriptFileRegex;fi

: ${strFlLastOneAlwaysWinList:="scripts/mm_skills_infos.txt"} #help comma separated relative file paths. The last one found will override every other mod that modifies it, and will just patch vanilla directly.
mapfile -t -d "," astrFlLastOneAlwaysWinList < <( echo -n "$strFlLastOneAlwaysWinList" )

strThisFolder="$(pwd)"
#strThisFolderBN="$(basename "${strThisFolder}")"

#help This bash script will look on the parent folder for all mergeable script or text files you passed as main parameter. Each will be considered as layers to be merged in a single final folder. The load order priority is from the ModLauncher main mod, then the order you prepared by naming the folders properly with numbered layers. Each folder must have the contents of one extracted game mod file.
mapfile -t astrListFoldersLayersOrderOriginal < <(
	find -L "${strGameInstallMainFolder}"* -iregex "${strFindScriptFileRegex}" \
		|sort \
		|egrep "[.]layer" \
		|egrep -v "${strRegexFoldersToIgnore}|${strMergedModsFolderBN}|${strVanillaScriptsPath}|${strVanillaLayer}" \
			2>/dev/null
)
# Fix the list to only have final file references
for((i=0;i<${#astrListFoldersLayersOrderOriginal[@]};i++));do
	strTmp="${astrListFoldersLayersOrderOriginal[$i]}"
	if [[ "${strTmp}" =~ .*([.]patch|[.]kvpatch[.]json)$ ]];then
		strTmp="${strTmp%.patch}"
		strTmp="${strTmp%.kvpatch.json}"
		astrListFoldersLayersOrderOriginal[$i]="${strTmp}"
	fi
done
# Fix the list to have no dups
mapfile -t astrListFoldersLayersOrderOriginal < <(
	for strTmp in "${astrListFoldersLayersOrderOriginal[@]}";do
		echo "$strTmp"
	done |sort -u
)
echo;declare -p astrListFoldersLayersOrderOriginal |sed -r -e "$strSedArrayNumToLn";echo
astrListFoldersLayersOrder=("${astrListFoldersLayersOrderOriginal[@]}")

: ${strFlModLoadSett:="${strPathParent}/Dark Messiah Might and Magic Single Player/_mods/core/user_settings.json"} #help This is the main game folder, also is the final merged folder from OverlayFS
if [[ ! -f "$strFlModLoadSett" ]];then
	# this below is where it is written by OverlayFS or equivalent if you setup it like that, but in this case, OverlayFS is not running
	strFlModLoadSett="${strPathParent}/Dark Messiah Might and Magic Single Player.0.WriteLayer/_mods/core/user_settings.json";
fi
if [[ ! -f "$strFlModLoadSett" ]];then
	FUNCechoInfo "ModLauncher settings file not found where expected '${strPathParent}/Dark Messiah Might and Magic Single Player/_mods/core/user_settings.json'"
	FUNCexit 1
fi

function FUNCmodLauncherIgnoredMod() {
	local lstrLayer="$1"
	local lstrModLauncherModFolder
	for lstrModLauncherModFolder in "${astrModLauncherOrderList[@]}";do
		if [[ "${lstrLayer}" =~ .*/_mods/${lstrModLauncherModFolder}/content/.* ]];then
			local lstrModLauncherIgnoreFolder
			for lstrModLauncherIgnoreFolder in "${astrModLauncherIgnoreList[@]}";do
				if [[ "${lstrModLauncherModFolder}" == "${lstrModLauncherIgnoreFolder}" ]];then
					return 0
				fi
			done
		fi
	done
	return 1
}

mapfile -t astrModLauncherOrderList < <(
	#FUNCjson "$strFlModLoadSett" ".load_order[]" |sed -r -e 's@^"@@' -e 's@"$@@'
	FUNCjsonGetArray "$strFlModLoadSett" "load_order" |sed -r -e 's@^"@@' -e 's@"$@@'
)
mapfile -t astrModLauncherIgnoreList < <(
	#FUNCjson "$strFlModLoadSett" ".ignore[]" |sed -r -e 's@^"@@' -e 's@"$@@'
	FUNCjsonGetArray "$strFlModLoadSett" "ignore" |sed -r -e 's@^"@@' -e 's@"$@@'
)
echo;declare -p astrModLauncherOrderList |sed -r -e "$strSedArrayNumToLn";echo
astrListCurrent=()
astrListFromModLauncher=()
#set +x
for strModLauncherModFolder in "${astrModLauncherOrderList[@]}";do
#	for strLayer in "${astrListFoldersLayersOrder[@]}";do
	for((i=0;i<${#astrListFoldersLayersOrder[@]};i++));do
		strLayer="${astrListFoldersLayersOrder[i]}"
		if [[ "${strLayer}" =~ .*/_mods/${strModLauncherModFolder}/content/.* ]];then
			bIgnoreModFolder=false
			for strModLauncherIgnoreFolder in "${astrModLauncherIgnoreList[@]}";do
				if [[ "${strModLauncherModFolder}" == "${strModLauncherIgnoreFolder}" ]];then
					bIgnoreModFolder=true
					break;
				fi
			done
			if ! $bIgnoreModFolder;then
				astrListFromModLauncher+=("${strLayer}")
			fi
			unset astrListFoldersLayersOrder[$i]
			break;
		fi
	done
	astrListFoldersLayersOrder=("${astrListFoldersLayersOrder[@]}") # clear unset indexes
done
echo;declare -p astrListFoldersLayersOrder |sed -r -e "$strSedArrayNumToLn";echo
echo;declare -p astrListFromModLauncher |sed -r -e "$strSedArrayNumToLn";echo
astrListCurrent=("${astrListFoldersLayersOrder[@]}" "${astrListFromModLauncher[@]}") # remaining folders at astrListFoldersLayersOrder will be overriden by the ones from ModLauncher list order
echo
FUNCechoInfo "[list with overriden by the ones from ModLauncher list order]"
declare -p astrListCurrent |sed -r -e "$strSedArrayNumToLn";echo
if((${#astrListCurrent[@]} < 2));then
	FUNCechoInfo "[Nothing to merge] is needed 2 or more to merge"
	FUNCexit
fi

: ${bFollowFolderLayersOrder:=""} #help bFollowFolderLayersOrder=false to use ModLaucher order before other mods not using it. bFollowFolderLayersOrder=true will just follow folders alphanumeric order so you need to grant the priority properly naming them. bFollowFolderLayersOrder="" will show a message and wait. Tho, anyway, ModMerger will prioritize it's order also over mods non compatible with it, so FinalMergedScriptsMaxPriority mod must be last one there to this all work, as FinalMergedScriptsMaxPriority actually works are a max priority overrider.
if [[ -z "$bFollowFolderLayersOrder" ]];then
	if [[ "${astrListCurrent[@]}" != "${astrListFoldersLayersOrder[@]}" ]];then
		FUNCechoInfo "[The folders layers order differ from following ModLauncher setting list order]"
		FUNCechoInfo "[ModLauncher setting list order will be prefered] Unless you set bFollowFolderLayersOrder=true (hit Ctrl+c to set it)"
		FUNCechoInfo "[Press a key to continue.]"
		read -n 1
	fi
else
	if $bFollowFolderLayersOrder;then
		astrListCurrent=()
		astrListCurrentChk=("${astrListFoldersLayersOrderOriginal[@]}")
		#for((i=0;i<${#astrListCurrent[@]};i++));do
			#strChkLayer="${astrListCurrent[$i]}"
		for strChkLayer in "${astrListCurrentChk[@]}";do
			if ! FUNCmodLauncherIgnoredMod "$strChkLayer";then
				astrListCurrent+=("$strChkLayer")
			fi
		done
		echo
		FUNCechoInfo "[list following Folders Layers Order]"
		declare -p astrListCurrent |sed -r -e "$strSedArrayNumToLn";echo
	fi
fi

for strLastOneWins in "${astrFlLastOneAlwaysWinList[@]}";do
	if [[ "$strLastOneWins" == "$strScriptFileRelat" ]];then
		astrListCurrent=("${astrListCurrent[$((${#astrListCurrent[*]}-1))]}")
		declare -p astrListCurrent |sed -r -e "$strSedArrayNumToLn";echo
		break;
	fi
done

function FUNCgetEncoding_Work() {
	local lLn="$1";shift
	if ! [[ -f "$1" ]];then
		FUNCwait "[ERROR:${FUNCNAME[@]}:CalledAtLn${lLn}] invalid file '$1'"
	fi
	file -bi "$1" |sed -r -e 's@text/plain; charset=(.*)$@\1@g'; 
};export -f FUNCgetEncoding_Work;alias FUNCgetEncoding='FUNCgetEncoding_Work $LINENO '
function FUNCcheckEncodingUTF8_Work() { #help <LINENO> <file>
	local lLn="$1";shift
	if ! [[ -f "$1" ]];then
		FUNCwait "[ERROR:${FUNCNAME[@]}:CalledAtLn${lLn}] invalid file '$1'"
	fi
	while [[ $# -gt 0 ]];do
		if [[ "$(FUNCgetEncoding "$1")" != "utf-8" ]];then
			echo "[ERROR_BUG:${FUNCNAME[@]}:CalledAtLn${lLn}] shall only work with UTF-8: found '$(FUNCgetEncoding "$1")' at '$1'" >&2
			exit 1;
		fi;
		shift
	done
	return 0
};export -f FUNCcheckEncodingUTF8_Work;alias FUNCcheckEncodingUTF8='FUNCcheckEncodingUTF8_Work $LINENO '

function FUNCexecMerger() {
	local lastrParams=()
	local lbAlert=false
	while [[ $# -gt 0 ]];do
		local lstrParam="$1"
		shift
		
		if [[ "$lstrParam" == --alert ]];then
			lbAlert=true
			continue
		fi
		if [[ -f "$lstrParam" ]];then
			FUNCcheckEncodingUTF8 "$lstrParam"
			lastrParams+=("$lstrParam")
			
			#local lstrEnc="$(file -bi "$lstrParam")"
			#case "$strEncodingVanilla" in
				#us-ascii|utf-16le|iso-8859-1)
					#:
					#;;
				#*)
					#echo "'$lstrParam'"
					#ls -l "$lstrParam"
					#FUNCechoInfo "[WARN] not validated/patched encoding yet, this file above is: '$lstrEnc'"
					#;;
			#esac
		fi
	done
	
	#: ${strMergerBlackList:="resource/mm_itemnames_english.txt"} #causes too much trouble on mergers, comma separated
	: ${strMergerBlackList:=""} #causes too much trouble on mergers, comma separated
	mapfile -t astrMergerBlackList < <(echo "$strMergerBlackList" |tr ',' '\n')
	bMB=false
	for strMB in "${astrMergerBlackList[@]}";do
		if [[ "$strScriptFileRelat" == "${strMB}" ]];then
			bMB=true
			break;
		fi
	done
	
	if $lbAlert;then
		FUNCsay "PROBLEM: Manual Merging Required"
	else
		FUNCsay "Merge result is ready to check."
	fi
	
	if $bMB;then
		FUNCechoInfo "[PROBLEM] wont open merger for '${strScriptFileRelat}', it can't handle that. Opening a robust text editor instead:"
		"${astrExecRobustTextEditor[@]}" "${lastrParams[@]}"
	else
		set -x;"${strExecMerger}" "${lastrParams[@]}";set +x
	fi
}

function FUNCprePatchChk() { #help <lstrFlChk>
	local lstrFlChk="$1"
	local lbPrePatchFail=false
	while ! ./kvSanityChecker.sh "$lstrFlChk";do
		local lstrPrePatchVanilla="$strPathMainModFolder/VanillaPrePatches/${strScriptFileRelat}.patch"
		declare -p lstrPrePatchVanilla
		if ! $lbPrePatchFail;then
			if [[ -f "$lstrPrePatchVanilla" ]];then
				local lacmdPatch=(patch -F $nFuzzyPatch -i "${lstrPrePatchVanilla}" -o "${lstrFlChk}.PRE_PATCH" "$lstrFlChk") #patch [ORIGINAL_FILE] -i [PATCH_FILE] -o [OUTPUT_FILE]
				FUNCechoInfo "[ExecPrePatch] ${lacmdPatch[*]}"
				if "${lacmdPatch[@]}";then
					chmod -v u+w "$lstrFlChk"
					mv -vf "${lstrFlChk}.PRE_PATCH" "$lstrFlChk"
					continue
				else
					FUNCechoInfo "[WARN] prepatching failed: ${lacmdPatch[*]}"
					lbPrePatchFail=true
				fi
			else
				FUNCechoInfo "[WARN] prepatch file not found: $lstrPrePatchVanilla"
			fi
		fi
		FUNCsay "Database Sanity Failed"
		FUNCaskYesNo "[PROBLEM:Ln$LINENO] Fix it (the right one) manually according to the sanity check above please (if not will just exit or the game may will crash)"
		#FUNCexecMerger --alert "$strVanillaScriptFile" "$lstrFlChk"
		"${astrExecRobustTextEditor[@]}" "$strVanillaScriptFile" "$lstrFlChk" # an editor that can fold nestings and detect their open/close is better for this
	done
}

FUNCconvEncToUTF8BOM() { #help <strEncodingVanilla> <input> <output>
	(printf '\xEF\xBB\xBF'; iconv -f "$1" -t UTF-8 "$2") |sponge "${3}.UTF-8" # this makes it UTF-8-BOM and is detected as UTF-8 by text editors and `file -bi ...`
}

strEncodingRestore=""
FUNCconvEncoding() {
	strEncodingVanilla="$(FUNCgetEncoding "$strVanillaScriptFile")"
	case "$strEncodingVanilla" in
		us-ascii|utf-16le|iso-8859-1)
			strEncodingRestore="$strEncodingVanilla"
			;;
		*)
			#FUNCechoInfo "[PROBLEM] may not work well with encodings different of '$strEncodingOK' and '$strEncodingUTF16LE', this vanilla is: '$strEncodingVanilla'"
			FUNCechoInfo "[ERROR] encoding not supported yet: $strEncodingVanilla"
			exit 1
			;;
	esac
	chmod -v u+w "${strVanillaScriptFile}.UTF-8"&&: # to easy overwrite if it exists
	#iconv -f "$strEncodingVanilla" -t UTF-8 "$strVanillaScriptFile" > "${strVanillaScriptFile}.UTF-8"
	#(printf '\xEF\xBB\xBF'; iconv -f "$strEncodingVanilla" -t UTF-8 "$strVanillaScriptFile") > "${strVanillaScriptFile}.UTF-8" # this makes it UTF-8-BOM and is detected as UTF-8 by text editors and `file -bi ...`
	FUNCconvEncToUTF8BOM "$strEncodingVanilla" "$strVanillaScriptFile" "${strVanillaScriptFile}.UTF-8"
	strVanillaScriptFile="${strVanillaScriptFile}.UTF-8"
}

strVanillaScriptFile="$(find -L "$strVanillaScriptsPath" -iregex "${strFindScriptFileRegex}")"
bDummyVanilla=false
if [[ -f "$strVanillaScriptFile" ]];then
	FUNCconvEncoding
	FUNCcheckEncodingUTF8 "$strVanillaScriptFile"
	if ! ./kvSanityChecker.sh "$strVanillaScriptFile";then
		bDummyVanilla=true;
		strDummyMsgType=FailedSanityCheck
		FUNCcheckEncodingUTF8 "$strVanillaScriptFile"
	fi
else
	bDummyVanilla=true
	strDummyMsgType=MissingVanilla
fi
#bFlVanilla=false;if [[ -f "$strVanillaScriptFile" ]];then bFlVanilla=true;fi
if $bDummyVanilla;then
	#FUNCechoInfo "[WARNING: There is no such Vanilla] create it there empty: '${strVanillaScriptsPath}/mm/$strScriptFileRelat'"
	#FUNCechoInfo "[Merge existing one from mods anyway?] Ctrl+C to abort"
	##read -n 1&&:
	##FUNCexit 1
	#bFlVanilla=false
	#bDummyVanilla=true
	case "$strDummyMsgType" in
		MissingVanilla) 
			strVanillaScriptFile="${strFinalDummyHelperFolder}/${strScriptFileRelat}"
			mkdir -vp "$(dirname "$strVanillaScriptFile")"
			#if [[ ! -f "$strVanillaScriptFile" ]];then #TODO redundant?
				#cp "${astrListCurrent[0]}" "$strVanillaScriptFile" # see info below for being the first file on the list
				#if [[ -z "$strEncodingRestore" ]];then FUNCconvEncoding;fi #TODO useless?
			#fi
			cp -v "${astrListCurrent[0]}" "$strVanillaScriptFile" # see info below for being the first file on the list
			
			FUNCechoInfo "[WARNING: There is no such Vanilla File] created a dummy one '${strVanillaScriptFile}' with the contents of the first one found '${astrListCurrent[0]}' in the list of MODs, it will be deleted later." 
			
			FUNCconvEncoding
			;;
		FailedSanityCheck)
			FUNCechoInfo "[WARNING: Failed Sanity Check] created a dummy one to fix it '${strVanillaScriptFile}' in the list of MODs, it will be deleted later." 
			;;
		*) FUNCechoInfo "[DEV_ERROR_BUG] reason not specified";;
	esac
	FUNCcheckEncodingUTF8 "$strVanillaScriptFile"
	FUNCprePatchChk "$strVanillaScriptFile" #working on dummy
fi
chmod ugo-w "$strVanillaScriptFile"
ls -l "$strVanillaScriptFile"
strVanillaScriptFileOriginal="$strVanillaScriptFile"

nBkpIndex=0

######## MAIN ########

: ${bApplyEachPatch:=true} #help to finalize the merge work properly
if $bApplyEachPatch;then
	strFlWork="${strFinalMergedFolderContent}/${strScriptFileRelat}"
	if $bVerbose;then declare -p strFlWork;fi
	
	strFlSuccessCfg="${strFlWork}.SUCCESS.cfg"
	
	if [[ -f "$strFlWork" ]] && [[ -f "$strFlSuccessCfg" ]];then
		echo;ls -l "$strFlSuccessCfg"
		source "$strFlSuccessCfg" #astrListSUCCESS
		
		bAlreadyFullyPatched=true
		for((i=0;i<${#astrListSUCCESS[@]};i++));do
			if [[ "${astrListSUCCESS[i]}" != "${astrListCurrent[i]}" ]];then
				bAlreadyFullyPatched=false
				break;
			fi
		done
		
		if $bAlreadyFullyPatched;then
			#declare -p astrListCurrent |sed -r -e "$strSedArrayNumToLn"
			if $bVerbose;then declare -p astrListSUCCESS |sed -r -e "$strSedArrayNumToLn";fi
			FUNCechoInfo "[File alredy fully patched with the same existing mods.]"
			FUNCexit
		else
			colordiff <(declare -p astrListSUCCESS |sed -r -e "$strSedArrayNumToLn") <(declare -p astrListCurrent |sed -r -e "$strSedArrayNumToLn")&&:
			FUNCechoInfo "[File alredy fully patched but mods list changed, repatch ? ] Ctrl+C to abort"
			read -n 1&&:
			FUNCtrash "$strFlSuccessCfg"
		fi
	fi
	
	FUNCtrash "$strFlWork" "$strFlSuccessCfg"&&:
	#for((i=0;i<${#astrWorkDB[@]};i++));do
		#if [[ "${astrWorkDB[i]}" == "$strScriptFileRelat" ]];then
			#unset astrWorkDB[$i]
			#break;
		#fi
	#done
	
	# init final work file
	mkdir -vp "$(dirname "$strFlWork")"
	cp -v "$strVanillaScriptFile" "$strFlWork"
	chmod -v u+w "$strFlWork"
	
	strFlPreviouslyPatched="${strFlWork}.PREVIOUSLY_PATCHED_FILE"
	
	FUNCtrash "$strFlPreviouslyPatched"&&:
fi

echo
#for strFileToMerge in "${astrListCurrent[@]}";do
astrEasyLogReview=()
nCols=$(tput cols)
if [[ "$nCols" =~ ^[0-9]*$ ]];then strFullLineVisualDelimiter="$(echo;eval printf '=%.0s' {1..${nCols}})";fi #KEEPinfo eval is properly protected
for((i=0;i<${#astrListCurrent[@]};i++));do
	echo "$strFullLineVisualDelimiter"
	
	strFileToMerge="${astrListCurrent[i]}"
	
	strInfo="[Working with][$((i+1))/${#astrListCurrent[@]}] '$(echo "$strFileToMerge" |egrep -o "[.]layer.*")'"
	astrEasyLogReview+=("$strInfo")
	echo;FUNCechoInfo "$strInfo"
	
	bKeyValueDiffMode=false
	if strFlPatch="$(FUNCpatchMode "${strFileToMerge}")";then
		bKeyValueDiffMode=true
	fi
	
	: ${bForceRecreatePatches:=true} #help
	if ! $bForceRecreatePatches && [[ -f "$strFlPatch" ]];then
		FUNCechoInfo "[Skip patch creation, ready already]"
		ls -l "${strFlPatch}"
	else
		if [[ -f "$strFileToMerge" ]];then
			#strFlOrig=".tmp.fileOriginal.txt"
			#strFlModd=".tmp.fileModded__.txt"
			if $bKeyValueDiffMode;then
				#KEEPinfo: this implicitly creates the same "${strFileToMerge}.kvpatch.json": "${strPathSelf}/keyValuePatcher.py" create <(iconv -f $(file -b --mime-encoding "$strVanillaScriptFile") -t UTF-8 "$strVanillaScriptFile") "$strFileToMerge"&&:;nDiffRet=$? #but the below is more clear and can handle mismatching encodings
				set -x
				#iconv -f $(file -b --mime-encoding "$strVanillaScriptFile") -t UTF-8 "$strVanillaScriptFile" >"$strFlOrig"
				#iconv -f $(file -b --mime-encoding "$strFileToMerge"      ) -t UTF-8 "$strFileToMerge"       >"$strFlModd"
				#"${strPathSelf}/keyValuePatcher.py" create -o "${strFlPatch}" "$strFlOrig" "$strFlModd" &&:;
				"${strPathSelf}/keyValuePatcher.py" create \
					-o "${strFlPatch}" \
					<(iconv -f $(file -b --mime-encoding "$strVanillaScriptFile") -t UTF-8 "$strVanillaScriptFile") \
					<(iconv -f $(file -b --mime-encoding "$strFileToMerge"      ) -t UTF-8 "$strFileToMerge"      ) \
					&&:;
				nDiffRet=$?
				set +x
			else # code patch mode
				( # prepare the patch using relative path to remove user name
					cd "${strPathParent}"
					set -x
					set -o pipefail # so the diff exit value will be captured with $? if using |tee
					#iconv -f $(file -b --mime-encoding "$strVanillaScriptFile") -t UTF-8 "$strVanillaScriptFile" >"$strFlOrig"
					#iconv -f $(file -b --mime-encoding "$strFileToMerge"      ) -t UTF-8 "$strFileToMerge"       >"$strFlModd"
					#diff -u "$strFlOrig" "$strFlModd" >"${strFlPatch}";nRet=$?
					diff -u \
						<(iconv -f $(file -b --mime-encoding "$strVanillaScriptFile") -t UTF-8 "$strVanillaScriptFile") \
						<(iconv -f $(file -b --mime-encoding "$strFileToMerge"      ) -t UTF-8 "$strFileToMerge"      ) \
							>"${strFlPatch}";nRet=$?
							#KEEPinfo: too much unnecessary log: #					|tee "${strFlPatch}";nRet=$?
					set +o pipefail # to not mess other things like grep
					declare -p nRet
					set +x
					exit $nRet #KeepInfo dont use FUNCexit for captured exit values on subshells!
				)&&:;nDiffRet=$?
			fi
		else #if [[ -f "$strFileToMerge" ]];then
			FUNCechoInfo "[WARNING] unable to recreate the patch as modded file does not exist: '$strFileToMerge'"
			FUNCechoInfo "[INFO] using the patch to re-create the modded file: '$strFileToMerge'"
			if $bKeyValueDiffMode;then
				acmdPatch=("${strPathSelf}/keyValuePatcher.py" apply --prettify --append-missing --output "${strFileToMerge}.RECREATED_MODDED" "$strVanillaScriptFile" "${strFlPatch}") #keyValuePatcher.py apply [-h] [-o OUTPUT] [-a] target patch
			else
				acmdPatch=(patch -F $nFuzzyPatch -i "${strFlPatch}" -o "${strFileToMerge}.RECREATED_MODDED" "$strVanillaScriptFile") #patch [ORIGINAL_FILE] -i [PATCH_FILE] -o [OUTPUT_FILE]
			fi
			nDiffRet=0 # means there is no patch available
			set -x;"${acmdPatch[@]}"&&:;nRetPatch=$?;set +x
			#if FUNChasBOM "$strVanillaScriptFile";then
				#FUNCfixBOM "${strFileToMerge}.RECREATED_MODDED"
			#fi
			if((nRetPatch==0));then
				mv -vf "${strFileToMerge}.RECREATED_MODDED" "${strFileToMerge}"
				nDiffRet=1 # assuming success already in the past
			else
				FUNCechoInfo "[ERROR] unable to recreate the modded file by applying the patch using the vanilla file, modded would be: '${strFileToMerge}'"
				echo -n >>"${strFileToMerge}" # creates and empty "modded" file if it doesnt exist ...
				nDiffRet=2 #... to help open merger tool later
			fi
			#if $bKeyValueDiffMode;then
				#if [[ -f "${strFileToMerge}.kvpatch.json" ]];then
					#nDiffRet=1 # success already in the past
				#fi
			#else
				#if [[ -f "${strFileToMerge}.patch" ]];then
					#nDiffRet=1 # success already in the past
				#fi
			#fi
		fi
		
		if $bVerbose;then declare -p nDiffRet;fi
		case $nDiffRet in
			0) FUNCechoInfo "[Identical] Skip"; continue;;
			1) 
				FUNCechoInfo "[Diff PATCH from MOD vs Vanilla creation (((OK))) ]"
				if $bShowDiffPerFile;then
					FUNCexecMerger "$strVanillaScriptFile" "$strFileToMerge"
				fi
				;;
			2) 
				FUNCechoInfo "[WARNING: diff trouble] try manually"; #this ever happens?
				FUNCexecMerger --alert "$strVanillaScriptFile" "$strFileToMerge";
				;;
			*) FUNCechoInfo "[ERROR: unrecognized diff return value]";FUNCexit 1;;
		esac
		
		ls -l "${strFlPatch}"
		realpath "${strFlPatch}"
	fi
	
	if $bApplyEachPatch;then
		cp -v "${strFlWork}" "$strFlPreviouslyPatched"
		chmod ugo-w "$strFlPreviouslyPatched" #help if you want to modify a patch, do it in a new mod folder layer instead of using "$strExecMerger" 3way
		
		bMergedManually=false
#		acmdPatch=(patch -F $nFuzzyPatch "$strFlWork" "${strFlPatch}")
		if $bKeyValueDiffMode;then
			acmdPatch=("${strPathSelf}/keyValuePatcher.py" apply --prettify --append-missing --output "${strFlWork}.NEWLY_PATCHED" "$strFlWork" "${strFlPatch}") #keyValuePatcher.py apply [-h] [-o OUTPUT] [-a] target patch
		else
			acmdPatch=(patch -F $nFuzzyPatch -i "${strFlPatch}" -o "${strFlWork}.NEWLY_PATCHED" "$strFlWork") #patch [ORIGINAL_FILE] -i [PATCH_FILE] -o [OUTPUT_FILE]
		fi
		#declare -p acmdPatch
		ls -l "$strFlWork"
		set -x;"${acmdPatch[@]}"&&:;nRetPatch=$?;set +x
		#if FUNChasBOM "$strVanillaScriptFile";then
			#FUNCfixBOM "${strFlWork}.NEWLY_PATCHED"
		#fi
		ls -l "$strFlWork"
		if((nRetPatch==0));then
			mv -vf "$strFlWork" "$strFlWork.$nBkpIndex.bkp"
			mv -vf "${strFlWork}.NEWLY_PATCHED" "$strFlWork"
		else
			FUNCechoInfo "[ERROR: patch failed] if it is a compatibility patch (that is just merging other mods) may work just to disable the file by renaming it to ex.: filename.ext.DISABLED"
			if $bVerbose;then declare -p acmdPatch;fi
			FUNCechoInfo "[Please patch manually with '$strExecMerger'. The left one is always the vanilla. The middle one is the new patch to be merged. The final file receiving all the patches is on the right.]"
			: ${bAutoOpenManualMergeRequest:=true} #help
			if ! $bAutoOpenManualMergeRequest;then
				read -n 1&&:
			fi
			chmod ugo-w "$strFileToMerge" #help this is important to prevent changing the mod file. The point is just to apply the changes on the final file!
			cp -vf "$strFlWork" "$strFlWork.$nBkpIndex.bkp"
			chmod -v u+w "$strFlWork"
			declare -p astrEasyLogReview |sed -r -e "${strSedArrayNumToLn}"
			FUNCexecMerger --alert "$strVanillaScriptFile" "$strFileToMerge" "$strFlWork" #help manual merge required. show vanilla on the left just to try to guess what to do.
			FUNCechoInfo "nRet=$?"
			bMergedManually=true
		fi
		((nBkpIndex++))&&:
		FUNCtrash "${strFlWork}.orig" "${strFlWork}.rej" &&:
		
		: ${bShow3wayDiffAfterEachPatch:=false} #help only with "$strExecMerger". This will show on the right the final file being modified per step!
		if ! $bMergedManually && $bShow3wayDiffAfterEachPatch;then
			: ${bCompareVanillaInTheMiddle:=false} #help otherwise will put in the middle the previously patched file so you can see each difference per patching step that is better to understand what is happening.
			if $bCompareVanillaInTheMiddle;then
				FUNCexecMerger "$strFileToMerge" "$strVanillaScriptFile" "$strFlWork"
			else
				FUNCexecMerger "$strFileToMerge" "$strFlPreviouslyPatched" "$strFlWork"
			fi
		fi
		
		FUNCtrash "$strFlPreviouslyPatched"
	fi
	
	bFirstFileWork=false
	echo
done

echo "$strFullLineVisualDelimiter"

#bPrePatchFail=false
#while ! ./kvSanityChecker.sh "$strFlWork";do
	#strPrePatchVanilla="$strPathMainModFolder/VanillaPrePatches/${strScriptFileRelat}.patch"
	#declare -p strPrePatchVanilla
	#if ! $bPrePatchFail && [[ -f "$strPrePatchVanilla" ]];then
		#acmdPatch=(patch -F $nFuzzyPatch -i "${strPrePatchVanilla}" -o "${strFlWork}.PRE_PATCH" "$strFlWork") #patch [ORIGINAL_FILE] -i [PATCH_FILE] -o [OUTPUT_FILE]
		#FUNCechoInfo "[ExecPrePatch] ${acmdPatch[*]}"
		#if "${acmdPatch[@]}";then
			#mv -vf "${strFlWork}.PRE_PATCH" "$strFlWork"
			#continue
		#else
			#FUNCechoInfo "[WARN] prepatching failed: ${acmdPatch[*]}"
			#bPrePatchFail=true
		#fi
	#fi
	#FUNCsay "Database Sanity Failed"
	#FUNCaskYesNo "[PROBLEM] Fix it (the right one) manually according to the sanity check above please (if not will just exit or the game may will crash)"
	#FUNCexecMerger --alert "$strVanillaScriptFile" "$strFlWork"
#done
#FUNCprePatchChk "$strFlWork"
if ! ./kvSanityChecker.sh "$strFlWork";then
	FUNCsay "Ln$LINENO: Database Sanity Failed"
	FUNCechoInfo "[WARN] It is better to create a VanillaPrePatches file."
	FUNCaskYesNo "[PROBLEM:Ln$LINENO] Fix it (the right one) manually according to the sanity check above please (if not will just exit or the game may will crash)"
	FUNCexecMerger --alert "$strVanillaScriptFile" "$strFlWork"
fi

: ${bShowFinalComparison:=true} #help compare vanilla with fully mods merged file after all mods merging end for it
if $bShowFinalComparison;then
	FUNCechoInfo "[Showing final merge comparison with vanilla]"
	echo "'$strVanillaScriptFile'"
	echo "'$strFlWork'"
	FUNCcheckEncodingUTF8 "$strVanillaScriptFile" "$strFlWork"
	FUNCexecMerger "$strVanillaScriptFile" "$strFlWork"
fi


##################################################################################
##################### RESTORE ENCODING, be careful below here ####################
##################################################################################

case "$strEncodingVanilla" in
	us-ascii|utf-16le|iso-8859-1)
		(iconv -f UTF-8 -t "$strEncodingVanilla" "$strFlWork") |sponge "$strFlWork"
		;;
esac
if FUNChasBOM "$strVanillaScriptFileOriginal";then
	FUNCfixBOM "$strFlWork"
fi
if [[ "$(FUNCgetEncoding "$strVanillaScriptFileOriginal")" != "$(FUNCgetEncoding "$strFlWork")" ]];then
	FUNCechoInfo "[ERROR] restoring enconding failed"
	echo "file -bi '$strVanillaScriptFileOriginal';"
	echo "file -bi '$strFlWork';"
	exit 1
fi

if $bApplyEachPatch;then
	# prepare a status file confirming all went ok
	astrListSUCCESS=("${astrListCurrent[@]}")
	declare -p astrListSUCCESS >"$strFlSuccessCfg"
	chmod -v ugo-w "$strFlSuccessCfg"
	ls -l "$strFlSuccessCfg"
	
	#astrWorkDB+=("$strScriptFileRelat")
	#mapfile -t astrWorkDB < <(for strFl in "${astrWorkDB[@]}";do echo "$strFl";done |sort -u)
	#declare -p astrWorkDB >"$strFlWorkDatabase"
	
	if $bDummyVanilla;then
		FUNCtrash "$strVanillaScriptFile"
	fi
	
	### JSON ###
	strFlJson="$strFlFinalMergerModJson"
	
	# create json lock to prevent multithread concurrency
	strFlJsonLock="${strFlJson}.lock"
	strFlJsonLockSelfID="${strFlJson}.lock.$$"
	while ! ln -s "$strFlJson" "${strFlJsonLock}";do
		echo -ne "[INFO] $(date) Trying to acquire: ${strFlJsonLock}\r"
		sleep 1
	done
	ln -sf "${strFlJsonLock}" "$strFlJsonLockSelfID" #this is to help kill the right PID (this $$)
	
	#FUNCjsonSetArray() {
		#local lstrID="$1";shift
		#local lastrCfgsList=("$@")
		
		#local lstrArrayCfg=""
		#for((i=0;i<${#lastrCfgsList[@]};i++));do
			#if((i>0));then lstrArrayCfg+=", ";fi
			#lstrArrayCfg+="\"${lastrCfgsList[i]}\"";
		#done
		##FUNCjson '.autoexec_configs = ['"${lstrArrayCfg}"']' "$strFlJson" |sponge "$strFlJson"
		#FUNCjson ".${lstrID} = [ ${lstrArrayCfg} ]" "$strFlJson" |sponge "$strFlJson"
	#}
	#if [[ ! -f "$strFlJson" ]];then echo "{}" >"$strFlJson";fi
	if [[ -z "$(FUNCjson "$strFlJson" ".name")" ]];then
		FUNCtrash "$strFlJson"
		echo "{}" >"$strFlJson";
	fi
	FUNCjsonSetArrayByExt() {
		local lstrID="$1"
		local lstrExt="$2"
		
		local lastrCfgsList
		#mapfile -t lastrCfgsList < <(FUNCjson ".${lstrID}[]" "$strFlJson" |sed -r -e 's@^"@@' -e 's@"$@@' |sort -u)
		mapfile -t lastrCfgsList < <(FUNCjsonGetArray "$strFlJson" "${lstrID}")
		if [[ -n "$lstrExt" ]] && [[ "${strScriptFileRelat}" =~ .*[.]${lstrExt}$ ]];then
			lastrCfgsList+=("$(basename "${strScriptFileRelat}")")
		fi
		mapfile -t lastrCfgsList < <(for strFl in "${lastrCfgsList[@]}";do echo "$strFl";done |sort -u)
		FUNCjsonSetArray "$strFlJson" "${lstrID}" "${lastrCfgsList[@]}"
		#local lstrArrayCfg=""
		#for((i=0;i<${#lastrCfgsList[@]};i++));do
			#if((i>0));then lstrArrayCfg+=", ";fi
			#lstrArrayCfg+="\"${lastrCfgsList[i]}\"";
		#done
		##FUNCjson '.autoexec_configs = ['"${lstrArrayCfg}"']' "$strFlJson" |sponge "$strFlJson"
		#FUNCjson ".${lstrID} = [ ${lstrArrayCfg} ]" "$strFlJson" |sponge "$strFlJson"
	}	
	FUNCjsonSet "$strFlJson" name        "GSK - Final Merged Mods"
	FUNCjsonSet "$strFlJson" version     "1.0"
	FUNCjsonSet "$strFlJson" description "MUST BE AFTER ALL MODS MERGED ON IT (possibly last to be loaded)! The result of applying all modded script and text files thru $(basename "$0"). DO NOT EDIT! Auto-generated by $(basename "$0")"
	FUNCjsonSet "$strFlJson" author      "GussakThor"
	FUNCjsonSet "$strFlJson" author_url  ""
	FUNCjsonSet "$strFlJson" website     ""
	FUNCjsonSetArrayByExt launch_parameters ""
	FUNCjsonSetArrayByExt gameinfo_parameters ""
	FUNCjsonSetArrayByExt modules ""
	FUNCjsonSetArrayByExt game_configs cfg
	FUNCjsonSetArrayByExt autoexec_configs ""
	ls -l "$strFlJson"
	cat "$strFlJson"
	rm "${strFlJsonLock}" "$strFlJsonLockSelfID" # clean json lock
	
	echo;FUNCechoInfo "[Final merge SUCCESS!!!]"
fi

FUNCtrash "$strFinalDummyHelperFolder"
FUNCechoInfo "nRet=$?"

#: ${nWaitBeforeExiting:=0} #help
#read -n 1 -p "Press a key to exit..." -t $nWaitBeforeExiting&&:

FUNCexit 0
