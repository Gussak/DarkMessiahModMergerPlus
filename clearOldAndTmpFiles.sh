#!/bin/bash

while [[ ! -f "./allMergerScriptsGenericConfig.sh" ]];do cd ..;done; source "./allMergerScriptsGenericConfig.sh"; FUNCminiModInit "$@"

(
	cd "${strGameInstallMainFolder}/${strGameSubRelatFolderWriteAllHere}"

	FUNCtrash \
		"demoheader.tmp.SnapShot_ID_"*".bkp" \
		"demoheader.tmp.SnapShot_ID_"*".bkp.Strings.txt" \
		"condump"*".txt" &&:

	#set -x
	#ls -1t "SAVE/mm-"*".sav" |while read strFl;do
		#: ${iCount:=0}
		#((iCount++))&&:
		#declare -p iCount
	#done
	mapfile -t aFl < <(ls -1t "SAVE/mm-"*".sav")
	nSz="${#aFl[@]}"
	if((nSz>10));then
		for((i=10;i<nSz;i++));do
			FUNCtrash "${aFl[$i]}"
		done
	fi
)
