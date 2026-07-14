#!/bin/bash

pwd
strSelf="$(basename $0)"
if [[ ! -f "./${strSelf}" ]];then
	cd "$(dirname "${strSelf}")"
fi
pwd
strMainModFolder="$(pwd)"

while [[ ! -f "./allMergerScriptsGenericConfig.sh" ]];do cd ..;done; source "./allMergerScriptsGenericConfig.sh"; FUNCminiModInit "$@"

#set -x

if which ScriptEchoColor;then
	cd ..;pwd
	if [[ -f "Dark Messiah Might and Magic Single Player/mm.exe" ]];then
		echo "Already mounted..."
	else
		bSudoWithScript=true strUnionFSID=overlayfs secOverrideMultiLayerMountPoint.sh "Dark Messiah Might and Magic Single Player" #help depends on ScriptEchoColor
	fi
fi

: ${bFixW=true} #help runs fixWindowAndDontStop.sh
if $bFixW;then
	cd "${strMainModFolder}/"
	./fixWindowAndDontStop.sh #waits game start
fi

cd "${strMainModFolder}/"
bPauseOnlyNoFocusInstance=true ./autoPauseAfterSaveGameIsLoaded.sh -m #endless loop

cd "${strMainModFolder}/"
(xterm -e ./createFunctionalBkp.sh & disown) #run once, create configs small backup

#cd "${strMainModFolder}/"
#./gitgui.sh #run once

cd "${strMainModFolder}/"
./quickBkp.sh #endless loop to backup quick.sav

##################

if which ScriptEchoColor;then
	echo "you may try to just drop_caches or remount, secOverrideMultiLayerMountPoint.sh helps on it too"
	read -n 1 -p "Umount?(y/...)" strResp;
	if [[ "${strResp}" == y ]];then
		cd "${strMainModFolder}/../"
		bSudoWithScript=true strUnionFSID=overlayfs secOverrideMultiLayerMountPoint.sh -u "Dark Messiah Might and Magic Single Player" #help depends on ScriptEchoColor
	fi
fi
