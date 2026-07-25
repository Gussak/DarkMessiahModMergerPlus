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
	#mm_npc_create_spider_mini #do not use this one, it will encumber AI and RAM too that is better for challenging NPCs.
	mm_npc_create_undead
	#mm_npc_create_villager_undead
	#mm_npc_create_wizard #this is friendly right?
	mm_npc_create_facehugger # custom alias created now
)

function FUNCfixPosAng() {
	./analyzeGetSetPosAngleDiscrepancy.sh -f "$1"
}

function FUNCaliasNpcSpawner() {
	local lstrInfo="$1"
	# alias name limit is 30 chars
	local lstrShortName="${strNPC#mm_npc_create_}"
	local lstrBeginLoopHint="";if((i==0));then lstrBeginLoopHint=" <> <> <> <> <> <> <> <> <> <>";fi
	echo "alias gskCCnpcSwitch_${i} \"developer 1; contimes 50; echo CFG_CREATE${lstrInfo}:${lstrShortName}${lstrBeginLoopHint}; alias +gskCCnpcSpawn gskCCnpcSpawn_${i}; alias +gskCCnpcSwitch gskCCnpcSwitch_${iNext}\""
	echo "alias gskCCnpcSpawn_${i} \"echo gskSpawnHint; getpos; getpos; echo ${strNPC}; echo ${strNPC}; ${strNPC}\"" #this way, it creates a reusable log to quickly place all NPCs again!!! OBS.: getpos 2 times is because the engine bugs and may not print one character some times
}

: ${strExecEdit:=geany} #help
: ${bAutoFixMissingChars:=true} #help the engine may not print all charaters in a line, so usually repeating the command will provide a 2nd line with the missing char

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

bCreateSpawnsForCurrentMap=false
strAppendMapName=""
#bUpdateCondumpBkp=false
astrAllParams=("$@")
while [[ $# -gt 0 && "${1:0:1}" == "-" ]];do
	#if [[ "${1}" == "-d" ]];then #help update condump backup file using latest condump
		#bUpdateCondumpBkp=true
	if [[ "${1}" == "-m" ]];then #help read last condump and prepare a cfg file to help fill a map with placed NPCs
		bCreateSpawnsForCurrentMap=true
	elif [[ "${1}" == "-M" ]];then #help <strAppendMapName> same as -m but you can prepare a smaller area in that map with loads of foes to not encumber the engine, ex.: "02_FrontYard_OK" for gskmap_l02_b1_02_FrontYard_OK.cfg
		bCreateSpawnsForCurrentMap=true
		shift
		strAppendMapName="_${1}"
	else
		FUNCechoInfo "[ERROR] invalid option: $@"
		exit 1
	fi
	shift
done

if $bCreateSpawnsForCurrentMap;then
	: ${strFlCondump:="$(ls -1tr "${strGameInstallMainFolder}/${strGameSubRelatFolderWriteAllHere}/condump"* |tail -n 1)"} #help can be the backup like ex.: "gskmap_l02_b1_02_FrontYard_OK.cfg.condump.txt"
	ls -l "$strFlCondump"
	
	FUNCmapInfo "$strFlCondump"
	## map     :  L00 at: -1385 x, -4444 y, 343 z
	## map     :  l02_b1 at: -4902 x, -10930 y, 367 z
	#strRegexMapPos='^map\s*:\s*([a-zA-Z0-9_-]*)\s*at:\s*(.*)'
	#: ${strMapName:="$(ugrep "${strRegexMapPos}" "$strFlCondump" |head -n 1 |sed -r -e "s@${strRegexMapPos}@\1@g")"} #help
	#if [[ -z "$strMapName" ]];then
		#FUNCechoInfo "[ERROR:noMapNameDetected]"
		#FUNCexit 1
	#fi
	#strMapCfgFile="gskmap_${strMapName}${strAppendMapName}.cfg"
	strMapCfgFile="gskmap_${FUNCmapInfo_strMapName}${strAppendMapName}.cfg"
	#if $bUpdateCondumpBkp || [[ ! -f "${strMapCfgFile}.condump.txt" ]];then
	if [[ ! -f "${strMapCfgFile}.condump.txt" ]];then
		cp -vf "$strFlCondump" "${strMapCfgFile}.condump.txt"
	fi
	
	# clean condump file is good for git
	strFlCondumpClean="${strMapCfgFile}.condump_CLEAN.txt"
	bUsingCleanCondump=false;if [[ "$strFlCondump" == "$strFlCondumpClean" ]];then bUsingCleanCondump=true;fi
	iTotEntryDataLines=5
	if ! $bUsingCleanCondump;then
		cp -vf "$strFlCondumpClean" "$strFlCondumpClean.$(FUNCdtFlNm).bkp"&&:
		echo "$FUNCmapInfo_strMapStatus" >"$strFlCondumpClean"
	fi
	FUNCprepareCleanDataOriginBkp() {
		if $bUsingCleanCondump;then return 0;fi
		for((j=0;j<iTotEntryDataLines;j++));do
			local lstrLine="${astrAllLines[$((iLnDataIni+j))]}"
			local lstrExtra="";if [[ "$lstrLine" =~ ^gskSpawnHint.* ]];then lstrExtra="  // ( $((iSpawnCount+1))/${nTotSpawns} )";fi
			echo "${lstrLine}${lstrExtra}" >>"$strFlCondumpClean"
		done
	}
	
	cp -v "$strMapCfgFile" "${strMapCfgFile}.$(FUNCdtFlNm).bkp"&&:
	FUNCtrash "$strMapCfgFile" # like a temp backup
	echo -n >"$strMapCfgFile"
	
	#strPosRestore="$(ugrep "${strRegexMapPos}" "$strFlCondump" |head -n 1 |sed -r -e "s@${strRegexMapPos}@\2@g" |tr -d 'xyz,\r')"
	#if [[ -z "$strPosRestore" ]];then
		#FUNCechoInfo "[ERROR:noPosToRestoreDetected]"
		#FUNCexit 1
	#fi
	#strRestorePosInTheEnd="setpos ${strPosRestore}"
	strRestorePosInTheEnd="setpos ${FUNCmapInfo_strPosRestore}"
	
	#mapfile -t astrSpawnHintList < <(egrep "gskSpawnHint" "$strFlCondump" -A 2 |egrep -v "\--" |tr -d '\r')
	mapfile -t astrAllLines < <(cat "$strFlCondump" |tr -d '\r')
	#for strSpawnHint in "${astrSpawnHintList[@]}";do
	: ${iMoreFoesSpawnIndexBegin:=0} #help change this to help append indexes in an existing map cfg file. also be careful with the `setpos` in the finishing last one. use like ex.: iMoreFoesSpawnIndexBegin=11 ./createNpcSpawnSwitches.sh -M temp;
	iSpawnCount=$iMoreFoesSpawnIndexBegin
	#iDataLines=4
	echo
#	echo "// FILL MAP WITH NPCs, total $((${#astrSpawnHintList[@]}/iDataLines))"
	nTotSpawns="$(cat "$strFlCondump" |grep "^gskSpawnHint" -c)"
	if((nTotSpawns==0));then
		FUNCechoInfo "[ERROR:spawnSomeFoes] use F7 F8 keys"
		FUNCexit 1
	fi
	FUNCechoAndFillFile "// AUTO GENERATED WITH $(basename "$0"). DO NOT PATCH! Patch the '${strFlCondumpClean}' file instead!"
	FUNCechoAndFillFile "// FILL MAP WITH NPCs, total $nTotSpawns"
	#FUNCechoAndFillFile "alias gskCCnpcSpawn_helper \"\""
	strCmdsON=" developer 1; +duck; gskDevGodModeToggles; gskEffect100 " # do not use host_timescale 0.01 as it will mess teleporting. +duck is to help to fit yourself in smaller places causing less issues
	strCmdsOFF=" -duck; gskDevGodModeToggles; gskEffectOFF; developer 0 "
	FUNCechoAndFillFile "alias gskCCnpcSpawn_next \"${strCmdsON}; gskCCnpcSpawn_$( printf %03d $((iSpawnCount)) )\"" # initializes with some dev toggles
	#for((i=0;i<${#astrSpawnHintList[@]};i+=iDataLines));do
	for((i=0;i<${#astrAllLines[@]};i++));do
		strLine="${astrAllLines[$i]}"
		if [[ "$strLine" =~ ^gskSpawnHint.* ]];then
			iLnDataIni=$i
			iLnData=$iLnDataIni;#declare -p iLnData
			
			FUNCprepareCleanDataOriginBkp
			
			((iLnData++))&&:;strSelfPosAngle="${astrAllLines[$iLnData]}"
			((iLnData++))&&:;strSelfPosAngleChk="${astrAllLines[$iLnData]}" #as engine may not print one char! :O
			if [[ "$strSelfPosAngle" != "$strSelfPosAngleChk" ]];then
				if $bAutoFixMissingChars;then
					if((${#strSelfPosAngleChk} > ${#strSelfPosAngle}));then
						strSelfPosAngle="$strSelfPosAngleChk"
					fi
				else
					declare -p strSelfPosAngle strSelfPosAngleChk
					FUNCechoInfo "[ERROR:invalidPOS] ( the engine sometimes do not print some letters!!! :O )"
					"$strExecEdit" "$strFlCondump:$((iLnData+1))" #editors begin in line 1 not 0
					FUNCexit 1
				fi
			fi
			
			((iLnData++))&&:;strNPC="$(    echo "${astrAllLines[$iLnData]}" |awk '{print $1}')"
			((iLnData++))&&:;strNPCchk="$( echo "${astrAllLines[$iLnData]}" |awk '{print $1}')"
			#declare -p strSelfPosAngle strNPC
			if [[ "$strNPC" != "$strNPCchk" ]];then
				if $bAutoFixMissingChars;then
					if((${#strNPCchk} > ${#strNPC}));then
						strNPC="$strNPCchk"
					fi
				fi
			fi
			FUNCvalidateNPC "$strNPC" "$strFlCondump" "$iLnData"
			
			strCount="$(     printf %03d $((iSpawnCount  )) )"
			strCountShow="$( printf   %d $((iSpawnCount+1)) )" # begins in 1 and ends like 45/45 looks better
			strCountNext="$( printf %03d $((iSpawnCount+1)) )"
			
			FUNCechoAndFillFile "alias gskCCnpcSpawn_${strCount} \"$(FUNCfixPosAng "${strSelfPosAngle}"); ${strNPC}; echo Spawning:${strCountShow}/${nTotSpawns}:${strNPC#mm_npc_create_}; alias gskCCnpcSpawn_next gskCCnpcSpawn_${strCountNext}\""
			((iSpawnCount++))&&:
			
			if(( iTotEntryDataLines != (iLnData - iLnDataIni + 1) ));then
				FUNCechoInfo "[ERROR:DEV] invalid iTotEntryDataLines=$iTotEntryDataLines iLnData=$iLnData iLnDataIni=$iLnDataIni"
				exit 1
			fi
			i=$iLnData # jump skip, next loop will be +1
		fi
	done
	FUNCechoAndFillFile "alias gskCCnpcSpawn_${strCountNext} \"echo FinishedSpawnings; gskSndDONE; ${strRestorePosInTheEnd}; ${strCmdsOFF}; \"" #this also prevents continuing thru some previous list entries of a previous test run or map may be
	FUNCechoAndFillFile "clear" # before beggining each spawning, this is good
	FUNCechoAndFillFile "echo \"Now, slowly and repeatedly press the key to spawn the next NPC.\""
	FUNCechoAndFillFile "echo \"You will be in developer mode and carefully teleported to the location and rotation required for the spawning and without triggering anything.\""
	FUNCechoAndFillFile "echo \"Obs.: your vision is blurred to the spawn and location be a surprise.\""
	
	if egrep "^Unknown command: rm[0-9]*" -i "${strMapCfgFile}.condump.txt";then #help just type rm1 rm3 etc, will not be recognized as a command but will be logged!
		FUNCechoInfo "[WARN] removes detected, better edit to remove from that line up to 'gskSpawnHint' and rerun!" #TODO this can be scripted easily if the echo on the console is like: RemoveAbove=1 or Remove=1 or RM1; echo RM1; echo rm2
		echo "${strExecEdit} '${strMapCfgFile}.condump.txt'"
		echo "strFlCondump='${strMapCfgFile}.condump.txt' $0 ${astrAllParams[@]}"
	fi
	
	ls -l "$strMapCfgFile"
else # create spawner aliases
	echo
	echo "// Total ${#astrNPC[@]} NPCs"
	echo "alias mm_npc_create_facehugger \"mm_npc_create npc_facehugger models/NPC/Facehugger/Npc_Facehugger.mdl\""
	
	# these could work but the engine do not allow it. The NPC is created but the special item (bread or potion) is badly positioned at feet and on death it just vanishes.
	#  mm_npc_create npc_necro_guard_bow models/npc/Necroguard/npc_necroguard.mdl item_food_bread01_cooked weapon_arx_short_sword  weapon_arxcrossbow
	#  mm_npc_create npc_necro_guard_bow models/npc/Necroguard/npc_necroguard.mdl item_potion_life weapon_arx_short_sword weapon_arxcrossbow
	#  mm_npc_create npc_necro_guard models/npc/Necroguard/npc_necroguard.mdl item_potion_life item_potion_life weapon_arx_short_sword weapon_mm_shield_necroguard
	
	for((i=0;i<${#astrNPC[@]};i++));do
		strNPC="${astrNPC[$i]}"
		iNext=$((i+1))&&:
		if(( i == (${#astrNPC[@]}-1) ));then
			iNext=0
		fi
		FUNCaliasNpcSpawner "( $i / $((${#astrNPC[@]} - 1)) )"
	done
fi

