#!/bin/bash

# SPDX-License-Identifier: Apache-2.0

bChkVpkExec=true # for allMergerScriptsGenericConfig.sh
while [[ ! -f "./allMergerScriptsGenericConfig.sh" ]];do cd ..;done; source "./allMergerScriptsGenericConfig.sh"; FUNCminiModInit "$@"

#strExec="$HOME/.local/bin/vpk"
#if [[ ! -f "$strExec" ]];then
	#set -x
	#sudo apt install python3-pip
	#pip install vpk
	#set +x
#fi


#: ${strExtFolder:="${strPathParent}/Dark Messiah Might and Magic Single Player.layer004.VanillaExtractedTextFiles.IGNORE_LAYER"} #help
: ${strExtFolder:="${strVanillaScriptsPath}"} #help

mkdir -vp "$strExtFolder/mm"
if ! cp -vf "${strVanillaLayer}/mm/gameinfo.txt" "$strExtFolder/mm/";then
	FUNCechoInfo "[it is important to copy 'gameinfo.txt' from vanilla folder too as it may be patched and is not present in vpk files]" 
	FUNCexit 1
fi

mkdir -vp "$strExtFolder"
ls "${strVanillaLayer}/vpks/depot_"*"_dir.vpk" |while read strFlDir;do
	"$strVpkExec" -re "$strScriptsExtRegexNorm" -x "$strExtFolder" "$strFlDir"
done

