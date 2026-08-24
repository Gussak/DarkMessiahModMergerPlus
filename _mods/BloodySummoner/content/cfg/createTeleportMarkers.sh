#!/bin/bash

# The Clear BSD License
#
# Copyright (c) 2026, Gussak<https://github.com/Gussak>
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted (subject to the limitations in the disclaimer
# below) provided that the following conditions are met:
#
#      * Redistributions of source code must retain the above copyright notice,
#      this list of conditions and the following disclaimer.
#
#      * Redistributions in binary form must reproduce the above copyright
#      notice, this list of conditions and the following disclaimer in the
#      documentation and/or other materials provided with the distribution.
#
#      * Neither the name of the copyright holder nor the names of its
#      contributors may be used to endorse or promote products derived from this
#      software without specific prior written permission.
#
# NO EXPRESS OR IMPLIED LICENSES TO ANY PARTY'S PATENT RIGHTS ARE GRANTED BY
# THIS LICENSE. THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND
# CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
# PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
# BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER
# IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

while [[ ! -f "./allMergerScriptsGenericConfig.sh" ]];do cd ..;done; source "./allMergerScriptsGenericConfig.sh"; FUNCminiModInit "$@"

#set -x
#: ${bXterm=true} #help
#if $bXterm;then
	#if pgrep -fa DMMM_teleportMarkersCreation;then exit 0;fi
	##(FUNCxterm -title DMMM_teleportMarkersCreation -e "$0" & disown);
	#FUNCxterm -title DMMM_teleportMarkersCreation -e "$0"
	#exit 0
#fi
strSelfXtermInstanceID=DMMM_teleportMarkersCreation
: ${bXterm:=true} #help
if $bXterm && bXterm=false FUNCxtermChild $strSelfXtermInstanceID -maximized -e "$0" "$@";then echo ChildReady; exit 0; fi
#set +x

function FUNCgskCmd() { # <lstrFlCondump> <lstrCmdFull> <lstrCmdShort> <lnGetParamIndex>
	local lstrFlCondump="$1";shift
	local lstrCmdFull="$1";shift
	local lstrCmdShort="$1";shift
	local lnGetParamIndex="$1";shift
	
	((lnGetParamIndex++))&&: # because the first () is just for the ors '|'
	local lstrRegexMatch="^(${lstrCmdFull}|Unknown command: ${lstrCmdFull}|\] ${lstrCmdFull}|${lstrCmdShort}|Unknown command: ${lstrCmdShort}|\] ${lstrCmdShort}) ([^; ]*)[; ]*(.*)"
	
	ugrep -i "$lstrRegexMatch" "$lstrFlCondump" |tail -n 1 |tr -d '\r' |sed -r -e "s@${lstrRegexMatch}@\${lnGetParamIndex}@g" #|awk '{print $1}'
}
strFlCondumpPrev=""
strCfgPath="${strGameInstallMainFolder}/${strGameSubRelatFolderWriteAllHere}/cfg"
strTeleCurrentCfgFile="${strCfgPath}/gskTeleMarkers.cfg"
strMatchRename=".*(gskTeleMarkerRename|gsktrn)[ ]*([^ ]*)[ ]*(.*)"
: ${nLoopSleep:=0.33} #help
while true;do
	sleep $nLoopSleep
	
	if ! strFlCondump="$(FUNCgetNewestCondump)";then
		echo -ne "$(date) Waiting first condump.\r"
		continue
	fi
	
	if [[ "$strFlCondumpPrev" == "$strFlCondump" ]];then
		echo -ne "$(date) Waiting new condump.\r"
		continue
	fi
	
	echo
	echo "============================================"
	FUNCechoInfo "WORKING WITH: $(basename "${strFlCondump}")"
	
	bRecreateCfgFile=false
	strDeleteMarker=""
	strTeleName=""
	strTeleReNameFromID="";strTeleReNameToPrettyName=""
	strTeleportUpAlias="" #bTeleportUp=false; strTeleportUpAlias=""
	strTeleportTargetAlias=""
	#bTeleMarkerDrop=false
	
	if ugrep -q "gskTeleMarkerDelete=CurrentOneSelected|gsktdc" "$strFlCondump";then #help delete current one selected (you can just type it on console too)
		FUNCmapInfo "$strFlCondump"
		strMapCfgFile="${strCfgPath}/gskTeleMarkers_${FUNCmapInfo_strMapName}.cfg"
		
		#strDeleteMarker="$(ugrep "^[+]gskTeleMarkerSelectNext : gskTeleMarkerSelect[0-9]*" "$strFlCondump" |tail -n 1 |awk '{print $3}')"
		strDeleteMarker="$(ugrep "^gskTeleMarkerRecall : gskTeleMarker[0-9]*" "$strFlCondump" |tail -n 1 |awk '{print $3}')"
		
		bRecreateCfgFile=true;
	elif ugrep -q "gskTeleportUpPrepareHint" "$strFlCondump";then #help
		FUNCmapInfo "$strFlCondump"
		strMapCfgFile="${strCfgPath}/gskTeleMarkers_${FUNCmapInfo_strMapName}.cfg"
		
		declare -p FUNCmapInfo_anPosRestoreXYZ
		((FUNCmapInfo_anPosRestoreXYZ[z]+=600))&&:
		strTeleportUpAlias="alias gskTeleportUpApply \"setpos ${FUNCmapInfo_anPosRestoreXYZ[x]} ${FUNCmapInfo_anPosRestoreXYZ[y]} ${FUNCmapInfo_anPosRestoreXYZ[z]} \""
		declare -p strTeleportUpAlias
		
		bRecreateCfgFile=true;
	elif ugrep -q "gskTeleportTargetLocationPrepareHint" "$strFlCondump";then #help
		#TODO Test_CreateEntity prop_physics gskTeleportTargetLocationPrepareHint //this will dump the target position, just inc z by 100 ex.: prop at -3421 -11201 -100 missing modelname
		#declare -gA anTargetPosXYZ="$(FUNCxyzArray "$(echo "$strTargetPos" |sed -r -e 's@.*prop at (.*) missing modelname.*@\1@g')")"
		FUNCmapInfo "$strFlCondump"
		strMapCfgFile="${strCfgPath}/gskTeleMarkers_${FUNCmapInfo_strMapName}.cfg"
		
		FUNCposTarget "$strFlCondump"
		declare -p FUNCposTarget_anPosXYZ
		((FUNCposTarget_anPosXYZ[z]+=60))&&:
		strTeleportTargetAlias="alias gskTeleportTargetPosApply \"setpos ${FUNCposTarget_anPosXYZ[x]} ${FUNCposTarget_anPosXYZ[y]} ${FUNCposTarget_anPosXYZ[z]} \""
		declare -p strTeleportTargetAlias
		
		bRecreateCfgFile=true;
	elif ugrep -q "${strMatchRename}" "$strFlCondump";then #help @InfoID="gskTeleMarkerRename" use like this in console ex.:    clear; status; status; echo gsktrn POS_x-234_y587_z2354 Some Nice Pretty Name; condump; gskWait5s; exec gskTeleMarkers  //it will auto wait and reload the config file (just copy the ID from console, 'from' must be the Teleporter ID that have no spaces) //TODO let it be just the current one selected to be renamed
		FUNCmapInfo "$strFlCondump"
		strMapCfgFile="${strCfgPath}/gskTeleMarkers_${FUNCmapInfo_strMapName}.cfg"
		
		strTeleReNameFromID="$(      ugrep "gskTeleMarkerRename|gsktrn" "$strFlCondump" |tail -n 1 |sed -r -e "s@${strMatchRename}@\2@g")"
		strTeleReNameToPrettyName="$(ugrep "gskTeleMarkerRename|gsktrn" "$strFlCondump" |tail -n 1 |sed -r -e "s@${strMatchRename}@\3@g")"
		declare -p strTeleReNameFromID strTeleReNameToPrettyName
		#exit
		
		bRecreateCfgFile=true;
	elif ugrep -q "gskTeleMarkerDrop" "$strFlCondump";then
		#while true;do ! FUNCmapInfo "$strFlCondump";do FUNCwaitSeconds 3 "condump needs map info status data";done
		FUNCmapInfo "$strFlCondump"
		strMapCfgFile="${strCfgPath}/gskTeleMarkers_${FUNCmapInfo_strMapName}.cfg"
		
		strPos="$FUNCmapInfo_strPosRestore"
		strPosCmd="setpos ${strPos}"
		
		declare -p strPos strMapCfgFile FUNCmapInfo_strPosRestore strPosCmd
		
		echo "Now set this teleport marker name like: gskTeleMarkerName Some Nice Name, or gsktn Some Nice Name, or echo gsktn someNiceName, by typing it in the console. Then also type condump after the name prints" #help
		strRegextMatchTeleName="^(gskTeleMarkerName|Unknown command: gskTeleMarkerName|\] gskTeleMarkerName|gsktn|Unknown command: gsktn|\] gsktn) ([^;]*).*"
		function FUNCteleName() {
			local lstrFl="$1";shift
			#set -x
			ugrep -i "$strRegextMatchTeleName" "$lstrFl" |tail -n 1 |tr -d '\r' |sed -r -e "s@${strRegextMatchTeleName}@\2@g" #|awk '{print $1}'
			#set +x
		}
		#FUNCteleName "${strFlCondump}"&&:;exit
		if [[ "$(FUNCteleName "${strFlCondump}" |tr -d ' ')" == "_AUTOMATIC_" ]];then
			strTeleName="_AUTOMATIC_"
			declare -p strTeleName
			bRecreateCfgFile=true;
		else
			while true;do
				#set -x
				strFlCondumpForName="$(FUNCgetNewestCondump)"
				#if ugrep -i "$strRegextMatchTeleName" "$strFlCondumpForName";then
				if strTeleName="$(FUNCteleName "${strFlCondumpForName}")";then
					#strTeleName="$(ugrep -i "$strRegextMatchTeleName" "$strFlCondumpForName" |tail -n 1 |tr -d '\r' |sed -r -e "s@${strRegextMatchTeleName}@\2@g")"
					declare -p strTeleName
					bRecreateCfgFile=true;
					#set +x
					break;
				fi
				echo -ne "$(date) waiting Teleport marker name.\r"
				sleep 1
			done
		fi
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
			mapfile -t astrMarkerIndex < <(cat "$strMapCfgFile" |ugrep "$strRegexMatchIDNamePos" |sed -r -e "s@${strRegexMatchIDNamePos}@\1@g")
			mapfile -t astrMarkerID    < <(cat "$strMapCfgFile" |ugrep "$strRegexMatchIDNamePos" |sed -r -e "s@${strRegexMatchIDNamePos}@\2@g")
			mapfile -t astrMarkerName  < <(cat "$strMapCfgFile" |ugrep "$strRegexMatchIDNamePos" |sed -r -e "s@${strRegexMatchIDNamePos}@\3@g")
			mapfile -t astrMarkerPos   < <(cat "$strMapCfgFile" |ugrep "$strRegexMatchIDNamePos" |sed -r -e "s@${strRegexMatchIDNamePos}@\4@g")
			cp -v "$strMapCfgFile" "${strMapCfgFile}.$(FUNCdtFlNm).bkp" #TODO FUNCtrash "$strMapCfgFile" ?
		fi
		
		if [[ -n "$strDeleteMarker" ]];then
			#strDeleteMarkerIndex="$(echo "$strDeleteMarker" |sed -r -e 's@gskTeleMarkerSelect([0-9]*)@\1@g')"
			strDeleteMarkerIndex="$(echo "$strDeleteMarker" |sed -r -e 's@gskTeleMarker([0-9]*)@\1@g')"
			declare -p astrMarkerID strDeleteMarker strDeleteMarkerIndex
			#iDeleteMarkerIndex="$( echo $(( 10#${strDeleteMarkerIndex} - 1 )) )"
			#strDeleteMarkerIndexFixed="$(printf %03d $iDeleteMarkerIndex)"
			for((i=0;i<${#astrMarkerID[@]};i++));do
				strMarkerID="${astrMarkerID[$i]}"
				strMarkerIndex="${astrMarkerIndex[$i]}"
				#if [[ "$strDeleteMarker" == "${strMarkerID}" ]];then
				#if [[ "${strDeleteMarkerIndexFixed}" == "${strMarkerIndex}" ]];then
				if [[ "${strDeleteMarkerIndex}" == "${strMarkerIndex}" ]];then
					unset astrMarkerID[$i]
					break
				fi
			done
			astrMarkerID=("${astrMarkerID[@]}")
			declare -p astrMarkerID
		elif [[ -n "$strTeleReNameFromID" ]] && [[ -n "$strTeleReNameToPrettyName" ]];then
			declare -p strTeleReNameFromID strTeleReNameToPrettyName
			for((i=0;i<${#astrMarkerID[@]};i++));do
				strMarkerID="${astrMarkerID[$i]}"
				if [[ "${strTeleReNameFromID}" == "${strMarkerID}" ]];then
					astrMarkerID[$i]="$(echo "${strTeleReNameToPrettyName}" |tr -d ' ')"
					astrMarkerName[$i]="${strTeleReNameToPrettyName}"
					break
				fi
			done
		elif [[ -n "$strTeleName" ]];then
			declare -p strTeleName
			# astrMarkerIndex will be reindexed if needed.
			if [[ "$strTeleName" == "_AUTOMATIC_" ]];then
				strTeleName="$(echo "${strPos}" |sed -r -e "s@\s*([0-9-]*)\s*([0-9-]*)\s*([0-9-]*)\s*@POS_x\1_y\2_z\3@g")"
			fi
			astrMarkerID+=("$(echo "${strTeleName}" |tr -d ' ')")
			astrMarkerName+=("${strTeleName}")
			astrMarkerPos+=("${strPos}")
			declare -p astrMarkerID astrMarkerName astrMarkerPos
		#elif $bTeleportUp;then
			#strTeleportUpAlias="alias gskTeleportUpApply "
		fi
		
		#make markers unique (last one wins)
		for((i=0;i<${#astrMarkerID[@]};i++));do 
			strMarkerID="${astrMarkerID[$i]}"
			if [[ -z "$strMarkerID" ]];then continue;fi
			strMarkerName="${astrMarkerName[$i]}"
			strMarkerPos="${astrMarkerPos[$i]}"
			declare -p strMarkerID strMarkerName strMarkerPos
			
			astrMarkerID_Index[$strMarkerID]="${astrMarkerID_Index[$strMarkerID]-$i}" #this means: if that strMarkerID already exists, the next one found will replace it LEAST it's new RE-INDEX!
			astrMarkerID_Name[$strMarkerID]="$strMarkerName"
			astrMarkerID_Pos[$strMarkerID]="$strMarkerPos"
		done
		#nIndexMax=0
		#astrMarkerID_IndexChk=("${astrMarkerID_Index[@]}")
		##declare -p astrMarkerID_Index
		#for((i=0;i<${#astrMarkerID_IndexChk[@]};i++));do
			##declare -p nIndexMax i
			#if((i != ${astrMarkerID_IndexChk[$i]}));then
				#FUNCechoInfo "[DEV_ERROR] inconsistent indexing."
				#declare -p astrMarkerID_Index astrMarkerID_IndexChk
				#FUNCexit 1
			#fi
			#if((nIndexMax<i));then
				#nIndexMax="$i"
			#fi
		#done
		##nIndexMax=$(( ${#astrMarkerID[@]} - 1))&&:
		declare -p astrMarkerID astrMarkerID_Name astrMarkerID_Pos astrMarkerID_Index #nIndexMax
		
		# prepare cfg file
		echo -n >"$strMapCfgFile" #trunc
		echo "alias gskTeleMarkerRecall gskTeleMarker000" >>"$strMapCfgFile"
		echo "alias +gskTeleMarkerSelectNext gskTeleMarkerSelect000" >>"$strMapCfgFile"
		echo "alias -gskTeleMarkerSelectNext \"developer 0\"" >>"$strMapCfgFile"
		echo "alias gskTeleMarkerSelect000 \"exec gskTeleMarkers; echo List is Empty\" //this will be overriden if there is anything tho" >>"$strMapCfgFile"
		echo >>"$strMapCfgFile"
		echo "echo \"Teleport Markers List for ${FUNCmapInfo_strMapName}:\"" >>"$strMapCfgFile"
		echo >>"$strMapCfgFile"
		nIndexCount=0
		for strMarkerID in "${!astrMarkerID_Name[@]}";do
			nIndex=$((nIndexCount++))&&: #"${astrMarkerID_Index[$strMarkerID]}"
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
			echo "alias ${strAliasForID} \"setpos ${astrMarkerID_Pos[$strMarkerID]}; gskTeleMarkerRecallEffects; $strEcho\"" >>"$strMapCfgFile"
			
			#if((nIndex != nIndexMax));then
			if(( nIndex != (${#astrMarkerID_Name[@]} - 1) ));then
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
		echo "echo \"Total at ${FUNCmapInfo_strMapName}: ${#astrMarkerID[@]}\"" >>"$strMapCfgFile"
		echo >>"$strMapCfgFile"
		echo "$strTeleportUpAlias" >>"$strMapCfgFile"
		echo "$strTeleportTargetAlias" >>"$strMapCfgFile"
		
		ln -vsf "$strMapCfgFile" "$strTeleCurrentCfgFile"
		cat "${strTeleCurrentCfgFile}" |egrep "^echo"
		
		if((${#astrMarkerID[@]}==0));then
			FUNCsay "Teleporter markers list is empty."
		else
			FUNCsay "Teleporter markers list is ready."
		fi
	fi
	
	strFlCondumpPrev="$strFlCondump"

	#TODO this can also update a file gskFillCurrentMapWithNPCs.cfg based on the current map name and on available files at CarefulCombat! so at 'q' key to reload some cfgs, it will also load gskFillCurrentMapWithNPCs.cfg that is ready with the spawn NPC settings for current map!
done
