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

FUNCchkDeps unix2dos iconv file

: ${strAliasPrefix:=gsk} #help


if [[ ! -f "${strGameInstallMainFolder}/mm.exe" ]];then
	echo "[PROBLEM] Please mount '${strGameInstallMainFolder}' to be sure what is active to properly prepare the keybindings."
	exit 1
fi

FUNCrefreshMount # if it did not update, means OverlayFS needs refresing to sync with modified files.

mapfile -t astrAliasList < <(cat gskEnabledBinds.DoNotEnable.cfg |grep "^bind" |egrep -v '"' |awk '{print $3}' |egrep "^[+]*${strAliasPrefix}" |tr -d '\r')
strMenuDataBegin='
"lang"
{
    "Language" "English"
    "Tokens"
    {
'
strMenuDataEnd='
    }
}
'
strMenuDataEntries=""
function FUNCgoodDesc() {
	local lstrAlias="$1";shift
	
	local lstrLN="$(grep " ${lstrAlias} " gskEnabledBinds.DoNotEnable.cfg)"
	if [[ "$lstrLN" =~ .*//.* ]];then
		local lstrDesc="$(echo "$lstrLN" | sed -r -e 's@^[^/]*//@@' -e 's@ //.*$@@' -e 's@^[[:space:]]*@@; s@[[:space:]]*$@@')" # works with this to ignore the long description: aaa // short description // long description

		#: ${lnMaxDescSize:=40} #help
		#if((${#lstrDesc} > lnMaxDescSize));then
			#FUNCechoInfo "[WARN] lstrDesc size is too big (${#lstrDesc} chars/$lnMaxDescSize) and will not fit in the menu for '$lstrDesc'"
			#if ! FUNCaskYesNo "continue anyway?";then exit 1;fi
		#fi
		echo -n "$lstrDesc"
		return 0
	fi
	return 1
}
function FUNClazyDesc() {
	local lstrAlias="$1";shift
	
	if FUNCgoodDesc "$lstrAlias";then return 0;fi
	
	local lstrLazyDesc=""
	local i
	for((i=0;i<${#lstrAlias};i++));do
		if [[ "${lstrAlias:$i:1}" =~ [A-Z] ]];then lstrLazyDesc+=" ";fi
		lstrLazyDesc+="${lstrAlias:$i:1}";
	done
	
	echo -n "$lstrLazyDesc" |sed -r -e "s@[+]*${strAliasPrefix} (.*)@\1@g"
}
#set -x
strKVPatches=""
iMaxMenuIdSz=0
strMaxMenuIdSz=""
: ${bDBG:=false} #help
astrDbg=()
#for strAlias in "${astrAliasList[@]}";do
for((iAlias=0;iAlias<${#astrAliasList[@]};iAlias++));do
	strAlias="${astrAliasList[$iAlias]}"
	echo "Working with [$iAlias/${#astrAliasList[@]}]: $strAlias"
	strMenuID="mc_$(echo "$strAlias" |sed -r -e 's@[+]*(.*)@\1@g' |tr '[:upper:]' '[:lower:]')"
	if((iMaxMenuIdSz < ${#strMenuID}));then iMaxMenuIdSz=${#strMenuID}; strMaxMenuIdSz="$strMenuID";fi
	strAliasHurtmeRegex="[+-]*${strAlias}\s+.*hurtme\s*([0-9.]*).*"
	mapfile -t anCost < <(egrep "${strAliasHurtmeRegex}" "$strGameInstallMainFolder"/ -iRIaoh --include="*.cfg" |sed -r -e 's@(.*)//.*@\1@' -e "s@${strAliasHurtmeRegex}@\1@g")
	nCost=0;for nC in "${anCost[@]}";do ((nCost+=nC))&&:;done
	strCost="";if((nCost>0));then strCost=" HP${nCost}";fi
	#declare -p strCost
	strDescription="$(FUNClazyDesc "$strAlias")${strCost}"
	
	: ${nMaxDescSize:=40} #help
	if((${#strDescription} > nMaxDescSize));then
		FUNCechoInfo "[WARN] strDescription size is too big (chars ${#strDescription} max $nMaxDescSize) and will not fit in the menu for '$strDescription'"
		if ! FUNCaskYesNo "continue anyway?";then exit 1;fi
	fi
	
	if $bDBG;then
		astrDbg+=("$(declare -p nCost strAlias strCost) $(egrep "${strAliasHurtmeRegex}" "$strGameInstallMainFolder"/ -iRIaoh --include="*.cfg")")&&:
	fi
	strMenuDataEntries+='
        //# '"$strMenuID"'
        //~ '"$strMenuID"'
        "'"$strMenuID"'" "'"$strDescription"'"
'
	if [[ -n "$strKVPatches" ]];then strKVPatches+=",\n";fi
	strKVPatches+="\t\"${strAlias}\": \"#${strMenuID}\""
	#declare -p strAlias strMenuID strDescription
done
declare -p iMaxMenuIdSz strMaxMenuIdSz
echo "Total binds added: ${#astrAliasList[@]}"

strFlTmp="$(mktemp)"
pwd
echo "${strMenuDataBegin}${strMenuDataEntries}${strMenuDataEnd}" |unix2dos >>"$strFlTmp" #this grants CRLF #|sed 's@$@\r@'
ls -l ../resource/mm_gskcustombinds_english.txt
printf "\xFF\xFE" >../resource/mm_gskcustombinds_english.txt #this grants BOM
iconv -f $(file -b --mime-encoding "$strFlTmp") -t "UTF-16LE" "$strFlTmp" >>../resource/mm_gskcustombinds_english.txt #finally is: UTF-16LE(With BOM)
ls -l ../resource/mm_gskcustombinds_english.txt
if $bVerbose;then
	cat ../resource/mm_gskcustombinds_english.txt
fi
rm "$strFlTmp"

pwd
ls -l ../scripts/kb_act.lst&&:
#HELPkeep but below there is instructions to to it manually... #FUNCtrash ../scripts/kb_act.lst #help this file needs to be trashed to let the reuse of vanilla+kvpatch to recreate it properly during merge.sh
ls -l ../scripts/kb_act.lst.kvpatch.json&&:
echo -e "{\n${strKVPatches}\n}" >../scripts/kb_act.lst.kvpatch.json
ls -l ../scripts/kb_act.lst.kvpatch.json
if $bVerbose;then
	cat ../scripts/kb_act.lst.kvpatch.json
fi

echo '
now run: 
trash ../resource/closecaption_manifest.txt; #will be auto recreated from vanilla + kvpatch
trash ../scripts/kb_act.lst; #will be auto recreated from vanilla + kvpatch
cd ../../../..
./merge.sh -f resource/closecaption_manifest.txt;
./merge.sh -f scripts/kb_act.lst;
'

if $bDBG;then
	declare -p astrDbg |tr '[' '\n'
fi
