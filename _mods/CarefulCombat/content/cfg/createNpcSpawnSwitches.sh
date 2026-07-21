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
	echo "alias gskCCnpcSpawn_${i} \"echo gskSpawnHint; getpos; getpos; echo ${strNPC}; ${strNPC}\"" #this way, it creates a reusable log to quickly place all NPCs again!!! OBS.: getpos 2 times is because the engine bugs and may not print one character some times
}

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
		FUNCechoInfo "[ERROR:invalid] $lstrChkNpc ( the engine sometimes do not print some letters!!! :O )"
		: ${strExecEdit:=geany} #help
		"$strExecEdit" "$lstrFlCondump:$((lLn+1))"
		FUNCexit 1
	fi
}

if [[ "${1-}" == "-m" ]];then #help read last condump and prepare a cfg file to help fill a map with placed NPCs
	strFlCondump="$(ls -1tr "${strGameInstallMainFolder}/${strGameSubRelatFolderWriteAllHere}/condump"* |tail -n 1)"
	ls -l "$strFlCondump"
	mapfile -t astrSpawnHintList < <(egrep "gskSpawnHint" "$strFlCondump" -A 2 |egrep -v "\--" |tr -d '\r')
	#for strSpawnHint in "${astrSpawnHintList[@]}";do
	iCount=0
	iDataLines=3
	echo
	echo "// FILL MAP WITH NPCs, total $((${#astrSpawnHintList[@]}/iDataLines))"
	echo "alias gskCCnpcSpawn_next gskCCnpcSpawn_000"
	for((i=0;i<${#astrSpawnHintList[@]};i+=iDataLines));do
		strPos="${astrSpawnHintList[$((i+1))]}"
		strPosChk="${astrSpawnHintList[$((i+2))]}" #as engine may not print one char! :O
		iLnNPC="$((i+3))"
		strNPC="$( echo "${astrSpawnHintList[$iLnNPC]}" |awk '{print $1}')"
		#declare -p strPos strNPC
		FUNCvalidateNPC "$strNPC" "$strFlCondump" "$iLnNPC"
		
		strCount="$(      printf %03d $((iCount  )) )"
		strCountPlus1="$( printf %03d $((iCount+1)) )"
		
		echo "alias gskCCnpcSpawn_${strCount} \"${strPos}; ${strNPC}; alias gskCCnpcSpawn_next gskCCnpcSpawn_${strCountPlus1}\""
		((iCount++))&&:
	done
else
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
