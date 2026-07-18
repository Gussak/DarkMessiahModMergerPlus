#!/bin/bash

if [[ "${1-}" == "--help" ]];then #help ok
	: #egrep "[#]help" "$0"
fi

pwd
strSelfBN="$(basename "$0")"
declare -p strSelfBN
if [[ ! -f "./${strSelfBN}" ]];then
	cd "$(dirname "$0")"
fi
pwd
strMainModFolder="$(pwd)"

while [[ ! -f "./allMergerScriptsGenericConfig.sh" ]];do cd ..;done; source "./allMergerScriptsGenericConfig.sh"; FUNCminiModInit "$@"

: ${bXtermAlready:=false} # self internal use only
if ! $bXtermAlready;then
	: ${bXterm:=true} #help
	if $bXterm;then
		if pgrep -fa GSK_DMMM_Helpers;then exit 0;fi
		(xterm -title GSK_DMMM_Helpers -e bash -c "while true;do read -p PressEnterToRunHelpers&&:; bXtermAlready=true ./${strSelfBN};done" & disown)
		exit 0
	fi
fi

#set -x

if which ScriptEchoColor;then
	cd ..;pwd
	if [[ -f "Dark Messiah Might and Magic Single Player/mm.exe" ]];then
		echo "Merged game folder already mounted..."
	else
		bSudoWithScript=true strUnionFSID=overlayfs secOverrideMultiLayerMountPoint.sh "Dark Messiah Might and Magic Single Player" #help @InfoID="secOverrideMultiLayerMountPoint.sh:MOUNT" Helper Script, depends on ScriptEchoColor
	fi
fi

: ${bFixW:=true} #help runs fixWindowAndDontStop.sh
if $bFixW;then
	cd "${strMainModFolder}/"
	./fixWindowAndDontStop.sh #help @InfoID="fixWindowAndDontStop.sh" Helper Script, waits game start
fi

cd "${strMainModFolder}/"
bPauseOnlyNoFocusInstance=true ./autoPauseAfterSaveGameIsLoaded.sh -m #help @InfoID="autoPauseAfterSaveGameIsLoaded.sh" Helper Script, endless loop

cd "${strMainModFolder}/"
(xterm -e ./createFunctionalBkp.sh & disown) #help @InfoID="createFunctionalBkp.sh" Helper Script, run once, create configs small backup

#cd "${strMainModFolder}/"
#./gitgui.sh #run once

cd "${strMainModFolder}/"
./quickBkp.sh #help @InfoID="quickBkp.sh" Helper Script, endless loop to backup quick.sav

##################

if which ScriptEchoColor;then
	echo "you may try to just drop_caches or remount, secOverrideMultiLayerMountPoint.sh helps on it too"
	read -n 1 -p "Umount?(y/...)" strResp;
	if [[ "${strResp}" == y ]];then
		cd "${strMainModFolder}/../"
		bSudoWithScript=true strUnionFSID=overlayfs secOverrideMultiLayerMountPoint.sh -u "Dark Messiah Might and Magic Single Player" #help @InfoID="secOverrideMultiLayerMountPoint.sh:UMOUNT" Helper Script, depends on ScriptEchoColor
	fi
fi
