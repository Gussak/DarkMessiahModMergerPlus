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

astrInitialParams=("$@")

while [[ ! -f "./allMergerScriptsGenericConfig.sh" ]];do cd ..;done; source "./allMergerScriptsGenericConfig.sh"; FUNCminiModInit "$@"

FUNCechoInfo "This looks for PATCH files that have no full work file available by it's side."
FUNCechoInfo "These PATCH files MUST have been created based on VANILLA files (just a \`diff -u\` from them!)."
FUNCechoInfo "Then, using the already extracted vanilla (thru ex.: extractVanillaScriptsTextsFromVPKs.sh) Scripts and other 'mimetype text' files, reconstructs the Work file that will be used on the merging process, to make it easy to visualize with Meld, WinMerge (thru CygWin) etc."

: ${strFilter:=""} #help to work with fewer files

#bRevalidate=false
#if [[ "${1-}" == --revalidate ]];then #help reconstruct the work file AGAIN, and compare it with existing one
	#shift
	#bRevalidate=true
#fi
#bTrashReconstructed=false
#if [[ "${1-}" == --trash-reconstructed ]];then #help implies --revalidate. useful to apply to your mod before releasing just the patch files. Be sure to use the strFilter matching your mod base folder and check the files that will be trashed.
	#shift
	#bRevalidate=true
	#bTrashReconstructed=true
#fi

bRevalidate=false
bTrashReconstructed=false
while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do # checks if param is set
	if [[ "$1" == "--help" ]];then #help show this help
		SECFUNCshowHelpV2 "./allMergerScriptsGenericConfig.sh"
		SECFUNCshowHelpV2 "$0"
		#egrep "[#]help" "./allMergerScriptsGenericConfig.sh" "$0" |sed -r -e 's@^[ \t]*@@'
		exit 0
	elif [[ "$1" == "-r" || "$1" == "--revalidate" ]];then #help reconstruct the work file AGAIN, and compare it with existing one
		bRevalidate=true
	elif [[ "$1" == "-t" || "$1" == "--trash-reconstructed" ]];then #help implies --revalidate. useful to apply to your mod before releasing just the patch files. Be sure to use the strFilter matching your mod base folder and check the files that will be trashed.
		bRevalidate=true
		bTrashReconstructed=true
	else
		echo "[invalid option] '$1'"
		$0 --help #$0 considers ./, works best anyway..
		FUNCexit 1
	fi
	shift&&:
done

cd "${strPathParent}"

IFS=$'\n' read -d '' -r -a astrPatchList < <(
	find -L "${strGameInstallMainFolder}"* -iregex ".*\(${strJustExtRegexEsc}\)\(.patch\|.kvpatch.json\)" \
		|sort \
		|egrep "[.]layer" \
		|egrep ".*${strFilter}.*" \
		|egrep -v "${strRegexFoldersToIgnore}|${strMergedModsFolder}|${strVanillaScriptsPath}|${strVanillaLayer}" \
			2>/dev/null
)&&:
if [[ -n "$strFilter" ]];then
	echo;declare -p astrPatchList |sed -r -e "$strSedArrayLn";echo
fi

nNewReconstruct=0
nAlreadyReconstruct=0
astrExistingWorkFilesList=()
#bAllowTrash=true
astrFlCanTrash=()
astrRevalidationFail=()
astrFlMissingVanillaList=()
for strFlPatch in "${astrPatchList[@]}";do
	if [[ "$strFlPatch" =~ .*[.]kvpatch[.]json$ ]] && [[ "$(cat "$strFlPatch" |tr -d '\r')" == "{}" ]];then #TODO this file should not have even been generated...
		trash "$strFlPatch"
		continue
	fi
	
	strFlWork="$strFlPatch"
	strFlWork="${strFlWork%.patch}"
	strFlWork="${strFlWork%.kvpatch.json}"
	
	bWorkFileExists=false
	if [[ -f "$strFlWork" ]];then
		astrExistingWorkFilesList+=("$strFlWork")
		bWorkFileExists=true
		((nAlreadyReconstruct++))&&:;
		if ! $bRevalidate;then
			continue;
		fi
	fi
	if ! $bWorkFileExists && $bRevalidate;then
		FUNCechoInfo "[WARNING:] to be revalidated it needs to be reconstructed first, missing file: $strFlWork"
		continue;
	fi
	
	echo
	echo ">>>>>>>>>>>>>>>>>>> $strFlPatch"
	ls -l "$strFlPatch"
	#set -x
	#for strRelFold in "${astrKnownGameModRelativeFolders[@]}";do
		#strModBaseFolder="${strGameInstallMainFolder}*/"
		#if [[ "${strFlWork:0:${#strRelFold}}" == "strRelFold" ]];then
			#:
		#fi
	#done
	#strFlRelat="$(echo "$strFlWork" |egrep -oi "(${strRegexKGMRF}).*" |cut -d"/" -f2-)"
	strFlRelat="$(FUNCfileRelat "$strFlWork")"
	declare -p strFlRelat
	strFlVanilla="$strVanillaScriptsPath/mm/${strFlRelat}"
	#strVanillaScriptFile="$(find -L "$strVanillaScriptsPath" -iregex "${strFindScriptFileRegex}")"
	if ! ls -l "$strFlVanilla";then
		strFlSelVanillaAlt=""
		if [[ -f "${strFlPatch}.Vanilla.config" ]];then
			strFlSelVanillaAlt="${strPathParent}/$(cat "${strFlPatch}.Vanilla.config")"
		fi
		
		if [[ -f "$strFlSelVanillaAlt" ]];then
			strFlVanilla="$strFlSelVanillaAlt"
		else
			strFlVaniFilter="$(basename "${strFlRelat}")"
			strProblMsg="Vanilla file not found.\n If it is not based on vanilla game files but in some mod, select it now to be used as base in the patching process.\n strFlSelVanillaAlt='$strFlSelVanillaAlt'\n strFlVaniFilter='$strFlVaniFilter'"
			FUNCechoInfo "[PROBLEM:] $strProblMsg"
			bVanillaAltOk=false
			while strFlSelVanillaAlt="$(yad --title "$0" --text "$strProblMsg" --file-filter="$strFlVaniFilter" --file)";do
				if [[ "$strFlSelVanillaAlt" =~ ^${strPathParent}.* ]];then
					strFlVanilla="$strFlSelVanillaAlt"
					strFlSelVanillaRelat="${strFlSelVanillaAlt#${strPathParent}/}" # relative
					echo "$strFlSelVanillaRelat" >"${strFlPatch}.Vanilla.config"
					ls -l "${strFlPatch}.Vanilla.config"
					cat "${strFlPatch}.Vanilla.config"
					bVanillaAltOk=true
					break
				else
					read -n 1 -p "[It must be relative to '${strPathParent}']"
				fi
			done
			
			if ! $bVanillaAltOk;then
				astrFlMissingVanillaList+=("$strFlVanilla")
				continue
			fi
		fi
	fi
	
	function FUNCrevalidDiff() {
		set -x;colordiff "${strFlWork}.NEWLY_PATCHED" "$strFlWork"&&:;nRetDiff=$?;set +x
		if((nRetDiff==0));then
			astrFlCanTrash+=("${strFlWork}")
			FUNCtrash "${strFlWork}.NEWLY_PATCHED"
		else
			FUNCechoInfo "[WARNING:] reconstructed patched file differs from existing one!"
			#: ${bIgnoreDifferentReconstructed:=false} #help just for dev tests
			#if ! $bIgnoreDifferentReconstructed;then
				#read -n 1 -p "hit a key to continue"
			#fi
			#return 1
			#bAllowTrash=false
			astrRevalidationFail+=("${strFlWork}.NEWLY_PATCHED")
		fi
		#return 0
	}
	
	#declare -p strFileToMerge
	bKeyValueDiffMode=false
	if strFlPatchCheck="$(FUNCpatchMode "${strFlWork}")";then
		bKeyValueDiffMode=true
	fi
	if [[ "$strFlPatchCheck" != "$strFlPatch" ]];then
		FUNCechoInfo "[ERROR:] strFlPatchCheck='$strFlPatchCheck' != strFlPatch='$strFlPatch'"
		FUNCexit 1
	fi
	
	if $bKeyValueDiffMode;then
		#"${strPathSelf}/keyValuePatcher.py" apply \
			#-o "${strFlPatch}" \
			#<(iconv -f $(file -b --mime-encoding "$strFlVanilla") -t UTF-8 "$strVanillaScriptFile") \
			#<(iconv -f $(file -b --mime-encoding "$strFileToMerge"      ) -t UTF-8 "$strFileToMerge"      ) \
			#&&:;
		set -x;
		"${strPathSelf}/keyValuePatcher.py" apply -a \
			-o "${strFlWork}.NEWLY_PATCHED" \
			<(iconv -f $(file -b --mime-encoding "$strFlVanilla") -t UTF-8 "$strFlVanilla") \
			"${strFlPatch}" \
			&&: #keyValuePatcher.py apply [-h] [-o OUTPUT] [-a] target patch
		nRetPatch=$?
		set +x;
	else
		set -x;
		patch \
			-i "${strFlPatch}" \
			-o "${strFlWork}.NEWLY_PATCHED" \
			<(iconv -f $(file -b --mime-encoding "$strFlVanilla") -t UTF-8 "$strFlVanilla") \
			&&:;
		nRetPatch=$?;
		set +x
	fi
	
	ls -l "${strFlPatch}" "${strFlWork}.NEWLY_PATCHED" "$strFlVanilla"&&:
	if((nRetPatch==0));then
		if $bRevalidate;then # just revalidate
			FUNCrevalidDiff
		else # reconstruct
			mv -vf "${strFlWork}.NEWLY_PATCHED" "$strFlWork"
			ls -l "$strFlWork"
		fi
	else
		FUNCechoInfo "[PROBLEM:] it seems that the above patch file was not created based on the vanilla file. Try to manually recreate it:"
		read -n 1 -p "Hit a key to run ${strExecMerger}"
		if $bRevalidate;then
			cp -v "$strFlVanilla" "${strFlWork}.NEWLY_PATCHED"
			chmod u+w "${strFlWork}.NEWLY_PATCHED"
			while ! "${strExecMerger}" "${strFlPatch}" "${strFlWork}.NEWLY_PATCHED";do #TODO this is not good because the .patch file is hard to use in case of many lines beggining with '+' ?
				FUNCechoInfo "[PROBLEM:] some error happened in the merger, please retry"
				read -n 1 -p "Hit a key to run ${strExecMerger}"
			done
			FUNCechoInfo "[Manual Work Done] now that you manually patched it, that new file will become the final one."
			mv -v "${strFlWork}" "${strFlWork}.$$.bkp"
			cp -v "${strFlWork}.NEWLY_PATCHED" "${strFlWork}"
			FUNCtrash "${strFlWork}.patch"
			FUNCrevalidDiff
			FUNCechoInfo "[Prepare patch for it now] ./prepareAllModsPatchesForScriptFile.sh '${strFlRelat}'"
			FUNCechoInfo "[Run this again after the .patch file is ready] $0 ${astrInitialParams[@]}"
			FUNCexit 1
		else
			cp -v "$strFlVanilla" "$strFlWork"
			chmod u+w "$strFlWork"
			while ! "${strExecMerger}" "${strFlPatch}" "$strFlWork";do
				FUNCechoInfo "[PROBLEM:] some error happened in the merger, please retry"
				read -n 1 -p "Hit a key to run ${strExecMerger}"
			done
		fi
	fi
	
	FUNCechoInfo "[!!!SUCCESS!!!] $strFlWork"
	((nNewReconstruct++))&&:
done

echo
echo "<> <> <> <> <> <> <> <> <> <> <> <> <> <> <> <> <> <> <> <> <> <> <> <> <> <> <> <> <> <> "
FUNCechoInfo "[PROBLEMS:] listed below (if any)"
if [[ -n "${astrFlMissingVanillaList[@]}" ]];then
	declare -p astrFlMissingVanillaList |sed -r -e "$strSedArrayLn"
fi
if [[ -n "${astrRevalidationFail[@]}" ]];then
	declare -p astrRevalidationFail |sed -r -e "$strSedArrayLn"
fi
FUNCechoInfo "[TOTAL Patch Files:] ${#astrPatchList[@]}"
FUNCechoInfo "[Already Reconstructed Files:] $nAlreadyReconstruct"
FUNCechoInfo "[NEWLY Reconstructed Files:] $nNewReconstruct"

#if $bTrashReconstructed && $bAllowTrash;then
if $bTrashReconstructed;then
	echo
	#declare -p astrFlCanTrash |sed -r -e "$strSedArrayLn"
	for strFlCT in "${astrFlCanTrash[@]}";do
		echo "${strFlCT}" |egrep "[.]layer.*" -o
	done
	if((${#astrFlCanTrash[@]}>0));then
		echo
		FUNCechoInfo "[Trash the above files?] (y/...)"
		read -n 1 strResp
		if [[ $strResp == y ]];then
			for strFlToTrash in "${astrFlCanTrash[@]}";do
				FUNCtrash "$strFlToTrash"
			done
		fi
		echo
	else
		FUNCechoInfo "[No files to trash]"
	fi
fi

FUNCechoInfo "[DONE]"







