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

#help USAGE: <strScriptFileRelat>

: ${bVerbose:=false} #help
bRedoAllFiles=false;
: ${bForceRePatch:=false} #help
while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do # checks if param is set
	if [[ "$1" == "--help" ]];then #help show this help
		#egrep "[#]help" "./allMergerScriptsGenericConfig.sh" "$0" |sed -r -e 's@^[ \t]*@@'
		SECFUNCshowHelpV2 "./allMergerScriptsGenericConfig.sh"
		SECFUNCshowHelpV2 "$0"
		exit 0
	elif [[ "$1" == "-f" || "$1" == "--forceRePatch" ]];then #help
		bForceRePatch=true
	elif [[ "$1" == "-v" || "$1" == "--verbose" ]];then #help shows more useful messages
		bVerbose=true
	elif [[ "$1" == --redoall ]];then #help REDO the work on all files at the Final merged folder
		bRedoAllFiles=true
	else
		echo "[invalid option] '$1'"
		$0 --help #$0 considers ./, works best anyway..
		exit 1
	fi
	shift&&:
done

strScriptFileRelat="${1}" #help provide a relative path (as mods may implement variants in other sub paths, like arena mod, that shall not affect the main game) ex.: "scripts/spells.txt" will be prepended with "*/" becoming "*/scripts/spells.txt" and matching like _mods folder like ".../content/scripts/spells.txt", main game like ".../mm/scripts/spells.txt"
exec > >(tee "$strFinalMergedFolder/${strScriptFileRelat}.log") 2>&1

FUNCchkDeps() {
	while ! ${1+false};do
		if ! which "$1";then
			FUNCechoInfo "ERROR: missing dependency '$1'"
			exit 1;
		fi
		shift
	done
}
FUNCchkDeps jq colordiff patch

astrWorkDB=()
strFlWorkDatabase="$(basename "$0").cfg"
if [[ -f "$strFlWorkDatabase" ]];then
	source "$strFlWorkDatabase"
	if $bVerbose;then declare -p astrWorkDB |sed -r -e "$strSedArrayNumToLn";fi
	if $bRedoAllFiles;then
		for strFlWDB in "${astrWorkDB[@]}";do
			FUNCechoInfo "[WorkDB] '$strFlWDB'"
			read -n 1&&:
			bForceRePatch=true "$0" "$strFlWDB"
		done
		exit
	fi
fi

: ${bShowDiffPerFile:=false} #help
: ${strShowDiffCmd:="${strExecMerger}"} #help try also colordiff

if $bForceRePatch;then
	FUNCtrash "$strFinalMergedFolder/$strScriptFileRelat" "$strFinalMergedFolder/${strScriptFileRelat}.SUCCESS.cfg"&&:
fi

if [[ "$strScriptFileRelat" != "gameinfo.txt" ]];then #help is this the only file that ever happens on root mod dir? TODO
	if [[ ! "$strScriptFileRelat" =~ .*/.* ]] || [[ "$strScriptFileRelat" =~ ^[/].* ]];then
		declare -p strScriptFileRelat
		FUNCechoInfo "[Invalid relative file] all text script etc files are relative to some sub directory in vanilla tree. Also do not use absolute file paths."
		exit 1
	fi
fi
strFindScriptFileRegex=".*/\(${strRegexEscKGMRF}\)/${strScriptFileRelat}\$"
if $bVerbose;then declare -p strFindScriptFileRegex;fi

strThisFolder="$(pwd)"
#strThisFolderBN="$(basename "${strThisFolder}")"

#help This bash script will look on the parent folder for all mergeable script or text files you passed as main parameter. Each will be considered as layers to be merged in a single final folder. The load order priority is from the ModLauncher main mod, then the order you prepared by naming the folders properly with numbered layers. Each folder must have the contents of one extracted game mod file.
#set -x
IFS=$'\n' read -d '' -r -a astrListFoldersLayersOrderOriginal < <(
	find -L "${strGameInstallMainFolder}"* -iregex "${strFindScriptFileRegex}" \
		|sort \
		|egrep "[.]layer" \
		|egrep -v "${strRegexFoldersToIgnore}|${strMergedModsFolderBN}|${strVanillaScriptsPath}|${strVanillaLayer}" \
			2>/dev/null
)&&:
#set +x
echo;declare -p astrListFoldersLayersOrderOriginal |sed -r -e "$strSedArrayNumToLn";echo
astrListFoldersLayersOrder=("${astrListFoldersLayersOrderOriginal[@]}")

: ${strFlModLoadSett:="${strPathParent}/Dark Messiah Might and Magic Single Player/_mods/core/user_settings.json"} #help
if [[ ! -f "$strFlModLoadSett" ]];then
	strFlModLoadSett="${strPathParent}/Dark Messiah Might and Magic Single Player.0.WriteLayer/_mods/core/user_settings.json";
fi
if [[ ! -f "$strFlModLoadSett" ]];then
	FUNCechoInfo "ModLauncher settings file not found where expected '${strPathParent}/*/_mods/core/user_settings.json'"
	exit 1
fi

IFS=$'\n' read -d '' -r -a astrModLauncherOrderList < <(
	jq ".load_order[]" "$strFlModLoadSett" |sed -r -e 's@^"@@' -e 's@"$@@'
)&&:
IFS=$'\n' read -d '' -r -a astrModLauncherIgnoreList < <(
	jq ".ignore[]" "$strFlModLoadSett" |sed -r -e 's@^"@@' -e 's@"$@@'
)&&:
echo;declare -p astrModLauncherOrderList |sed -r -e "$strSedArrayNumToLn";echo
astrListCurrent=()
for strModLauncherModFolder in "${astrModLauncherOrderList[@]}";do
#	for strLayer in "${astrListFoldersLayersOrder[@]}";do
	for((i=0;i<${#astrListFoldersLayersOrder[@]};i++));do
		strLayer="${astrListFoldersLayersOrder[i]}"
		if [[ "${strLayer}" =~ .*/${strModLauncherModFolder}/.* ]];then
			bIgnoreModFolder=false
			for strModLauncherIgnoreFolder in "${astrModLauncherIgnoreList[@]}";do
				if [[ "${strModLauncherModFolder}" == "${strModLauncherIgnoreFolder}" ]];then
					bIgnoreModFolder=true
					break;
				fi
			done
			if ! $bIgnoreModFolder;then
				astrListCurrent+=("${strLayer}")
			fi
			unset astrListFoldersLayersOrder[$i]
			break;
		fi
	done
	astrListFoldersLayersOrder=("${astrListFoldersLayersOrder[@]}") # clear unset indexes
done
astrListCurrent=("${astrListFoldersLayersOrder[@]}" "${astrListCurrent[@]}") # remaining folders at astrListFoldersLayersOrder will be overriden by the ones from ModLauncher list order
echo
FUNCechoInfo "[list with overriden by the ones from ModLauncher list order]"
declare -p astrListCurrent |sed -r -e "$strSedArrayNumToLn";echo
if((${#astrListCurrent[@]} < 2));then
	FUNCechoInfo "[Nothing to merge] is needed 2 or more to merge"
	exit
fi

: ${bFollowFolderLayersOrder:=""} #help bFollowFolderLayersOrder=false to use ModLaucher order before other mods not using it. bFollowFolderLayersOrder=true will just follow folders alphanumeric order so you need to grant the priority properly naming them. bFollowFolderLayersOrder="" will show a message and wait. Tho, anyway, ModMerger will prioritize it's order also over mods non compatible with it, so FinalMergedScriptsMaxPriority mod must be last one there to this all work, as FinalMergedScriptsMaxPriority actually works are a max priority overrider.
if [[ -z "$bFollowFolderLayersOrder" ]];then
	if [[ "${astrListCurrent[@]}" != "${astrListFoldersLayersOrder[@]}" ]];then
		FUNCechoInfo "[The folders layers order differ from following ModLauncher setting list order]"
		FUNCechoInfo "[ModLauncher setting list order will be prefered] Unless you set bFollowFolderLayersOrder=true"
		FUNCechoInfo "[Press a key to continue.]"
		read -n 1
	fi
else
	if $bFollowFolderLayersOrder;then
		astrListCurrent=("${astrListFoldersLayersOrderOriginal[@]}")
		echo
		FUNCechoInfo "[list following Folders Layers Order]"
		declare -p astrListCurrent |sed -r -e "$strSedArrayNumToLn";echo
	fi
fi

strVanillaScriptFile="$(find -L "$strVanillaScriptsPath" -iregex "${strFindScriptFileRegex}")"
bDummyVanilla=false
#bFlVanilla=false;if [[ -f "$strVanillaScriptFile" ]];then bFlVanilla=true;fi
if [[ ! -f "$strVanillaScriptFile" ]];then
	#FUNCechoInfo "[WARNING: There is no such Vanilla] create it there empty: '${strVanillaScriptsPath}/mm/$strScriptFileRelat'"
	#FUNCechoInfo "[Merge existing one from mods anyway?] Ctrl+C to abort"
	##read -n 1&&:
	##exit 1
	#bFlVanilla=false
	bDummyVanilla=true
	strVanillaScriptFile="${strFinalDummyHelperFolder}/${strScriptFileRelat}"
	mkdir -vp "$(dirname "$strVanillaScriptFile")"
	if [[ ! -f "$strVanillaScriptFile" ]];then
		cp "${astrListCurrent[0]}" "$strVanillaScriptFile" # see info below for being the first file on the list
	fi
	FUNCechoInfo "[WARNING: There is no such Vanilla File] created a dummy one with the contents of the first one found '${strVanillaScriptFile}' in the list of MODs, it will be deleted later."
fi
chmod ugo-w "$strVanillaScriptFile"
ls -l "$strVanillaScriptFile"

nBkpIndex=0

######## MAIN ########

: ${bApplyEachPatch:=true} #help to finalize the merge work properly
if $bApplyEachPatch;then
	strFlWork="${strFinalMergedFolder}/${strScriptFileRelat}"
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
			exit
		else
			colordiff <(declare -p astrListSUCCESS |sed -r -e "$strSedArrayNumToLn") <(declare -p astrListCurrent |sed -r -e "$strSedArrayNumToLn")&&:
			FUNCechoInfo "[File alredy fully patched but mods list changed, repatch ? ] Ctrl+C to abort"
			read -n 1&&:
			FUNCtrash "$strFlSuccessCfg"
		fi
	fi
	
	FUNCtrash "$strFlWork" "$strFlSuccessCfg"&&:
	for((i=0;i<${#astrWorkDB[@]};i++));do
		if [[ "${astrWorkDB[i]}" == "$strScriptFileRelat" ]];then
			unset astrWorkDB[$i]
			break;
		fi
	done
	
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
	
#function FUNCpatchMode() {
	#local lstrFileToMerge="$1"
	
	#local lbKeyValueDiffMode=false
	#local lstrExt="$(echo "${lstrFileToMerge}" |sed -r -e 's@.*[.]([a-zA-Z0-9_]*)$@\1@')"
	#declare -p lstrExt >&2
	#if [[ -z "$lstrExt" ]];then
		#FUNCechoInfo "[ERROR] invalid filename without extension '$lstrFileToMerge'" >&2
		#exit 1
	#fi
	#case $lstrExt in
		#lst|qct|txt|vmt)
			#lbKeyValueDiffMode=true
			#strFlPatch="${lstrFileToMerge}.kvpatch.json"
			#;;
		##KEEPinfo: cfg) # see *) uses generic code patcher way
			##;;
		#*)
			#lbKeyValueDiffMode=false
			#strFlPatch="${lstrFileToMerge}.patch"
			#;;
	#esac
	## special files that keys are meant to happen more than once in the same hierarchy nesting depth
	#if echo "${lstrFileToMerge}" |egrep -q "resource/closecaption_manifest.txt$";then
			#lbKeyValueDiffMode=false
			#strFlPatch="${lstrFileToMerge}.patch"
	#fi
	
	#if $lbKeyValueDiffMode;then
		#return 0
	#else
		#return 1
	#fi
#}
	bKeyValueDiffMode=false
	if strFlPatch="$(FUNCpatchMode "${strFileToMerge}")";then
		bKeyValueDiffMode=true
	fi
	
	: ${bForceRecreatePatches:=true} #help
	if ! $bForceRecreatePatches && [[ -f "$strFlPatch" ]];then
		FUNCechoInfo "[Skip patch creation, ready already]"
		ls -l "${strFlPatch}"
	else
		if $bKeyValueDiffMode;then
			#KEEPinfo: this implicitly creates the same "${strFileToMerge}.kvpatch.json": "${strPathSelf}/keyValuePatcher.py" create <(iconv -f $(file -b --mime-encoding "$strVanillaScriptFile") -t UTF-8 "$strVanillaScriptFile") "$strFileToMerge"&&:;nDiffRet=$? #but the below is more clear and can handle mismatching encodings
			"${strPathSelf}/keyValuePatcher.py" create \
				-o "${strFlPatch}" \
				<(iconv -f $(file -b --mime-encoding "$strVanillaScriptFile") -t UTF-8 "$strVanillaScriptFile") \
				<(iconv -f $(file -b --mime-encoding "$strFileToMerge"      ) -t UTF-8 "$strFileToMerge"      ) \
				&&:;
			nDiffRet=$?
		else
			( # prepare the patch using relative path to remove user name
				cd "${strPathParent}"
				set -x
				set -o pipefail # so the diff exit value will be captured with $? if using |tee
				diff -u \
					<(iconv -f $(file -b --mime-encoding "$strVanillaScriptFile") -t UTF-8 "$strVanillaScriptFile") \
					<(iconv -f $(file -b --mime-encoding "$strFileToMerge"      ) -t UTF-8 "$strFileToMerge"      ) \
						>"${strFlPatch}";nRet=$?
						#KEEPinfo: too much unnecessary log: #					|tee "${strFlPatch}";nRet=$?
				declare -p nRet
				set +x
				exit $nRet
			)&&:;nDiffRet=$?
		fi
		if $bVerbose;then declare -p nDiffRet;fi
		case $nDiffRet in
			0) FUNCechoInfo "[Identical] Skip"; continue;;
			1) 
				FUNCechoInfo "[Diff PATCH from MOD vs Vanilla creation OK]"
				if $bShowDiffPerFile;then
					"$strShowDiffCmd" "$strVanillaScriptFile" "$strFileToMerge"
				fi
				;;
			2) 
				FUNCechoInfo "[WARNING: diff trouble] try manually"; #this ever happens?
				"${strExecMerger}" "$strVanillaScriptFile" "$strFileToMerge";
				;;
			*) FUNCechoInfo "[ERROR: unrecognized diff return value]";exit 1;;
		esac
		
		ls -l "${strFlPatch}"
		realpath "${strFlPatch}"
	fi
	
	if $bApplyEachPatch;then
		cp -v "${strFlWork}" "$strFlPreviouslyPatched"
		chmod ugo-w "$strFlPreviouslyPatched" #help if you want to modify a patch, do it in a new mod folder layer instead of using "$strExecMerger" 3way
		
		bMergedManually=false
		: ${nFuzzyPatch:=0} #help try nFuzzyPatch=1 This is very helpful to make it easier to provide an initial auto merge, just review the results
#		acmdPatch=(patch -F $nFuzzyPatch "$strFlWork" "${strFlPatch}")
		if $bKeyValueDiffMode;then
			acmdPatch=("${strPathSelf}/keyValuePatcher.py" apply -a -o "${strFlWork}.NEWLY_PATCHED" "$strFlWork" "${strFlPatch}") #keyValuePatcher.py apply [-h] [-o OUTPUT] [-a] target patch
		else
			acmdPatch=(patch -F $nFuzzyPatch -i "${strFlPatch}" -o "${strFlWork}.NEWLY_PATCHED" "$strFlWork") #patch [ORIGINAL_FILE] -i [PATCH_FILE] -o [OUTPUT_FILE]
		fi
		declare -p acmdPatch
		ls -l "$strFlWork"
		set -x;"${acmdPatch[@]}"&&:;nRetPatch=$?;set +x
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
			declare -p astrEasyLogReview |sed -r -e "${strSedArrayNumToLn}"
			"$strExecMerger" "$strVanillaScriptFile" "$strFileToMerge" "$strFlWork" #help manual merge required. show vanilla on the left just to try to guess what to do.
			FUNCechoInfo "nRet=$?"
			bMergedManually=true
		fi
		((nBkpIndex++))&&:
		FUNCtrash "${strFlWork}.orig" "${strFlWork}.rej" &&:
		
		: ${bShow3wayDiffAfterEachPatch:=false} #help only with "$strExecMerger". This will show on the right the final file being modified per step!
		if ! $bMergedManually && $bShow3wayDiffAfterEachPatch;then
			: ${bCompareVanillaInTheMiddle:=false} #help otherwise will put in the middle the previously patched file so you can see each difference per patching step that is better to understand what is happening.
			if $bCompareVanillaInTheMiddle;then
				"$strExecMerger" "$strFileToMerge" "$strVanillaScriptFile" "$strFlWork"
			else
				"$strExecMerger" "$strFileToMerge" "$strFlPreviouslyPatched" "$strFlWork"
			fi
		fi
		
		FUNCtrash "$strFlPreviouslyPatched"
	fi
	
	bFirstFileWork=false
	echo
done

echo "$strFullLineVisualDelimiter"

: ${bShowFinalComparison:=true} #help compare vanilla with fully mods merged file after all mods merging end for it
if $bShowFinalComparison;then
	FUNCechoInfo "[Showing final merge comparison with vanilla]"
	"$strExecMerger" "$strVanillaScriptFile" "$strFlWork"
fi

if $bApplyEachPatch;then
	astrListSUCCESS=("${astrListCurrent[@]}")
	declare -p astrListSUCCESS >"$strFlSuccessCfg"
	chmod -v ugo-w "$strFlSuccessCfg"
	ls -l "$strFlSuccessCfg"
	
	astrWorkDB+=("$strScriptFileRelat")
	IFS=$'\n' read -d '' -r -a astrWorkDB < <(for strFl in "${astrWorkDB[@]}";do echo "$strFl";done |sort -u)&&:
	declare -p astrWorkDB >"$strFlWorkDatabase"
	
	if $bDummyVanilla;then
		FUNCtrash "$strVanillaScriptFile"
	fi
	
	### JSON ###
	FUNCjsonSet() {
		jq ".${1} = \"${2}\"" "$strFlJson" |sponge "$strFlJson"
	}
	FUNCjsonSetArray() {
		local lstrID="$1"
		local lstrExt="$2"
		
		local lastrCfgsList
		IFS=$'\n' read -d '' -r -a lastrCfgsList < <(jq ".${lstrID}[]" "$strFlJson" |sed -r -e 's@^"@@' -e 's@"$@@' |sort -u)&&:
		if [[ -n "$lstrExt" ]] && [[ "${strScriptFileRelat}" =~ .*[.]${lstrExt}$ ]];then
			lastrCfgsList+=("$(basename "${strScriptFileRelat}")")
		fi
		IFS=$'\n' read -d '' -r -a lastrCfgsList < <(for strFl in "${lastrCfgsList[@]}";do echo "$strFl";done |sort -u)&&:
		local lstrArrayCfg=""
		for((i=0;i<${#lastrCfgsList[@]};i++));do
			if((i>0));then lstrArrayCfg+=", ";fi
			lstrArrayCfg+="\"${lastrCfgsList[i]}\"";
		done
		#jq '.autoexec_configs = ['"${lstrArrayCfg}"']' "$strFlJson" |sponge "$strFlJson"
		jq ".${lstrID} = [ ${lstrArrayCfg} ]" "$strFlJson" |sponge "$strFlJson"
	}
	#if [[ ! -f "$strFlJson" ]];then echo "{}" >"$strFlJson";fi
	if [[ -z "$(jq ".name" "$strFlJson")" ]];then
		FUNCtrash "$strFlJson"
		echo "{}" >"$strFlJson";
	fi
	FUNCjsonSet name        "GSK - Final Merged Mods"
	FUNCjsonSet version     "1.0"
	FUNCjsonSet description "MUST BE AFTER ALL MODS MERGED ON IT (possibly last to be loaded)! The result of applying all modded script and text files thru $(basename "$0"). DO NOT EDIT! Auto-generated by $(basename "$0")"
	FUNCjsonSet author      "GussakThor"
	FUNCjsonSet author_url  ""
	FUNCjsonSet website     ""
	FUNCjsonSetArray launch_parameters ""
	FUNCjsonSetArray gameinfo_parameters ""
	FUNCjsonSetArray modules ""
	FUNCjsonSetArray game_configs cfg
	FUNCjsonSetArray autoexec_configs ""
	ls -l "$strFlJson"
	cat "$strFlJson"
	
	echo;FUNCechoInfo "[Final merge SUCCESS!!!]"
fi

FUNCtrash "$strFinalDummyHelperFolder"
FUNCechoInfo "nRet=$?"
exit 0
