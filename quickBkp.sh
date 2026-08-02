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
