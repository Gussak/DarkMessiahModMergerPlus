#!/bin/bash

# SPDX-License-Identifier: Apache-2.0

while [[ ! -f "./allMergerScriptsGenericConfig.sh" ]];do cd ..;done; source "./allMergerScriptsGenericConfig.sh"; FUNCminiModInit "$@"

strMatch="$1" #help if [--all] will extract all files
bAll=false;if [[ "$strMatch" == --all ]];then bAll=true;fi

bChkVpkExec=true

#strExec="$HOME/.local/bin/vpk"
#if [[ ! -f "$strExec" ]];then
	#set -x
	#sudo apt install python3-pip
	#pip install vpk
	#set +x
#fi

#cd "${strPathParent}"/*Vanilla*/vpks/ ########################################
cd "${strVanillaLayer}/vpks/" ########################################
IFS=$'\n' read -d '' -r -a astrFlVpk < <(ls *_dir.vpk)&&:
declare -p astrFlVpk |sed -r -e 's@\[@\n\[@g' >&2

: ${strExtFolder:="${strPathSelf}/Extracted.Quick.TMP"} #help
mkdir -vp "$strExtFolder"

if $bAll;then
	for strFlVpk in "${astrFlVpk[@]}";do
		"$strVpkExec" -x "$strExtFolder" "$strFlVpk"
	done
else
	IFS=$'\n' read -d '' -r -a astrFlEx < <(
		for strFlVpk in "${astrFlVpk[@]}";do
			"$strVpkExec" "$strFlVpk" -l;
		done |egrep "$strMatch" -i |sort -u
	)&&:
	#declare -p astrFlEx |sed -r -e 's@\[@\n\[@g' >&2
	for strFlEx in "${astrFlEx[@]}";do echo "$strFlEx";done

	: ${bDoExtract:=true} #help
	if $bDoExtract;then
		for strFlEx in "${astrFlEx[@]}";do
			for strFlVpk in "${astrFlVpk[@]}";do
				"$strVpkExec" -x "$strExtFolder" --filter "$strFlEx" "$strFlVpk"
			done
		done
	fi
fi
