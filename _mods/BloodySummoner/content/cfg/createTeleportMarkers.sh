#!/bin/bash

#	BSD 3-Clause License
#
#	Copyright (c) 2026, Gussak<https://github.com/Gussak>
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

: ${bXterm=true} #help
if $bXterm && ! pgrep -fa DMMM_teleportMarkersCreation;then
	(FUNCxterm -title DMMM_teleportMarkersCreation -e "$0" & disown);
	exit 0
fi

strFlCondumpPrev=""
while true;do
	strFlCondump="$(FUNCgetNewestCondump)"
	
	if [[ "$strFlCondumpPrev" != "$strFlCondump" ]];then
		bRecreateCfgFile=false
		strDeleteMarker=""
		
		if ugrep -q "gskTeleMarkerDelete|gsktd" "$strFlCondump";then #help delete current one selected (you can just type it on console too)
			strDeleteMarker="$(ugrep -q "+gskTeleMarkerSelectNext : gskTeleMarkerSelect[0-9]*" |awk '{print $3}')"
		fi
		if ugrep -q "gskTeleMarkerDrop" "$strFlCondump";then
			#while true;do ! FUNCmapInfo "$strFlCondump";do FUNCwaitSeconds 3 "condump needs map info status data";done
			FUNCmapInfo "$strFlCondump"
			
			strPos="$FUNCmapInfo_strPosRestore"
			strPosCmd="setpos ${strPos}"
			
			strCfgPath="${strGameInstallMainFolder}/${strGameSubRelatFolderWriteAllHere}/cfg"
			strMapCfgFile="${strCfgPath}/gskTeleMarkers_${FUNCmapInfo_strMapName}.cfg"
			strTeleCurrentCfgFile="${strCfgPath}/gskTeleMarkers.cfg"
			
			declare -p strPos strMapCfgFile FUNCmapInfo_strPosRestore strPosCmd
			
			echo "Now set this teleport marker name like: gskTeleMarkerName Some Nice Name, or gsktn Some Nice Name, or echo gsktn someNiceName, by typing it in the console. Then also type condump after the name prints" #help
			strRegextMatchTeleName="^(gskTeleMarkerName|Unknown command: gskTeleMarkerName|\] gskTeleMarkerName|gsktn|Unknown command: gsktn|\] gsktn) ([^;]*).*"
			while true;do
				#set -x
				strFlCondumpForName="$(FUNCgetNewestCondump)"
				if ugrep -i "$strRegextMatchTeleName" "$strFlCondumpForName";then
					strTeleName="$(ugrep -i "$strRegextMatchTeleName" "$strFlCondumpForName" |tail -n 1 |tr -d '\r' |sed -r -e "s@${strRegextMatchTeleName}@\2@g")"
					declare -p strTeleName
					bRecreateCfgFile=true;
					#set +x
					break;
				fi
				echo -ne "$(date) waiting Teleport marker name.\r"
				sleep 1
			done
		fi
		
		if $bRecreateCfgFile;then
			astrMarkerIndex=()
			astrMarkerID=()
			astrMarkerName=()
			astrMarkerPos=()
			declare -A astrMarkerID_Index=()
			declare -A astrMarkerID_Name=()
			declare -A astrMarkerID_Pos=()
			
			#retrieve existing markers
			if [[ -f "$strMapCfgFile" ]];then
				# ex.: // "GuestHouse" -4900  -10927  332
				strRegexMatchIDNamePos="^echo \"([0-9]*) ([^ ]*) '(.*)' (.*)\"$"
				mapfile -t astrMarkerIndex < <(cat "$strMapCfgFile" |ugrep "$strRegexMatchIDNamePos" |sed -r -e "s@${strRegexMatchIDNamePos}@\1@g") #this is dummy tho.
				mapfile -t astrMarkerID    < <(cat "$strMapCfgFile" |ugrep "$strRegexMatchIDNamePos" |sed -r -e "s@${strRegexMatchIDNamePos}@\2@g")
				mapfile -t astrMarkerName  < <(cat "$strMapCfgFile" |ugrep "$strRegexMatchIDNamePos" |sed -r -e "s@${strRegexMatchIDNamePos}@\3@g")
				mapfile -t astrMarkerPos   < <(cat "$strMapCfgFile" |ugrep "$strRegexMatchIDNamePos" |sed -r -e "s@${strRegexMatchIDNamePos}@\4@g")
				cp -v "$strMapCfgFile" "${strMapCfgFile}.$(FUNCdtFlNm).bkp" #TODO FUNCtrash "$strMapCfgFile" ?
			fi
			
			if [[ -n "$strDeleteMarker" ]];then
				for((i=0;i<${#astrMarkerID[@]};i++));do
					strMarkerID="${astrMarkerID[$i]}"
					if [[ "$strDeleteMarker" == "${strMarkerID}" ]];then
						unset astrMarkerID[$i]
						break
					fi
				done
				astrMarkerID=("${#astrMarkerID[@]}")
			else
				# astrMarkerIndex will be reindexed if needed.
				astrMarkerID+=("$(echo "${strTeleName}" |tr -d ' ')")
				astrMarkerName+=("${strTeleName}")
				astrMarkerPos+=("${strPos}")
				declare -p astrMarkerID astrMarkerName astrMarkerPos
			fi
			
			#make markers unique (last one wins)
			#iIndexCount=0
			for((i=0;i<${#astrMarkerID[@]};i++));do 
				#declare -p i iIndexCount
				strMarkerID="${astrMarkerID[$i]}"
				if [[ -z "$strMarkerID" ]];then continue;fi
				strMarkerName="${astrMarkerName[$i]}"
				strMarkerPos="${astrMarkerPos[$i]}"
				declare -p strMarkerID strMarkerName strMarkerPos
				
				astrMarkerID_Index[$strMarkerID]="$i" #$((iIndexCount++))"&&:
				astrMarkerID_Name[$strMarkerID]="$strMarkerName"
				astrMarkerID_Pos[$strMarkerID]="$strMarkerPos"
			done
			nIndexMax=$(( ${#astrMarkerID[@]} - 1))&&:
			declare -p astrMarkerID astrMarkerID_Name astrMarkerID_Pos astrMarkerID_Index
			#exit
			
			# prepare cfg file
			echo -n >"$strMapCfgFile" #trunc
			echo "alias gskTeleMarkerRecall gskTeleMarker000" >>"$strMapCfgFile"
			echo "alias +gskTeleMarkerSelectNext gskTeleMarkerSelect000" >>"$strMapCfgFile"
			echo "alias -gskTeleMarkerSelectNext \"developer 0\"" >>"$strMapCfgFile"
			echo >>"$strMapCfgFile"
			echo "echo \"Teleport Markers List for ${FUNCmapInfo_strMapName}:\"" >>"$strMapCfgFile"
			echo >>"$strMapCfgFile"
			for strMarkerID in "${!astrMarkerID_Name[@]}";do
				nIndex="${astrMarkerID_Index[$strMarkerID]}"
				strIndex="$(printf %03d $nIndex)"
				nIndexNext="$((nIndex+1))"&&:
				strIndexNext="$(printf %03d $nIndexNext)"
				echo "echo \"${strIndex} ${strMarkerID} '${astrMarkerID_Name[$strMarkerID]}' ${astrMarkerID_Pos[$strMarkerID]}\"" >>"$strMapCfgFile"
				
				#strAliasForID="gskTeleMarker_${strIndex}_${strMarkerID}"
				strAliasForID="gskTeleMarker${strIndex}"
				strAliasForIDNext="gskTeleMarker${strIndexNext}"
				#strAliasForID="gskTeleMarker_${strMarkerID}"
				#if((${#strAliasForID} > 30));then strAliasForID="${strAliasForID:0:30}";fi # if name is too big, trunc it, but the index will be the same always even if there is a trunc name clash
				strEcho="developer 1; echo Teleport to ${strIndex} ${strMarkerID} ${astrMarkerID_Name[$strMarkerID]} at ${astrMarkerID_Pos[$strMarkerID]}"
				#strEcho="echo Teleport to ${strIndex} ${strMarkerID} ${astrMarkerID_Name[$strMarkerID]} at ${astrMarkerID_Pos[$strMarkerID]}"
				#strEcho="echo Teleporting To ${strMarkerID} '${astrMarkerID_Name[$strMarkerID]}' at ${astrMarkerID_Pos[$strMarkerID]}"
				echo "alias ${strAliasForID} \"setpos ${astrMarkerID_Pos[$strMarkerID]}; $strEcho\"" >>"$strMapCfgFile"
				
				if((nIndex != nIndexMax));then
					echo "alias gskTeleMarkerSelect${strIndex} \"alias gskTeleMarkerRecall ${strAliasForID}; alias +gskTeleMarkerSelectNext gskTeleMarkerSelect${strIndexNext}; ${strEcho}\"" >>"$strMapCfgFile"
				else
					echo "alias gskTeleMarkerSelect${strIndex} \"alias gskTeleMarkerRecall ${strAliasForID}; alias +gskTeleMarkerSelectNext gskTeleMarkerSelect000; ${strEcho}\" //LOOP" >>"$strMapCfgFile"
				fi
				#echo "alias -gskTeleMarkerSelect${strIndex} \"developer 0\"" >>"$strMapCfgFile"
				
				echo >>"$strMapCfgFile"
			done
			#echo >>"$strMapCfgFile"
			#echo "alias gskTeleMarkerSelect$( printf %03d $((nIndexNext+1)) ) \"alias gskTeleMarkerRecall gskTeleMarker000; alias +gskTeleMarkerSelectNext gskTeleMarkerSelect000\"" >>"$strMapCfgFile"
			#if [[ ! -f "${strMapCfgFile}.condump.txt" ]];then
				#cp -v "$lstrFlCondump" "${strMapCfgFile}.condump.txt"
			#fi
			
			ln -vsf "$strMapCfgFile" "$strTeleCurrentCfgFile"
			cat "${strTeleCurrentCfgFile}"
		fi
		
		strFlCondumpPrev="$strFlCondump"
	else
		echo -ne "$(date) Waiting new condump.\r"
	fi

	#TODO this can also update a file gskFillCurrentMapWithNPCs.cfg based on the current map name and on available files at CarefulCombat! so at 'q' key to reload some cfgs, it will also load gskFillCurrentMapWithNPCs.cfg that is ready with the spawn NPC settings for current map!
	sleep 1
done

exit


Press key to mark
   alias gskTeleDrop "clear; status; status; status; echo gskTeleMarkerDrop; condump"

Open console type: gsktelenm some Nice name



prepareTeleRecall.sh

Use keu "u" to "status;status;status;codump", this will ask a map tele list update: copy existing ex gskTeleMarkers_L00.cfg to gskTeleMarkers_Current.cfg

alias gskTeleRecallSelect "exec gskTeleMarkers_Current.cfg; ..."#show index , nome completo , coordenadas, sem limite

alias +gskTeleRecallApply "exec gskTeleRecall.cfg"
alias -gskTeleRecallApply "setpos ...; hurtme 20; mm_player_unfreeze; gskWait5s;   mm_player_unfreeze"

alias gskTeleDeleteCurrent (gerado pelo tele select tb) ou gakteledel (digita no console)


Press key to recall


Total 
duas keybinds extras: mark recall, uma comum dev de condump
Dois comandos: gsktelenm gskteledel








dicas de outro script:

function FUNCalias() {
	# alias name limit is 30 chars
	strShortName="${strNPC#mm_npc_create_}"
	echo "alias gskCCnpcSwitch_${i} \"developer 1; echo CFG_CREATE:${strShortName}; alias gskCCnpcSpawn gskCCnpcSpawn_${i}; alias +gskCCnpcSwitch gskCCnpcSwitch_${iNext}\""
	echo "alias gskCCnpcSpawn_${i} \"echo gskSpawnHint; getpos; getpos; echo ${strNPC}; echo ${strNPC}; ${strNPC}\"" #this way, it creates a reusable log to quickly place all NPCs again!!! OBS.: getpos 2 times is because the engine bugs and may not print one character some times
}

: ${strExecEdit:=geany} #help
: ${bAutoFixMissingChars:=true} #help :O

function FUNCvalidateNPC() {
	local lstrChkNpc="$1";shift
	local lstrFlCondump="$1";shift
	local lLn="$1";shift
	
	local lbFound=false
	local i
	for((i=0;i<${#astrNPC[@]};i++));do
		local lstrNPC="${astrNPC[$i]}"
		#declare -p lstrNPC lstrChkNpc
		if [[ "$lstrNPC" == "$lstrChkNpc" ]];then lbFound=true;break;fi
	done
	if ! $lbFound;then
		FUNCechoInfo "[ERROR:invalidNPC] $lstrChkNpc ( the engine sometimes do not print some letters!!! :O )"
		"$strExecEdit" "$lstrFlCondump:$((lLn+1))"  #editors begin in line 1 not 0
		FUNCexit 1
	fi
}

function FUNCechoAndFillFile() {
	echo "$1" |tee -a "$strMapCfgFile"
}

if [[ "${1-}" == "-m" ]];then #help read last condump and prepare a cfg file to help fill a map with placed NPCs
	
	#mapfile -t astrSpawnHintList < <(egrep "gskSpawnHint" "$strFlCondump" -A 2 |egrep -v "\--" |tr -d '\r')
	mapfile -t astrAllLines < <(cat "$strFlCondump" |tr -d '\r')
	#for strSpawnHint in "${astrSpawnHintList[@]}";do
	iCount=0
	#iDataLines=4
	echo
#	echo "// FILL MAP WITH NPCs, total $((${#astrSpawnHintList[@]}/iDataLines))"
	nTot="$(cat "$strFlCondump" |grep "^gskSpawnHint" -c)"
	if((nTot==0));then
		FUNCechoInfo "[ERROR:spawnSomeFoes] use F7 F8 keys"
		FUNCexit 1
	fi
	FUNCechoAndFillFile "// AUTO GENERATED WITH $(basename "$0")"
	FUNCechoAndFillFile "// FILL MAP WITH NPCs, total $nTot"
	FUNCechoAndFillFile "alias gskCCnpcSpawn_helper \"developer 1; gskEffect100; host_timescale 0.01; noclip; ai_disable\""
	FUNCechoAndFillFile "alias gskCCnpcSpawn_next gskCCnpcSpawn_000"
	#for((i=0;i<${#astrSpawnHintList[@]};i+=iDataLines));do
	for((i=0;i<${#astrAllLines[@]};i++));do
		strLine="${astrAllLines[$i]}"
		if [[ "$strLine" =~ ^gskSpawnHint.* ]];then
			iLnData=$i;#declare -p iLnData
			((iLnData++))&&:;strPos="${astrAllLines[$iLnData]}"
			((iLnData++))&&:;strPosChk="${astrAllLines[$iLnData]}" #as engine may not print one char! :O
			if [[ "$strPos" != "$strPosChk" ]];then
				if $bAutoFixMissingChars;then
					if((${#strPosChk} > ${#strPos}));then
						strPos="$strPosChk"
					fi
				else
					declare -p strPos strPosChk
					FUNCechoInfo "[ERROR:invalidPOS] ( the engine sometimes do not print some letters!!! :O )"
					"$strExecEdit" "$strFlCondump:$((iLnData+1))" #editors begin in line 1 not 0
					FUNCexit 1
				fi
			fi
			
			((iLnData++))&&:;strNPC="$(    echo "${astrAllLines[$iLnData]}" |awk '{print $1}')"
			((iLnData++))&&:;strNPCchk="$( echo "${astrAllLines[$iLnData]}" |awk '{print $1}')"
			#declare -p strPos strNPC
			if [[ "$strNPC" != "$strNPCchk" ]];then
				if $bAutoFixMissingChars;then
					if((${#strNPCchk} > ${#strNPC}));then
						strNPC="$strNPCchk"
					fi
				fi
			fi
			FUNCvalidateNPC "$strNPC" "$strFlCondump" "$iLnData"
			
			strCount="$(      printf %03d $((iCount  )) )"
			strCountPlus1="$( printf %03d $((iCount+1)) )"
			
			FUNCechoAndFillFile "alias gskCCnpcSpawn_${strCount} \"${strPos}; ${strNPC}; echo ${iCount}/${nTot}; gskCCnpcSpawn_helper; alias gskCCnpcSpawn_next gskCCnpcSpawn_${strCountPlus1}\""
			((iCount++))&&:
			
			i=$iLnData
		fi
	done
	FUNCechoAndFillFile "alias gskCCnpcSpawn_${strCountPlus1} \"echo FinishedSpawnings; gskEffectOFF; gskSndDONE; ${strRestorePosInTheEnd}; host_timescale 1.0; noclip; ai_disable; developer 0; \"" #this also prevents continuing thru some previous list entries of a previous test run or map may be
	
	if egrep "remove" -i "${strMapCfgFile}.condump.txt";then
		FUNCechoInfo "[WARN] removes detected, better edit to remove from that line up to 'gskSpawnHint' and rerun!" #TODO this can be scripted easily if the echo on the console is like: RemoveAbove=1 or Remove=1 or RM1; echo RM1; echo rm2
		echo "${strExecEdit} '${strMapCfgFile}.condump.txt'"
		echo "strFlCondump='${strMapCfgFile}.condump.txt' $0 -m"
	fi
else # create spawner aliases
	echo
	echo "// Total ${#astrNPC[@]} NPCs"
	for((i=0;i<${#astrNPC[@]};i++));do
		strNPC="${astrNPC[$i]}"
		iNext=$((i+1))&&:
		if(( i == (${#astrNPC[@]}-1) ));then
			iNext=0
		fi
		FUNCalias
	done
fi
