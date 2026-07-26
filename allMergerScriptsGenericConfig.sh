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

set -Eeu #use this specifically, not to everything or |grep results will fail...: set -o pipefail

shopt -s expand_aliases
#function FUNCechoInfo() {
	#echo "[$(basename "$0")] $@" >&2
#}
alias FUNCechoInfo='echo "[$(basename "$0"):${FUNCNAME[@]}:$LINENO]" >&2'


################################# FUNCTIONS

function FUNCdtFlNm() {
	date +'%Y_%m_%d-%H_%M_%S'
};export FUNCdtFlNm

FUNCchkDeps() {
	while ! ${1+false};do
		if ! which "$1";then
			FUNCechoInfo "ERROR: missing dependency '$1'"
			FUNCexit 1;
		fi
		shift
	done
};export -f FUNCchkDeps

#FUNCask() { #use read cmd options
	#while read -t 0.1 -n 1;do :;done #clear key buffer
	#local lstrResp
	#read "$@" lstrResp&&:;local lnRet=$?
	#echo "$lstrResp"
	#return $lnRet
#};export -f FUNCask
FUNCaskYesNo() { # <questionForYesNo>. use like: if FUNCaskYesNo "oi?";then ...
	while read -t 0.1 -n 1;do :;done #clear key buffer
	local lstrResp
	echo -n "${1}? (y/...)" >&2
	read -n 1 lstrResp&&:
	if [[ "$lstrResp" =~ [yY] ]];then return 0;fi
	return 1
};export -f FUNCaskYesNo

FUNCwaitSeconds() {
	read -t $1 -n 1 -p "[WAITING:${1}s] ${2-} (press a key to continue)"
};export -f FUNCwaitSeconds
FUNCwait() {
	FUNCwaitSeconds $((60*60*24*31*12)) "${1-}"
};export -f FUNCwait
FUNCwait10s() {
	FUNCwaitSeconds 10 "${1-}"
};export -f FUNCwait10s
FUNCwait60s() {
	FUNCwaitSeconds 60 "${1-}"
};export -f FUNCwait10s

FUNCexit() {
	if [[ $* -gt 0 ]];then
		if(($1 != 0));then
			read -n 1 -p "[ERROR] $1" >&2 #because the script keeps running and wont stop not abruptly exit to terminal anymore!!!! :(, this is the only way to see problems now... :(
		fi
		exit $1
	fi
	exit 0
};export -f FUNCexit
trap 'echo "Ctrl+C pressed, exiting..." >&2; exit 1' INT
#trap 'read -n 1 -p "Ctrl+C pressed, exiting..." >&2; exit 1' INT


####################################### MAIN

: ${bVerbose:=false} #help enable this to see auto configured variables thru `declare`
exec 3>/dev/null   # Point FD 3 to /dev/null
if $bVerbose;then
	exec 3>&2          # Point FD 3 to stderr
fi

: ${bChkVpkExec:=false} #help
strVpkExec="$HOME/.local/bin/vpk"
if $bChkVpkExec;then
	if [[ ! -f "$strVpkExec" ]];then
		set -x
		if ! which pip;then
			sudo -k apt install python3-pip
		fi
		pip install vpk
		set +x
	fi
fi

: ${bDoPrivacyChecks:=true} #help
if $bDoPrivacyChecks;then
	#KEEPinfo: if egrep "$USER" * -iRnIa |egrep -v ".SUCCESS.cfg:|.log:";then #this may end weird
	if egrep "$USER" * -iRnIa --exclude="*.SUCCESS.cfg" --exclude="*.log" --exclude="*.bkp" --exclude="*.pyc" || ls -lR |egrep "[-]>.*$USER";then
		echo "[PROBLEM:] user name found in files that go to git"
		
		#strTimeStampRegex="[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}[.][0-9]{9} [+-][0-9]{4}"
		if false;then # helpful one-line-cmd simple scripts meant to be run copy/paste on the terminal, like one time use
			# this helps on fixing patch files:
			optWrite="-i.bkp";optWrite="";FUNCfixPatchFiles(){ echo;echo ">>>>>>>>>>>>>> $1";sed $optWrite -r -e 's,^(---)([^\t]*)\t(.*),\1 /dev/fd/63\t\3,g' -e 's,^([+][+][+])([^\t]*)\t(.*),\1 /dev/fd/62\t\3,g' "$1"; };export -f FUNCfixPatchFiles;find -iname "*.patch" -exec bash -c "FUNCfixPatchFiles '{}'" \;
		fi
		
		FUNCexit 1
	fi
fi

# Detect the OS environment safely
OS_ENV=$(uname -s)
: ${strOSEnvType:=""} #help override in case it is failing to detect
if [[ -z "$strOSEnvType" ]];then
	case "$OS_ENV" in
		CYGWIN*)
			echo "[Environment: Cygwin detected.]"
			
			# Example Windows path to convert
			WIN_PATH="C:\Users\Public\Documents"
			
			# Convert Windows path to Unix format using cygpath
			UNIX_PATH=$(cygpath -u "$WIN_PATH")
			echo " Windows Path: $WIN_PATH"
			echo " Unix Format: $UNIX_PATH"
			
			strOSEnvType=cygwin #help
			;;
			
		MSYS*|MINGW*)
			echo "[Environment: Git Bash / MSYS / MinGW detected.]"
			# Uses standard POSIX paths directly
			strOSEnvType=mingw #help
			;;
			
		Linux)
			echo "[Environment: Linux detected.]"
			strOSEnvType=linux #help
			;;
			
		Darwin)
			echo "[Environment: macOS detected.]"
			strOSEnvType=macos #help
			;;
			
		*)
			echo "[Environment: Unknown ($OS_ENV)]"
			echo "override strOSEnvType"
			FUNCexit 1
			;;
	esac
fi

# sed to prettify arrays into multilines use like: declare -p astr |sed -r -e "$strSedArrayLn"  >&3
strSedArrayLn='s@(\[[0-9]*\]=)@\n \1@g'
strSedArrayNumToLn="$strSedArrayLn"
strSedArrayIDsToLn='s@(\[[a-zA-Z0-9_/.]*\]=)@\n \1@g'

# all text file extensions
astrScriptsExt=()
astrScriptsExt+=("txt" "vmt" "cfg" "vmf" "res" "qc" "nut" "vdf" "vcd" "scr" "lst" "smd" "vmap" "vmat" "vpcf" "vcfg" "vsndevts" "qct") #from AI question
astrScriptsExt+=(js tag ttj ahk ain bat bns cfg css dat fgd gam html inf ini js lst md org php qc qct rad rc res scr sh smd tga txt vbsp vcd vdf vmf vmt) #clear;find . -mount -type f -exec bash -c 'file -b --mime-type "$1" | grep -q "^text/"' _ {} \; -print | awk -F. 'NF>1 {print $NF}' | sort -u #vpk is not 
astrScriptsExt=($(echo "${astrScriptsExt[@]}" |tr ' ' '\n' |sort -u))
#declare -p astrScriptsExt |tr '[' '\n' >&3
strScriptsExtRegexEsc=".*[.]\($(echo "${astrScriptsExt[@]}" |sed -r -e 's@ @\\|@g')\)$"
strScriptsExtRegexNorm=".*[.]($(echo "${astrScriptsExt[@]}" |sed -r -e 's@ @|@g'))$"
strJustExtRegexEsc="$(echo "${astrScriptsExt[@]}" |sed -r -e 's@ @\\|@g')$"
strJustExtRegex="$(echo "${astrScriptsExt[@]}" |sed -r -e 's@ @|@g')$"
astrGrepIncludesExt=()
for strExt in "${astrScriptsExt[@]}";do
	astrGrepIncludesExt+=(--include="*.${strExt}")
done

declare -p strScriptsExtRegexEsc strScriptsExtRegexNorm >&3

strPathSelf="$(pwd)"
strPathMainModFolder="${strPathSelf}"
if [[ ! -f "${strPathSelf}/$(basename "$0")" ]];then
	echo "[ERROR] failed to determine ModMerger path: current path '$strPathSelf' doesnt contain $(basename "$0")"
	FUNCexit 1
fi
strPathParent="$(dirname "$strPathSelf")" #help This is the folder where all Layers are placed, it is the parent of game main folder. this is important to be detected like that in case this path is a symlink! when using '../' would navigate to the realpath!

: ${strGameSubRelatFolderWriteAllHere:="WriteNewDataHereOnly"};export strGameSubRelatFolderWriteAllHere #help I know of: mm custom AddOn(overhaul mod) and my new one WriteNewDataHereOnly

: ${strGameInstallMainFolder:="${strPathParent}/Dark Messiah Might and Magic Single Player"} #help vanilla game installed main folder

: ${strVanillaLayer:="$(ls -d "${strGameInstallMainFolder}"*VanillaGameFiles*)"} #help vanilla game installed files' folder
if [[ ! -d "$strVanillaLayer" ]];then
	pwd
	echo "selfRunParam0: $0"
	declare -p strVanillaLayer strGameInstallMainFolder
	echo "ERROR: vanilla layer not found";
	FUNCexit 1;
fi

#: ${strVanillaScriptsFolder:="${strGameInstallMainFolder}.layer004.VanillaExtractedTextFiles.IGNORE_LAYER"} #help
: ${strVanillaScriptsPath:="$(ls -d "${strGameInstallMainFolder}"*VanillaExtractedTextFiles*/)"} #help after installing the game, use some vpk extractor (like thru one of the other bash scripts here)
if [[ ! -d "$strVanillaScriptsPath" ]];then echo "ERROR: VanillaExtractedTextFiles layer not found";FUNCexit 1;fi

: ${strWriteLayer:="${strGameInstallMainFolder}.0.WriteLayer"} #help write output thru OverlayFS

: ${strDownloadedModFilesRel:=".modPackages"} #help
: ${strDisabledTmpTestFolderRel:=".DisabledTmpTest"} #help

: ${strMergedModsFolderBN:="FinalMergedScriptsMaxPriority"} #help
: ${strMergedModsFolder:="${strPathSelf}/_mods/${strMergedModsFolderBN}"} #help
mkdir -vp "${strMergedModsFolder}"

strFinalMergedFolderContent="${strMergedModsFolder}/content/" #help compatible with mod manager
mkdir -vp "$strFinalMergedFolderContent"

strFinalDummyHelperFolder="${strMergedModsFolder}/dummy/"
mkdir -vp "${strFinalDummyHelperFolder}"

: ${strRegexFoldersToIgnore:="IGNORE_LAYER|Extracted.Quick.TMP|/_tmp/|/tmp/"} #help this is compatible with secOverrideMultiLayerMountPoint.sh that is using OverlayFS

strFlFinalMergerModJson="$strMergedModsFolder/info.json"

astrKnownGameModRelativeFolders=( #help from mini mods or overhaul EDIT THIS LINE TO ADD NEW ONES IF EVER
	mm #vanilla, also used by many mods
	custom #some mods use this
	AddOn #overhaul mod
	content #ModLauncher mods
) 
strRegexKGMRF=""
strRegexEscKGMRF=""
for strKGMRF in "${astrKnownGameModRelativeFolders[@]}";do
	if [[ -n "${strRegexKGMRF}" ]];then strRegexKGMRF+="|";fi
	if [[ -n "${strRegexEscKGMRF}" ]];then strRegexEscKGMRF+='\|';fi
	strRegexKGMRF+="${strKGMRF}"
	strRegexEscKGMRF+="${strKGMRF}"
done

function FUNCfileRelat() {
	local lstrFile="$1"
	
	if [[ "${lstrFile}" =~ .*/_mods/.* ]];then
		echo "$lstrFile" |sed -r -e 's@.*/_mods/.*/content/(.*)@\1@I'
	else
		echo "$lstrFile" |sed -r -e "s@.*/(${strRegexKGMRF})/(.*)@\2@I"
	fi
};export -f FUNCfileRelat

function FUNCpatchMode() {
	local lstrFileToMerge="$1"
	declare -p lstrFileToMerge >&2
	
	local lbKeyValueDiffMode=false
	local lstrExt="$(echo "${lstrFileToMerge}" |sed -r -e 's@.*[.]([a-zA-Z0-9_]*)$@\1@')"
	declare -p lstrExt >&2
	if [[ -z "$lstrExt" ]];then
		FUNCechoInfo "[ERROR] invalid filename without extension '$lstrFileToMerge'" >&2
		FUNCexit 1
	fi
	if [[ "$lstrFileToMerge" =~ .*/gameinfo[.]txt$ ]];then
		lstrExt="ForceCodePatchMode"
	fi
	case $lstrExt in
		lst|qct|txt|vmt)
			lbKeyValueDiffMode=true
			strFlPatch="${lstrFileToMerge}.kvpatch.json" # OBS.: using default patch.json would automatically create the same file but it is not output there, so if it changes there at keyValuPatcher.py, will miss here
			;;
		#KEEPinfo: cfg) # see *) uses generic code patcher way
			#;;
		*) #ForcePatchMode
			lbKeyValueDiffMode=false
			strFlPatch="${lstrFileToMerge}.patch"
			;;
	esac
	# special files that keys are meant to happen more than once in the same hierarchy nesting depth
	astrSpecialCodePatchingModeFiles=(
		# no need, .kvpatch.json supports it now: "resource/closecaption_manifest.txt$"
	)
	strSpecialCodePatchingModeFiles="$(echo "${astrSpecialCodePatchingModeFiles[@]}" |tr ' ' '|')"
	if [[ -n "$strSpecialCodePatchingModeFiles" ]];then
		if echo "${lstrFileToMerge}" |egrep -q "${strSpecialCodePatchingModeFiles}";then
				lbKeyValueDiffMode=false
				strFlPatch="${lstrFileToMerge}.patch"
		fi
	fi
	
	echo "$strFlPatch" # OUTPUT TO BE CAPTURED!
	
	if $lbKeyValueDiffMode;then
		return 0
	else
		return 1
	fi
};export -f FUNCpatchMode

: ${strExecMerger:="meld"} #help
if ! which "$strExecMerger" >&3;then
	strExecMerger="winmerge" # for cygwin/windows
fi
if ! which "$strExecMerger" >&3;then
	FUNCechoInfo "ERROR: no GUI merger tool found"
	FUNCexit 1
fi

echo  >&3
declare -p strMergedModsFolder strDisabledTmpTestFolderRel strDownloadedModFilesRel strVanillaLayer strVanillaScriptsPath strWriteLayer strFinalMergedFolderContent strFinalDummyHelperFolder strFlFinalMergerModJson astrKnownGameModRelativeFolders strRegexKGMRF >&3
echo >&3

FUNCtrash() {
	#while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do # checks if param is set
	while ! ${1+false};do
		if [[ -f "$1" ]];then
			echo "[Trashing] '$1'"
			trash "$1"
		fi
		shift
	done
	return 0
};export -f FUNCtrash

function SECFUNCshowHelpV2() { #help TODO WIP making it much easier to maintain!!!!!!!!
	local lstrFlHelp="$1"
	
	echo "[HELP for:] $lstrFlHelp  # OPTION DEFAULT DESCRIPTION"
	
	local lastrHelpList
	IFS=$'\n' read -d '' -r -a lastrHelpList < <(egrep "[#]help" "$lstrFlHelp")&&:
	
	local lstrHelp
	local lstrCommentedLinesRegex='^\s*#'
	local lstrCommentedLinesInfoRegex='#help.*[@]InfoID'
	local lnColW0max=0
	local lnColW1max=0
	
	local lastrColumnsPerLine=()
	local lastrColumnsAllLinesEnv=()
	local lastrColumnsAllLinesParam=()
	local lastrColumnsAllLinesInfo=()
	
	local lcolorEqualSign
	local lcolorOptParameter
	local lcolorOptParamVar
	local lcolorValue
	local lcolorReqOpenClose
	local lcolorEnvVar
	local lcolorInfo
	local lcolorCode
	local lcolorEnd
	function FUNCcolorSet() {
		lcolorEqualSign='\\E[0m\\E[33m'
		lcolorOptParameter='\\E[0m\\E[92m'
		lcolorOptParamVar='\\E[0m\\E[36m'
		lcolorValue='\\E[0m\\E[93m'
		lcolorReqOpenClose='\\E[0m\\E[31m'
		lcolorEnvVar='\\E[0m\\E[36m\\E[2m'
		lcolorInfo='\\E[0m\\E[37m\\E[2m'
		lcolorCode='\\E[0m\\E[94m'
		lcolorEnd='\\E[0m'
	};export -f FUNCcolorSet
	function FUNCcolorUnset() {
		lcolorEqualSign=""
		lcolorOptParameter=""
		lcolorOptParamVar=""
		lcolorValue=""
		lcolorReqOpenClose=""
		lcolorEnvVar=""
		lcolorInfo=""
		lcolorEnd=""
	};export -f FUNCcolorUnset
	
	FUNCalignIgnoringEscColorChars() {
		local lstrCol0
		local lstrCol1
		local lstrCol2
    while IFS=$'\t' read -r lstrCol0 lstrCol1 lstrCol2; do
        # 1. Strip ANSI escape color codes to get true visual length
        local lstrClean0=$(echo -e "$lstrCol0" | sed 's@\x1b\[[0-9;]*m@@g')
        local lstrClean1=$(echo -e "$lstrCol1" | sed 's@\x1b\[[0-9;]*m@@g')

        # 2. Calculate required padding spaces
        local lstrPad1=$(( lnColW0max - ${#lstrClean0} ))
        local lstrPad2=$(( lnColW1max - ${#lstrClean1} ))

        # 3. Prevent negative padding numbers if string exceeds the width
        (( lstrPad1 < 0 )) && lstrPad1=0
        (( lstrPad2 < 0 )) && lstrPad2=0

        # 4. Generate the space strings
        local lstrSpaces1=$(printf '%*s' "$lstrPad1" "")
        local lstrSpaces2=$(printf '%*s' "$lstrPad2" "")

        # 5. Output using echo -e so the colors render correctly
        # indent with 2 spaces so if there is a line wrap beggining with one space, it will differ
        echo -e "  ${lstrCol0}${lstrSpaces1} ${lstrCol1}${lstrSpaces2} [#]${lstrCol2}"
    done
	};export -f FUNCalignIgnoringEscColorChars
	
	: ${bSECShowHelpColoredMode:=true} #help_SECFUNCshowHelpV2
	if $bSECShowHelpColoredMode;then
		FUNCcolorSet
	else
		FUNCcolorUnset
	fi
	
	function FUNChelpPrint() {
		#set -x
		#echo -e "$(printf "  %-${lnColW0max}s %-${lnColW1max}s [#]%s\n" "${lastrColumnsPrint[@]}")" # indent with 2 spaces so if there is a line wrap beggining with one space, it will differ
		#printf "  %-${lnColW0max}s %-${lnColW1max}s [#]%s\n" "${lastrColumnsPrint[@]}" |align_colored_columns
		#printf "%-${lnColW0max}s\t%-${lnColW1max}s\t[#]%s\n" "${lastrColumnsPrint[@]}" |FUNCalignIgnoringEscColorChars
		printf "%s\t%s\t%s\n" "${lastrColumnsPrint[@]}" |FUNCalignIgnoringEscColorChars
		#set +x
	};export -f FUNChelpPrint
	
	for lstrHelp in "${lastrHelpList[@]}";do
		#if [[ "$lstrHelp" =~ ${lstrCommentedLinesRegex} ]];then continue;fi # skip commented lines
		if [[ "$lstrHelp" =~ ${lstrCommentedLinesRegex} ]] && ! [[ "$lstrHelp" =~ ${lstrCommentedLinesInfoRegex} ]];then continue;fi # skip commented lines
		
		strHelpType=""
		
		: ${bSECFUNCshowHelpV2_FUNCverboseHelpCleanup:=false};FUNCverboseHelpCleanup() { if $bSECFUNCshowHelpV2_FUNCverboseHelpCleanup;then echo "Ln$1: lstrHelp=\"$lstrHelp\"";fi }
		FUNCverboseHelpCleanup $LINENO
		
		############## line cleanup BEGIN
		
		lstrHelp="$(echo "$lstrHelp" |sed -r -e 's@^[ \t]*@@')" #remove beggining spaces
		FUNCverboseHelpCleanup $LINENO
		
		if [[ "${lstrHelp:0:1}" == ":" ]];then strHelpType=env;fi
		
		lstrHelp="$(echo "$lstrHelp" |sed -r -e 's@^\s*(if|elif) *\[\[ *"\$\{1[-]*\}" *== *"(.*)" *\]\];then [#]help[_ ]*(.*)@\2\t\3@')" #clean param simple options like: if [[ "${1}" == "-a" ]];then
		FUNCverboseHelpCleanup $LINENO
		
		#lstrHelp="$(echo "$lstrHelp" |sed -r -e 's@if *\[\[ \$# -gt 0 && *"\$\{1[-]*\}" *== *"(.*)" *\]\];then [#]help[_ ]*(.*)@\1\t\2@')" #clean param simple options like: if [[ $# -gt 0 && "$1" == "--help" ]];then
		#FUNCverboseHelpCleanup $LINENO
		
		lstrHelp="$(echo "$lstrHelp" |sed -r -e 's@^\s*(if|elif) *\[\[ *"\$[{]*1[}]*" *== *"(.*)" *\|\| *"\$[{]*1[}]*" *== *"(.*)" *\]\];then [#]help[_ ]*(.*)@\2 \3\t\4@')" #clean param options for options loop like: if [[ "${1}" == "-a" || "${1}" == "--alert"]];then
		FUNCverboseHelpCleanup $LINENO
		
		if [[ "${lstrHelp:0:1}" == "-" ]];then strHelpType=param;fi
		
		#if ! [[ "$lstrHelp" =~ ^:\ \$\{.* ]] && ! [[ "$lstrHelp" =~ ^\-.* ]] && ! [[ "$lstrHelp" =~ ${lstrCommentedLinesInfoRegex} ]];then continue;fi #after line is cleaned, skip non env (env is already a very clean line) nor param options nor info. (probably just non optional configs (may be shown later thru declare just to let user know what is happening. Could become options may be?)
		FUNCverboseHelpCleanup $LINENO
		
		if [[ "$strHelpType" == env ]];then
			lstrHelp="$(echo "$lstrHelp" |sed -r -e 's@(.*);export.*([#]help)@\1 \2@')" #clean env export directive
			lstrHelp="$(echo "$lstrHelp" |sed -r -e 's@^:\s*[$][{]([^:]*):=(.*)[}]\s*[#]help[_ ]*(.*)@\1\t\2\t\3@')" #clean env options like: : ${bTest:=true}
			FUNCverboseHelpCleanup $LINENO
		fi
		
		if [[ "$lstrHelp" =~ ${lstrCommentedLinesInfoRegex} ]];then strHelpType=info;fi
		lstrHelp="$(echo "$lstrHelp" |sed -r -e 's%.*[#]help[_ ]*[@]InfoID="([^"]*)"\s*(.*)%\1\t\2%')" #clean info options like: @InfoID="SomethingUnique123" help text description...
		FUNCverboseHelpCleanup $LINENO
		
		if [[ -z "$strHelpType" ]];then continue;fi
		
		############## line cleanup END
		
		IFS=$'\n' read -d '' -r -a lastrColumnsPerLine < <(echo "$lstrHelp" |sed -r -e 's@\t@\n@' -e 's@\t@\n@')&&:
		#if [[ "${lastrColumnsPerLine[0]}" =~ ^[-].* ]];then strHelpType=param;fi
		
		# Before being colored
		if((lnColW0max<${#lastrColumnsPerLine[0]}));then lnColW0max=${#lastrColumnsPerLine[0]};fi
		if((lnColW1max<${#lastrColumnsPerLine[1]}));then lnColW1max=${#lastrColumnsPerLine[1]};fi
		
		#local lastrColumnsPerLine=($(echo "$lstrHelp" |sed -r -e 's@\t@\n@g'))
		case "$strHelpType" in
			param)
				lastrColumnsPerLine[0]="${lcolorOptParameter}${lastrColumnsPerLine[0]}${lcolorEnd}"
				# a param will have no default value column
				if((${#lastrColumnsPerLine[@]} < 3));then lastrColumnsPerLine=("${lastrColumnsPerLine[0]}" "  " "${lastrColumnsPerLine[1]-}");fi
				;;
			env)
				lastrColumnsPerLine[0]="${lcolorEnvVar}${lastrColumnsPerLine[0]}${lcolorEnd}"
				# an env var may have no help description
				if((${#lastrColumnsPerLine[@]} < 3));then lastrColumnsPerLine=("${lastrColumnsPerLine[0]}" "${lastrColumnsPerLine[1]-}" "");fi
				;;
			info)
				lastrColumnsPerLine[0]="${lcolorInfo}${lastrColumnsPerLine[0]}${lcolorEnd}"
				# an env var may have no help description
				if((${#lastrColumnsPerLine[@]} < 3));then lastrColumnsPerLine=("${lastrColumnsPerLine[0]}" "  " "${lastrColumnsPerLine[1]-}");fi
				;;
			*) echo "[WARN] invalid strHelpType='$strHelpType'" >&2; continue;;
		esac
		#if [[ "${lastrColumnsPerLine[0]}" =~ ^\-.* ]];then
			#lastrColumnsPerLine[0]="${lcolorOptParameter}${lastrColumnsPerLine[0]}${lcolorEnd}"
			## a param will have no default value column
			#if((${#lastrColumnsPerLine[@]} < 3));then lastrColumnsPerLine=("${lastrColumnsPerLine[0]}" "  " "${lastrColumnsPerLine[1]-}");fi
		#else
			#lastrColumnsPerLine[0]="${lcolorEnvVar}${lastrColumnsPerLine[0]}${lcolorEnd}"
			## an env var may have no help description
			#if((${#lastrColumnsPerLine[@]} < 3));then lastrColumnsPerLine=("${lastrColumnsPerLine[0]}" "${lastrColumnsPerLine[1]-}" "");fi
		#fi
		
		# This fixes the double escaped \\E into \E to match lastrColumnsPerLine[2] below
		lastrColumnsPerLine[0]="$(echo -e "${lastrColumnsPerLine[0]}")"
		lastrColumnsPerLine[1]="$(echo -e "${lcolorReqOpenClose}<${lcolorCode}${lastrColumnsPerLine[1]}${lcolorReqOpenClose}>${lcolorEnd}")"
		
		#echo "${lastrColumnsPerLine[2]}"
		local lstrDefaultVar="$(echo "${lastrColumnsPerLine[2]}" |sed -n -r -e 's@(.*<)(.*)(>.*)@\2@p')" #from help column
		#declare -p lstrDefaultVar
		if [[ -n "$lstrDefaultVar" ]] && [[ "$lstrDefaultVar" =~ ^[a-zA-Z0-9_]*$ ]];then
			local lstrDefVal="$(eval "echo \"\${$lstrDefaultVar}\"")" #KEEPinfo: eval is properely protected
			#declare -p lstrDefaultVar lstrDefVal
			local lstrHelpWithVarValues="${lastrColumnsPerLine[2]}"
			#echo "${lstrHelpWithVarValues}" |sed -n -r -e 's@(.*<)('"${lstrDefaultVar}"')(>.*)@\1'"${lstrDefaultVar}=\"${lstrDefVal}\""'\3@p'
			
			local lstrVarAndVal
			function FUNCsetVarAndVal() {
				lstrVarAndVal=""
				lstrVarAndVal+="${lcolorReqOpenClose}<"
				lstrVarAndVal+="${lcolorOptParamVar}${lstrDefaultVar}"
				lstrVarAndVal+="${lcolorEqualSign}="
				lstrVarAndVal+="${lcolorValue}\"${lstrDefVal}\""
				lstrVarAndVal+="${lcolorReqOpenClose}>"
				lstrVarAndVal+="${lcolorEnd}"
			};export -f FUNCsetVarAndVal
			FUNCcolorUnset
			FUNCsetVarAndVal
			:
			FUNCcolorSet
			FUNCsetVarAndVal
			
			lastrColumnsPerLine[2]="$(echo "${lstrHelpWithVarValues}" |sed -n -r -e 's@(.*)<('"${lstrDefaultVar}"')>(.*)@\1'"${lstrVarAndVal}"'\3@p')"
			#echo "${lstrHelpWithVarValues}" |sed -n -r -e 's@(.*)<('"${lstrDefaultVar}"')>(.*)@\1'"${lcolorReqOpenClose}<${lcolorOptParamVar}${lstrDefaultVar}${lcolorEqualSign}=${lcolorValue}\"${lstrDefVal}\"${lcolorReqOpenClose}>${lcolorEnd}"'\3@p'
			#echo "${lastrColumnsPerLine[2]}"
		else
			if [[ -n "$lstrDefaultVar" ]];then
				echo "[ERROR] invalid (potentialy dangerous) variable name '$lstrDefaultVar' to eval for value."
				exit 1
			fi
		fi
		
		case "$strHelpType" in
			param) lastrColumnsAllLinesParam+=("${lastrColumnsPerLine[@]}") ;;
			env)   lastrColumnsAllLinesEnv+=("${lastrColumnsPerLine[@]}")   ;;
			info)  lastrColumnsAllLinesInfo+=("${lastrColumnsPerLine[@]}")   ;;
			*) echo "[WARN] invalid strHelpType='$strHelpType'" >&2; continue;;
		esac
		
#		printf " %-${nHelpTableColWidth0}s %-${nHelpTableColWidth1}s %s\n" "${lastrColumnsPerLine[@]}"
	done #| column -t -s $'\t' -W 2
	
	#declare -p lnColW1max
	if((lnColW1max>15));then lnColW1max=15;fi
	#declare -p lnColW1max
	local i
	
	if((${#lastrColumnsAllLinesParam[@]}>0));then echo " [OPTIONS:]";fi
	for((i=0;i<${#lastrColumnsAllLinesParam[@]};i+=3));do
		local lastrColumnsPrint=("${lastrColumnsAllLinesParam[i+0]}" "${lastrColumnsAllLinesParam[i+1]}" "${lastrColumnsAllLinesParam[i+2]}")
		FUNChelpPrint
	done
	
	if((${#lastrColumnsAllLinesEnv[@]}>0));then echo " [ENV VARS:] (set like this to easy change on each execution ex.: bDummy1=true strDummy2=\"abc\" $0; #OR to set for the terminal export bDummy1=true; export strDummy2=\"abc\"; #Then later you just run: $0)";fi
	for((i=0;i<${#lastrColumnsAllLinesEnv[@]};i+=3));do
		local lastrColumnsPrint=("${lastrColumnsAllLinesEnv[i+0]}" "${lastrColumnsAllLinesEnv[i+1]}" "${lastrColumnsAllLinesEnv[i+2]}")
		FUNChelpPrint
	done
	
	if((${#lastrColumnsAllLinesInfo[@]}>0));then echo " [INFO:]";fi
	for((i=0;i<${#lastrColumnsAllLinesInfo[@]};i+=3));do
		local lastrColumnsPrint=("${lastrColumnsAllLinesInfo[i+0]}" "${lastrColumnsAllLinesInfo[i+1]}" "${lastrColumnsAllLinesInfo[i+2]}")
		FUNChelpPrint
	done
	
	#declare -p lastrColumnsAllLinesParam lastrColumnsAllLinesEnv
	
	echo
};export -f SECFUNCshowHelpV2

#function FUNCparseJson() {
	#local lstrFlJson="$1";shift
	#local lstrFilterJson="$1";shift
	#exec 5> >(lstrStdErr=$(cat))
	##cat "$lstrFlJson" |jq "${lstrFilterJson}" 3>&1 1>&2 2>&3
	#cat "$lstrFlJson" |jq "${lstrFilterJson}" 2>&5
	#exec 5>&- #close custom descriptor
#}
function FUNCjson() {
	local lbIgnoreMissing=false
	if [[ "$1" == --ignoremissing ]];then shift;lbIgnoreMissing=true;fi
	
	local lstrFlJson="$1";shift
	local lstrFilterJson="$1";shift
	
	#local lstrStdErr="$(FUNCparseJson "$lstrFlJson" "$lstrFilterJson")"&&:;local lnRet=$?
	#local lstrStdErr="$( { FUNCparseJson "$lstrFlJson" "$lstrFilterJson"; } 3>&1 1>&2 2>&3)"&&:;local lnRet=$?
	#FUNCparseJson "$lstrFlJson" "$lstrFilterJson"&&:;local lnRet=$?

	#local lstrStdErr
	#exec 5> >(lstrStdErr="$(cat)")
	##cat "$lstrFlJson" |jq "${lstrFilterJson}" 3>&1 1>&2 2>&3
	#cat "$lstrFlJson" |jq "${lstrFilterJson}" 2>&5 &&:;local lnRet=$?
	#declare -p lstrStdErr >&2
	#exec 5>&- #close custom descriptor
	
	local lstrFlErr="$(mktemp -p /dev/shm)"
	cat "$lstrFlJson" |jq "${lstrFilterJson}" 2>"${lstrFlErr}" &&:;local lnRet=$? #### OUTPUTS DATA HERE!!!
	local lstrStdErr="$(cat "$lstrFlErr")"
	rm "$lstrFlErr"
	#declare -p lstrFlErr lstrFlJson lstrFilterJson >&2
	#declare -p lstrStdErr >&2
	
	#jq "$@"&&:;local lnRet=$? # jq outputs data here
	if((lnRet==1 || lnRet==0));then return 0;fi
	if((lnRet==5)) && $lbIgnoreMissing;then return 0;fi # ignore missing data mainly for get it
	case $lnRet in
		2|3|4) echo jq "$@" >&2;FUNCechoInfo "[ERROR:${FUNCNAME[@]-}] in 'jq': \`$@\` # ${lstrStdErr}" >&2; FUNCexit 1;;
		*)     echo jq "$@" >&2;FUNCechoInfo "[ERROR:${FUNCNAME[@]-}] UNKNOWN($lnRet) in 'jq': \`$@\` # ${lstrStdErr}" >&2; FUNCexit 1;;
	esac
	
	return 0;
};export -f FUNCjson
FUNCjsonSet() {
	local lstrFlJson="$1";shift
	FUNCjson "$lstrFlJson" ".${1} = \"${2}\"" |sponge "$lstrFlJson"
};export -f FUNCjsonSet
function FUNCjsonGetArray() {
	local lstrFlJson="$1";shift
	local lstrID="$1";shift
	FUNCjson --ignoremissing "$lstrFlJson" ".${lstrID}[]" |sed -r -e 's@^"@@' -e 's@"$@@' |sort -u
};export -f FUNCjsonGetArray
FUNCjsonSetArray() {
	local lstrFlJson="$1";shift
	local lstrID="$1";shift
	local lastrCfgsList=("$@")
	
	local lstrArrayCfg=""
	for((i=0;i<${#lastrCfgsList[@]};i++));do
		if [[ -z "${lastrCfgsList[i]}" ]];then continue;fi
		if((i>0));then lstrArrayCfg+=", ";fi
		lstrArrayCfg+="\"${lastrCfgsList[i]}\"";
	done
	FUNCjson "$lstrFlJson" ".${lstrID} = [ ${lstrArrayCfg} ]" |sponge "$lstrFlJson"
};export -f FUNCjsonSetArray

function FUNCisPidStopped() { #help <pid>
	local lstrState="$(ps --no-headers -o state -p $1)"
	if [[ "$lstrState" == T ]];then return 0;fi
	return 1
};export -f FUNCisPidStopped

function FUNCminiModInit() {
	# go to the path of the real file
	if [[ -L "$0" ]];then cd "$(dirname "$(readlink "$0")")";fi # a link at main mod root folder pointing to some minimod sub folder
	if [[ ! -f "$(basename "$0")" ]];then cd "$(dirname "$0")";fi # in case run by using some relative or absolute path
	
	declare -g strPathThisModFolderFull="$(pwd)";FUNCechoInfo "strPathThisModFolderFull='$strPathThisModFolderFull'" >&2
	declare -g strPathThisModFolderBN="$(basename "${strPathThisModFolderFull}")";FUNCechoInfo "strPathThisModFolderBN='$strPathThisModFolderBN'" >&2
	
	#while [[ ! -f "./allMergerScriptsGenericConfig.sh" ]];do cd ..;done
	#declare -g strPathMainModFolder="$(pwd)"
	
	#source "./allMergerScriptsGenericConfig.sh"
	
	if [[ $# -gt 0 ]];then
		if [[ "${1}" == "--help" ]];then #help show this help
			#egrep "[#]help" "./allMergerScriptsGenericConfig.sh" "$0" |sed -r -e 's@^[ \t]*@@'
			SECFUNCshowHelpV2 "${strPathMainModFolder}/allMergerScriptsGenericConfig.sh"
			SECFUNCshowHelpV2 "${strPathThisModFolderFull}/$(basename "$0")"
			
			: ${FUNCminiModInit_bExitOnHelpAtBaseInit:=true} #help
			if $FUNCminiModInit_bExitOnHelpAtBaseInit;then FUNCexit;fi #this will not consume the param so it can be reused at main file
			
			: ${FUNCminiModInit_bConsumeParamHelp:=true} #help
			if $FUNCminiModInit_bConsumeParamHelp;then shift;fi #if not, the param can be reused at main file
		elif [[ "${1}" == "-v" || "${1}" == "--verbose" ]];then #help
			bVerbose=true
			shift
		fi
	fi
};export -f FUNCminiModInit

function FUNCgetNewestCondump() {
	declare -g FUNCgetNewestCondump_strFlCondump="$(ls -1tr "${strGameInstallMainFolder}/${strGameSubRelatFolderWriteAllHere}/condump"* |tail -n 1)"} #help can be the backup like "${strMapCfgFile}.condump.txt"
	ls -l "$strFlCondump" >&2 &&:
};export -f FUNCgetNewestCondump
function FUNCmapInfo() {
	local lstrFlCondump="$1"
	
	# map     :  L00 at: -1385 x, -4444 y, 343 z
	# map     :  l02_b1 at: -4902 x, -10930 y, 367 z
	local lstrRegexMapPos='^map\s*:\s*([a-zA-Z0-9_-]*)\s*at:\s*(.*)'
	declare -g FUNCmapInfo_strMapStatus="$( ugrep "${lstrRegexMapPos}" "$lstrFlCondump" |awk 'length($0) > max { max = length($0); delete lines; lines[$0]; next } length($0) == max { lines[$0] } END { for (l in lines) print l }' )"
	if(($(echo "$FUNCmapInfo_strMapStatus" |wc -l) != 1));then FUNCechoInfo "[ERROR:] 2 biggest lines conflicting: $FUNCmapInfo_strMapStatus";FUNCexit 1;fi
	declare -g FUNCmapInfo_strMapName
	: ${FUNCmapInfo_strMapName:="$(echo "$FUNCmapInfo_strMapStatus" |sed -r -e "s@${lstrRegexMapPos}@\1@g")"} #help
	if [[ -z "$FUNCmapInfo_strMapName" ]];then
		FUNCechoInfo "[ERROR:] no Map Name Detected "
		FUNCexit 1
	fi

	declare -g FUNCmapInfo_strPosRestore="$(echo "${FUNCmapInfo_strMapStatus}" |sed -r -e "s@${lstrRegexMapPos}@\2@g" |tr -d 'xyz,\r')"
	if [[ -z "$FUNCmapInfo_strPosRestore" ]];then
		FUNCechoInfo "[ERROR:] no Pos To Restore Detected"
		FUNCexit 1
	fi
	strRestorePosInTheEnd="setpos ${FUNCmapInfo_strPosRestore}"
};export -f FUNCmapInfo
