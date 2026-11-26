#!/bin/bash

# SPDX-License-Identifier: Apache-2.0

while [[ ! -f "./allMergerScriptsGenericConfig.sh" ]];do cd ..;done; source "./allMergerScriptsGenericConfig.sh"; FUNCminiModInit "$@"

echo "Easy backup"
echo "This is meant to be run at (final merged OverlayFS) game folder"

function FUNCbkp() {
	while ! cd "$HOME/Wine/DarkMessiahOfMightAndMagic.win32/drive_c/Games/Dark Messiah Might and Magic Single Player";do
		echo "[waiting game start]"
		sleep 3
	done
	
	: ${strCopyToFolder:=""} #help set this to copy it into some backup device
	
	astr=("./AddOn/SAVE/" "./mm/SAVE" "./custom/SAVE" "./WriteNewDataHereOnly/SAVE") #help add folders here if you use any different
	strThisPath="$(pwd)"
	while true;do
		for str in "${astr[@]}";do
			echo
			echo ">>>>>>>>>>>>>>>>>>> [$str] >>>>>>>>>>>>>>>>>>>"
			
			strPrefix="$(echo "$str" |tr './' '__')_"
			strFlBkp="$strCopyToFolder/${strPrefix}quick.sav.7z"
			
			cd "$strThisPath"
			cd "$str"
			#pwd
			
			strBkpKeyOld="$(cat quick.sav.bkpKey.cfg)"&&:
			strBkpKeyNew="$(ls -l quick.sav)"
			if [[ -f "quick.sav" ]] && [[ "${strBkpKeyNew}" != "${strBkpKeyOld}" ]];then
				trash "quick.sav.7z"&&:
				
				7z a "quick.sav.7z" "quick.sav" "quick.tga"
				touch -r "quick.sav" "quick.sav.7z"
				touch -r "quick.tga" "quick.sav.7z"
				
				strDupItDtTm="$(FUNCdtFlNm)" #the game stops auto duplicating after some time of playing...
				cp "quick.sav" "mm-${strDupItDtTm}.sav"
				cp "quick.tga" "mm-${strDupItDtTm}.tga"
				
				ls -l "quick.sav.7z" "mm-${strDupItDtTm}.sav" "mm-${strDupItDtTm}.tga"
				
				ls -l "quick.sav" >"quick.sav.bkpKey.cfg"
				if [[ -n "$strCopyToFolder" ]];then
					mkdir -vp "$strCopyToFolder"
					cp -vf "quick.sav.7z" "$strFlBkp"
					#touch -r quick.sav "$strCopyToFolder/${strPrefix}quick.sav.7z"
				fi
			fi
		done
		
		read -t 5 -p "[$(FUNCdtFlNm)][press a key to backup all again]"
	done
};export -f FUNCbkp

if ! pgrep -fa DMMM_quickBkpLoop;then
	(FUNCxterm -title DMMM_quickBkpLoop -e bash -c "FUNCbkp" & disown);
fi
