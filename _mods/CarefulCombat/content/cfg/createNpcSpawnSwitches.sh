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

# beware: necroguards, necromancers and undead are the only ones of the same faction right? so only these can be placed together without beggining a fight.
astrNPC=(
	#mm_npc_create_aratrok
	#mm_npc_create_cyclope
	#mm_npc_create_death_knight
	mm_npc_create_death_knight_shield
	mm_npc_create_ghoul
	mm_npc_create_goblin
	#mm_npc_create_human_guard #this is friendly right?
	#mm_npc_create_human_guard_bow #this is friendly right?
	#mm_npc_create_human_guard_shield #this is friendly right?
	mm_npc_create_lich
	mm_npc_create_lich_king
	#mm_npc_create_necro_guard
	mm_npc_create_necro_guard_bow # good because they wont drop arrows and wont make it easier
	mm_npc_create_necro_guard_shield # this would drop the shield I guess, use just one per room and only if you have no shield (tho they seem to fight better? but still very weak against lethal things like fire, drowning etc)
	mm_npc_create_necromancer
	mm_npc_create_necromancer_lord
	#mm_npc_create_orc_sword
	mm_npc_create_orc_sword_bow
	mm_npc_create_orc_sword_shield
	mm_npc_create_servant_specter
	mm_npc_create_spider
	#mm_npc_create_spider_mini
	mm_npc_create_undead
	#mm_npc_create_villager_undead
	#mm_npc_create_wizard #this is friendly right?
)

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
	: ${strFlCondump:="$(ls -1tr "${strGameInstallMainFolder}/${strGameSubRelatFolderWriteAllHere}/condump"* |tail -n 1)"} #help can be the backup like "${strMapCfgFile}.condump.txt"
	ls -l "$strFlCondump"
	
	# map     :  L00 at: -1385 x, -4444 y, 343 z
	: ${strMapName:="$(egrep "^map\s*:\s*L.*" "$strFlCondump" |sed -r -e 's@^map\s*:\s*(L[a-zA-Z0-9_-]*).*@\1@g')"} #help
	if [[ -z "$strMapName" ]];then
		FUNCechoInfo "[ERROR:noMapNameDetected]"
		FUNCexit 1
	fi
	strMapCfgFile="gskmap_${strMapName}.cfg"
	cp -v "$strMapCfgFile" "${strMapCfgFile}.bkp"&&:
	cp -vf "$strFlCondump" "${strMapCfgFile}.condump.txt"&&:
	echo -n >"$strMapCfgFile"
	
	strRestorePosInTheEnd="setpos $(egrep "^map\s*:\s*L.*" "$strFlCondump" |sed -r -e 's@^map\s*:\s*(L[a-zA-Z0-9_-]*)\s*at:\s*(.*)@\2@g' |tr -d 'xyz,\r')"
	
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
	FUNCechoAndFillFile "alias gskCCnpcSpawn_helper \"gskEffect100; host_timescale 0.01; ai_disable 1\""
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
			
			FUNCechoAndFillFile "alias gskCCnpcSpawn_${strCount} \"${strPos}; ${strNPC}; gskCCnpcSpawn_helper; alias gskCCnpcSpawn_next gskCCnpcSpawn_${strCountPlus1}\""
			((iCount++))&&:
			
			i=$iLnData
		fi
	done
	FUNCechoAndFillFile "alias gskCCnpcSpawn_${strCountPlus1} \"echo FinishedSpawnings; gskEffectOFF; play *arkane/english/xana/l05_xana_pillardone.wav; ${strRestorePosInTheEnd}; host_timescale 1.0; ai_disable 0\"" #this also prevents continuing thru some previous list entries of a previous test run or map may be
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
