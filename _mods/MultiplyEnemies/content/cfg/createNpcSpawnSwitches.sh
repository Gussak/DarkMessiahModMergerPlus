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

lstrUseThisSector=""
while [[ ! -f "./allMergerScriptsGenericConfig.sh" ]];do cd ..;done; source "./allMergerScriptsGenericConfig.sh"; FUNCminiModInit "$@"

: ${strSpawnerMode:=MoreFoes} #help "MoreFoes" or "Summoning"
astrNPCsummonTmp_ID=()
astrNPCsummonTmp_Cost=()
astrNPCsummon_ID=()
astrNPCsummon_Cost=()
astrNPCsummon_Type=()
#declare -A astrNPCsummonings_Cost
#declare -A astrNPCsummonings_CostTmp
mapfile -t astrNPCsummoningsLines < <(cd "$strPathParent"; egrep "^alias [+]*gskSummon" * -iRIah --include="*.cfg" |egrep -v "Spawn|Switch|gskSummonFood" |sort -u) #gskSummonFood is a dup generic easy food spwning alias
#if [[ "$strSpawnerMode" == Summoning ]];then
if true;then
	for strLnData in "${astrNPCsummoningsLines[@]}";do
		strAliasSummon="$(echo "$strLnData" |awk '{print $2}')"
		FUNCcostHP "${strAliasSummon}"
		astrNPCsummonTmp_ID+=("${strAliasSummon}")
		astrNPCsummonTmp_Cost+=("${FUNCcostHP_nCost}")
		#astrNPCsummonings_CostTmp["$strAliasSummon"]="${FUNCcostHP_nCost}"
	done
	
	# sort by type
	FUNCfillByType_astrAlreadyUsed=()
	function FUNCfillByType() {
		#local lstrOptNot="";if [[ "$1" == --not ]];then lstrOptNot="-v";shift;fi
		local lbOptNot=false;if [[ "$1" == --not ]];then lstrOptNot=true;shift;fi
		local lstrTypeID="$1";shift
		local lstrTypeRegex="$1";shift
		
		#declare -g FUNCfillByType_regexAlreadyUsed=""
		#if [[ -n "${FUNCfillByType_regexAlreadyUsed}" ]];then
			#FUNCfillByType_regexAlreadyUsed+="|"
		#fi
		#FUNCfillByType_regexAlreadyUsed+="$lstrTypeRegex"
		
		#for strAlias in "${!astrNPCsummonings_CostTmp[@]}";do
		local i
		for((i=0;i<${#astrNPCsummonTmp_ID[@]};i++));do
			#if echo "$strAlias" |egrep -i "$lstrTypeRegex";then
				#astrNPCsummonings_Cost[${strAlias}]="${astrNPCsummonings_CostTmp[${strAlias}]}"
				#unset astrNPCsummonings_CostTmp[${strAlias}]
			#fi
			#if echo "${astrNPCsummonTmp_ID[$i]}" |egrep $lstrOptNot -i "$lstrTypeRegex";then
			if echo "${astrNPCsummonTmp_ID[$i]}" |egrep -iq "$lstrTypeRegex";then
				local lbAdd=true
				#if $lbOptNot;then
					local lstrChkNot
					for lstrChkNot in "${FUNCfillByType_astrAlreadyUsed[@]}";do
						if [[ "${astrNPCsummonTmp_ID[$i]}" == "$lstrChkNot" ]];then
							lbAdd=false
							break
						fi
					done
				#fi
				if $lbAdd;then
					astrNPCsummon_ID+=("${astrNPCsummonTmp_ID[$i]}")
					astrNPCsummon_Cost+=("${astrNPCsummonTmp_Cost[$i]}")
					astrNPCsummon_Type+=("${lstrTypeID}")
					FUNCfillByType_astrAlreadyUsed+=("${astrNPCsummonTmp_ID[$i]}")
				fi
			fi
		done
	}
	# aliases size limit is 30. So better add these hints there: npc food etc...
	FUNCfillByType "FriendlyNPCs"  "^[+]gskSummonGuardBow$|villager" #friendly NPCs
	FUNCfillByType "EtcNPCs"       "corpse" #etc NPCs
	FUNCfillByType "FoeNPCs"       "necroguard|necromancer|spider|facehugger|undead" #foe NPCs
	FUNCfillByType "POTIONS"       "potion"
	FUNCfillByType "DummyNPCs"     "crow|seagull|dog|pig" #harmless NPCs
	FUNCfillByType "FOOD"          "leek|bread|rib|fish|chicken|banana|food|fibs|garlic|ham|mushroom|pie" #food
	FUNCfillByType "Weapons/Tools" "club|staff|sword" #tools/weapons
	#FUNCfillByType --not "${FUNCfillByType_regexAlreadyUsed}" #everything else
	FUNCfillByType --not "ETC" ".*" #everything else
fi
#mapfile -t astrNPCsummonings_Cost < <(for strLnData in "${astrNPCsummoningsLines[@]}";do echo "$strLnData";done |awk '{print $2}' |sort -u)
#declare -p astrNPCsummonings_Cost |sed -r -e "$strSedArrayIDsToLn"
declare -p astrNPCsummoningsLines astrNPCsummonTmp_ID astrNPCsummon_Cost FUNCfillByType_astrAlreadyUsed astrNPCsummon_ID |sed -r -e "$strSedArrayIDsToLn"

# beware: necroguards, necromancers and undead are the only ones of the same faction right? so only these can be placed together without beggining a fight. TODO: there is a factions config file
astrNPCmoreFoes=( # shall be game commands or my configured alisases (that will look like a game command)
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
	local liCurrentIndex="$1";shift
	local lstrType="$1";shift
	local lstrShortName="$1";shift
	local liTot="$1";shift
	
	local liMaxIndex="$((liTot-1))"
	local lstrInfo="( $i / $liMaxIndex )"
	# alias name limit is 30 chars

	local lstrBeginLoopHint="";if((liCurrentIndex==0));then lstrBeginLoopHint=" <> <> <> <> <> <> <> <> <> <>";fi
	local iPrevious=$((liCurrentIndex-1));if((iPrevious==-1));then iPrevious=$liMaxIndex;fi
	echo "alias gsk${lstrType}Switch_${liCurrentIndex} \"\
gskEchoOn; \
contimes 50; \
echo CFG_CREATE${lstrInfo}:${lstrShortName}${lstrBeginLoopHint}; \
alias +gsk${lstrType}Spawn      +gsk${lstrType}Spawn_${liCurrentIndex}; \
alias -gsk${lstrType}Spawn      -gsk${lstrType}Spawn_${liCurrentIndex}; \
alias +gsk${lstrType}SwitchPrev gsk${lstrType}Switch_${iPrevious}; \
alias +gsk${lstrType}Switch     gsk${lstrType}Switch_${iNext}; \
\""
	echo "alias +gsk${lstrType}Spawn_${liCurrentIndex} \"\
echo gskSpawnHint; \
getpos; getpos; \
echo ${strNPC}; echo ${strNPC}; \
${strNPC}; \
\"" #this way, it creates a reusable log to quickly place all NPCs again!!! OBS.: getpos 2 times is because the engine bugs and may not print one character some times
	echo "alias -gsk${lstrType}Spawn_${liCurrentIndex} \"\
ent_setname gskSpawnNameOk; \
\"" #it is important to wait the spawn happen before assigning a name to it
}

: ${strExecEdit:=geany} #help
: ${bAutoFixMissingChars:=true} #help the engine may not print all charaters in a line, so usually repeating the command will provide a 2nd line with the missing char

function FUNCvalidateNPC() {
	local lstrChkNpc="$1";shift
	local lstrFlCondump="$1";shift
	local lLn="$1";shift
	
	local lbFound=false
	local i
	for((i=0;i<${#astrNPCmoreFoes[@]};i++));do
		local lstrNPC="${astrNPCmoreFoes[$i]}"
		#declare -p lstrNPC lstrChkNpc
		if [[ "$lstrChkNpc" == "$lstrNPC" ]];then lbFound=true;break;fi
	done
	for((i=0;i<${#astrNPCsummon_ID[@]};i++));do
		local lstrNPC="${astrNPCsummon_ID[$i]}"
		if [[ "$lstrChkNpc" == "$lstrNPC" ]];then lbFound=true;break;fi
	done
	if ! $lbFound;then
		FUNCechoInfo "[ERROR:invalidNPC] '$lstrChkNpc' ( the engine sometimes do not print some letters!!! :O )"
		"$strExecEdit" "$lstrFlCondump:$((lLn+1))"  #editors begin in line 1 not 0
		FUNCexit 1
	fi
}

function FUNCechoAndFillFile() {
	echo "$1" |tee -a "$strMapCfgFile"
}

bCreateSpawnsForCurrentMap=false
#bUpdateCondumpBkp=false
astrAllParams=("$@")
lstrUseThisMap=""
bRedoAll=false
while [[ $# -gt 0 && "${1:0:1}" == "-" ]];do
	#if [[ "${1}" == "-d" ]];then #help update condump backup file using latest condump
		#bUpdateCondumpBkp=true
	if [[ "${1}" == "-c" ]];then #help read last condump and prepare a cfg file to help fill a map with placed NPCs
		bCreateSpawnsForCurrentMap=true
	elif [[ "${1}" == "-m" ]];then #help <lstrUseThisMap> <lstrUseThisSector> specify a map like 'l02_b1' and a sector like '02_FrontYard_OK', now it will look for a cleaned condump file for it. lstrUseThisSector can be empty like "" if there is no sector because the map is too small.
		shift;lstrUseThisMap="${1}"
		shift;lstrUseThisSector="${1}"
		bCreateSpawnsForCurrentMap=true
	elif [[ "${1}" == "-M" ]];then #help like -m but a single string like l02_b2-05_Library_OK will become lstrUseThisMap=l02_b2 and lstrUseThisSector=05_Library_OK. You can use just the filename also like gskmap_l02_b2-05_Library_OK.cfg
		shift;lstrMapSector="${1}"
		lstrMapSector="${lstrMapSector#gskmap_}"
		lstrMapSector="${lstrMapSector%.cfg}"
		lstrUseThisMap="$(     echo "$lstrMapSector" |sed -r -e 's@(.*)-(.*)@\1@g')"
		if [[ "$lstrMapSector" =~ .*[-].* ]];then
			lstrUseThisSector="$(echo "$lstrMapSector" |sed -r -e 's@(.*)-(.*)@\2@g')"
		else
			lstrUseThisSector=""
		fi
		bCreateSpawnsForCurrentMap=true
	elif [[ "${1}" == "-s" ]];then #help <lstrUseThisSector> same as -c but you can prepare a smaller SECTOR area in that map with loads of foes to not encumber the engine, ex.: "02_FrontYard_OK" for gskmap_l02_b1-02_FrontYard_OK.cfg
		shift;lstrUseThisSector="${1}"
		bCreateSpawnsForCurrentMap=true
	elif [[ "${1}" == "--redoall" ]];then #help mainly to be used after patching this script
		bRedoAll=true
	else
		FUNCechoInfo "[ERROR] invalid option: $@"
		exit 1
	fi
	shift
done

if $bRedoAll;then
	mapfile -t astrRedoAll < <(ls gskmap*.cfg |sed -r -e 's@gskmap_(.*)[.]cfg@\1@g')
	for strRedo in "${astrRedoAll[@]}";do
		echo
		echo "=============== $strRedo ==============="
		echo "=============== $strRedo ==============="
		echo "=============== $strRedo ==============="
		"$0" -M "$strRedo"
	done
	exit
fi
	
#help @InfoID="Log flood Issue workaround" having to save many condumps and merge them (as they have a size limit) due to flooded unstoppable warn log messages, after merging them all there may happen several dup spawns, use this (it will turn all multine entry into a single line, sort it unique and restore it into multiline) ex.: clear;cat gskmap_l02_b2-04_ThroneRoom.cfg.condump_CLEAN.txt |egrep -v "^map" |sed -r -e 's@(gskSpawnHint).*@\1 @g' |tr -d '\n' |sed -r -e 's@gskSpawnHint@\n&@g'|sort -u |sed -r -e 's@setpos@\nsetpos@g' -e 's@mm_npc@\nmm_npc@g' #Tho the best way is to just find a previous save where there is no flood on the log (as I couldnt determine the cause of the problem).
#help @InfoID="Spawining Issue" Sometimes it may be impossible to find a good location and rotation for you to stay and that will be correctly restored later. The tip is: just replace the rotation (setang) for a spawn that is failing, with a rotation that is working (dont move, just rotate until it works)!
#help @InfoID="Usage Info" you can edit just the CLEAN file if you know what you are doing
#help @InfoID="Usage Example" strFlCondump="gskmap_L00.cfg.condump_CLEAN.txt" ./createNpcSpawnSwitches.sh -c #first time you use a newly generated condump by the game
#help @InfoID="Usage Example" strFlCondump="gskmap_l02_b1-01_GuestHouse_OK.cfg.condump_CLEAN.txt" ./createNpcSpawnSwitches.sh -s "01_GuestHouse_OK" #setting the condump manually
#help @InfoID="Usage Example" ./createNpcSpawnSwitches.sh -m l02_b2 01_LowestBigRoom_OK #easiest for maintenance, auto detects existing cleaned condump
#help @InfoID="Usage Example" ./createNpcSpawnSwitches.sh -m L02_A "" #this is for a small map that has no need for sectors
#help @InfoID="Hint" when you find 2 or more crows, that is when you can apply the next gskmap morefoes (after you clean the room)
#help @InfoID="Hint" when you find a seagull, it means there is some secret in that wall/floor/ceiling etc, that can only be reached thru +gskMoveThruWall. Be sure to crouch before using it as the space behind the wall may only fit if you are crouched. Anyway it auto saves before you teleport so you can just reload. If the teleport doesnt work, come back later after you clean almost all foes spawned, it may be related to the extra lag they generate.

function FUNCmapCfg() { #ex.: gskmap_l02_b1-01_GuestHouse_OK.cfg
	local lstr="gskmap_${1}"
	if [[ -n "${2}" ]];then
		lstr+="-${2}"
	fi
	lstr+=".cfg"
	echo "$lstr"
}

if $bCreateSpawnsForCurrentMap;then
	if [[ -n "$lstrUseThisMap" ]];then
		strFlCondump="$(FUNCmapCfg "${lstrUseThisMap}" "${lstrUseThisSector}").condump_CLEAN.txt"
	fi
	: ${strFlCondumpNewest:="$(ls -1tr "${strGameInstallMainFolder}/${strGameSubRelatFolderWriteAllHere}/condump"* |tail -n 1)"} #help
	: ${strFlCondump:="${strFlCondumpNewest}"} #help instead of being automatically the newest file, it can be the backup file like ex.: "gskmap_l02_b1-02_FrontYard_OK.cfg.condump.txt" or even the clean file ex.: "gskmap_l02_b1-02_FrontYard_OK.cfg.condump_CLEAN.txt"
	declare -p strFlCondump
	if ! ls -l "$strFlCondump";then
		FUNCechoInfo "[ERROR] condump file not found '$strFlCondump'"; 
		declare -p strFlCondumpNewest
		if FUNCaskYesNo "use newest condump to create a new one?";then
			strFlCondump="${strFlCondumpNewest}"
		else
			FUNCexit 1;
		fi
	fi
	
	while ! FUNCmapInfo "$strFlCondump";do FUNCwaitSeconds 3 "condump needs map info status data";done
	## map     :  L00 at: -1385 x, -4444 y, 343 z
	## map     :  l02_b1 at: -4902 x, -10930 y, 367 z
	#strRegexMapPos='^map\s*:\s*([a-zA-Z0-9_-]*)\s*at:\s*(.*)'
	#: ${strMapName:="$(ugrep "${strRegexMapPos}" "$strFlCondump" |head -n 1 |sed -r -e "s@${strRegexMapPos}@\1@g")"} #help
	#if [[ -z "$strMapName" ]];then
		#FUNCechoInfo "[ERROR:noMapNameDetected]"
		#FUNCexit 1
	#fi
	#strMapCfgFile="gskmap_${strMapName}_${lstrUseThisSector}.cfg"
	#strMapCfgFile="gskmap_${FUNCmapInfo_strMapName}"
	#if [[ -n "${lstrUseThisSector}" ]];then
		#strMapCfgFile+="-${lstrUseThisSector}"
	#fi
	#strMapCfgFile+=".cfg"
	strMapCfgFile="$(FUNCmapCfg "${FUNCmapInfo_strMapName}" "${lstrUseThisSector}")"
	#if $bUpdateCondumpBkp || [[ ! -f "${strMapCfgFile}.condump.txt" ]];then
	if [[ -f "${strMapCfgFile}.condump.txt" ]];then
		cp -v "${strMapCfgFile}.condump.txt" "${strMapCfgFile}.condump.txt.$(FUNCdtFlNm).bkp"
	fi
	if ! cmp "$strFlCondump" "${strMapCfgFile}.condump.txt";then
		cp -vf "$strFlCondump" "${strMapCfgFile}.condump.txt"
	fi
	
	# clean condump file is good for git
	strFlCondumpClean="${strMapCfgFile}.condump_CLEAN.txt"
	if [[ "$strFlCondump" == "$strFlCondumpClean" ]];then
		strUseThisCondump="${strFlCondumpClean}.TMP.txt"
		cp -vf "$strFlCondumpClean" "${strUseThisCondump}"&&:
		strFlCondump="$strUseThisCondump"
	fi
	#if ! $bUsingCleanCondump;then
		cp -vf "$strFlCondumpClean" "$strFlCondumpClean.$(FUNCdtFlNm).bkp"&&:
		echo "$FUNCmapInfo_strMapStatus" >"$strFlCondumpClean"
		echo "$FUNCmapInfo_strMapStatus" >>"$strFlCondumpClean"
	#fi
	FUNCprepareCleanDataOriginBkp() {
		#if $bUsingCleanCondump;then return 0;fi
		for((j=0;j<iTotEntryDataLines;j++));do
			local lstrLine="${astrAllLines[$((iLnDataIni+j))]}"
			local lstrExtra=""
			if [[ "$lstrLine" =~ ^gskSpawnHint.* ]];then 
				lstrExtra="  // ( $((iSpawnCount+1))/${nTotSpawns} )";
			fi
			lstrLine="$(echo "${lstrLine}" |sed -r -e 's@(^gskSpawnHint[^ ]*).*@\1@g')"
			echo "${lstrLine} ${lstrExtra}" >>"$strFlCondumpClean"
		done
	}
	#bUsingCleanCondump=false;if [[ "$strFlCondump" == "$strFlCondumpClean" ]];then bUsingCleanCondump=true;fi
	#if ! $bUsingCleanCondump;then
		#cp -vf "$strFlCondumpClean" "$strFlCondumpClean.$(FUNCdtFlNm).bkp"&&:
		#echo "$FUNCmapInfo_strMapStatus" >"$strFlCondumpClean"
		#echo "$FUNCmapInfo_strMapStatus" >>"$strFlCondumpClean"
	#fi
	#FUNCprepareCleanDataOriginBkp() {
		#if $bUsingCleanCondump;then return 0;fi
		#for((j=0;j<iTotEntryDataLines;j++));do
			#local lstrLine="${astrAllLines[$((iLnDataIni+j))]}"
			#local lstrExtra="";if [[ "$lstrLine" =~ ^gskSpawnHint.* ]];then lstrExtra="  // ( $((iSpawnCount+1))/${nTotSpawns} )";fi
			#echo "${lstrLine}${lstrExtra}" >>"$strFlCondumpClean"
		#done
	#}
	
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
	: ${iMoreFoesSpawnIndexBegin:=0} #help change this to help append indexes in an existing map cfg file. also be careful with the `setpos` in the finishing last one. use like ex.: iMoreFoesSpawnIndexBegin=11 ./createNpcSpawnSwitches.sh -s temp;
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
	strCmdsErasers="gskManaRegEraser; gskHMHurtmeEraser1of3; gskHMHurtmeEraser2of3; gskHMHurtmeEraser3of3; alias gskSmnWORK gskSmnWORKmoreFoes" #erasers are  to avoid messing the player HP and Mana pools and remove effects that slowdown things like placing more foes at least
	strCmdsON=" gskEchoOn; +duck; gskDevGodModeToggles; gskEffect100; ${strCmdsErasers}; alias gskWaitInteractDev gskWait333ms; " # do not use host_timescale 0.01 as it will mess teleporting. +duck is to help to fit yourself in smaller places causing less issues
	strCmdsOFF=" -duck; gskDevGodModeToggles; gskEffectOFF; gskEchoOff; +gskReloadCfgs " # +gskReloadCfgs is to restore what was erased
	FUNCechoAndFillFile "alias +gskCCnpcSpawn_next \"${strCmdsON}; +gskCCnpcSpawn_$( printf %03d $((iSpawnCount)) )\"" # initializes with some dev toggles
	#for((i=0;i<${#astrSpawnHintList[@]};i+=iDataLines));do
	for((i=0;i<${#astrAllLines[@]};i++));do
		strMODE=SpawnNPC
		iTotEntryDataLines=5
		strLine="${astrAllLines[$i]}"
		if [[ "$strLine" =~ ^gskSpawnHint.* ]];then
			strCount="$(     printf %03d $((iSpawnCount  )) )"
			strCountShow="$( printf   %d $((iSpawnCount+1)) )" # begins in 1 and ends like 45/45 looks better
			strCountNext="$( printf %03d $((iSpawnCount+1)) )"
			
			#if [[ "$strLine" =~ ^gskSpawnHint_DropPotion.* ]];then
				#iTotEntryDataLines=3
				#if [[ "$strLine" =~ ^gskSpawnHint_DropPotionLife.* ]];then
					#strMODE=DropItem
					#strDropItem="gskMapDevDropPotionLife"
				#fi
				#if [[ "$strLine" =~ ^gskSpawnHint_DropPotionMana.* ]];then
					#strDropItem="gskMapDevDropPotionMana"
				#fi
			#fi
			
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
			
			bInteractUseMode=false
			strAliasValue=""
			strAliasValue+="$(FUNCfixPosAng "${strSelfPosAngle}"); "
			strAliasValueLift=""
			strAliasInfo="echo Spawning:${strCountShow}/${nTotSpawns}"
			case "$strMODE" in
				SpawnNPC)
					((iLnData++))&&:;strNPC="$(    echo "${astrAllLines[$iLnData]}" |awk '{print $1}')"
					((iLnData++))&&:;strNPCchk="$( echo "${astrAllLines[$iLnData]}" |awk '{print $1}')"
					if [[ "$strNPC" != "$strNPCchk" ]];then
						if $bAutoFixMissingChars;then
							if((${#strNPCchk} > ${#strNPC}));then
								strNPC="$strNPCchk"
							fi
						fi
					fi
					
					if [[ "$strNPC" == "+gskInteractUseDev" ]];then
						bSetName=false;
						#strAliasValue+="mm_host_timescale 10; gskWait333ms; "
					elif [[ "$strNPC" =~ ^dummy.* ]];then
						bSetName=false;
					else
						FUNCvalidateNPC "$strNPC" "$strFlCondump" "$iLnData"
					fi
					#if [[ "$strNPC" == "+gskInteractUseDev" ]];then
						#strAliasInfo+=":+gskInteractUseDev; "
						#strAliasValue+="${strAliasInfo}; "
						#bInteractUseMode=true;
					#else
						#strAliasInfo+=":${strNPC#mm_npc_create_}; "
						#strAliasValue+="${strNPC}; ${strAliasInfo}; "
					#fi
					strAliasInfo+=":${strNPC#mm_npc_create_}; "
					strAliasValue+="${strNPC}; ${strAliasInfo}; "
					;;
				#InteractUse)
					#strAliasValue+="+use; ${strAliasInfo}:${strDropItem#gskMapDevDrop}; "
					#;;
				#DropItem) #help @Info ID="DroppingItems" prefer to place these at the end of the file to not mess NPCs placement
					#strAliasValue+="${strDropItem}; ${strAliasInfo}:${strDropItem#gskMapDevDrop}; "
					#;;
			esac
			strAliasValue+="alias +gskCCnpcSpawn_next +gskCCnpcSpawn_${strCountNext}; alias -gskCCnpcSpawn_next -gskCCnpcSpawn_${strCountNext}; "
			#FUNCechoAndFillFile "alias +gskCCnpcSpawn_${strCount} \"-gskInteractUseDev; ${strAliasValue}\"" #-gskInteractUseDev is to grant next +gskInteractUseDev wont break.
			FUNCechoAndFillFile "alias +gskCCnpcSpawn_${strCount} \"${strAliasValue}\""
			#if $bInteractUseMode;then
				#FUNCechoAndFillFile "alias -gskCCnpcSpawn_${strCount} \"+gskInteractUseDev\"" #the action must happen after the teleport
			#else
			if $bSetName;then
				FUNCechoAndFillFile "alias -gskCCnpcSpawn_${strCount} \"ent_setname gskSpawn${strCount}; ${strAliasValueLift}; \""
			fi
			
			((iSpawnCount++))&&:
			
			if(( iTotEntryDataLines != (iLnData - iLnDataIni + 1) ));then
				FUNCechoInfo "[ERROR:DEV] invalid iTotEntryDataLines=$iTotEntryDataLines iLnData=$iLnData iLnDataIni=$iLnDataIni"
				exit 1
			fi
			i=$iLnData # jump skip, next loop will be +1
		fi
	done
	#FUNCechoAndFillFile "alias +gskCCnpcSpawn_${strCountNext} \"echo FinishedSpawnings; gskSndDONE; ${strRestorePosInTheEnd}; ${strCmdsOFF}; -gskInteractUseDev; alias gskCCnpcSpawn_next +gskCCnpcSpawn_Finished; \"" #this also prevents continuing thru some previous list entries of a previous test run or map may be. -gskInteractUseDev is to grant next +gskInteractUseDev wont break.
	FUNCechoAndFillFile "alias +gskCCnpcSpawn_${strCountNext} \"echo FinishedSpawnings; gskSndDONE; ${strRestorePosInTheEnd}; ${strCmdsOFF}; alias gskCCnpcSpawn_next +gskCCnpcSpawn_Finished; \"" #this also prevents continuing thru some previous list entries of a previous test run or map may be.
	FUNCechoAndFillFile "alias -gskCCnpcSpawn_${strCountNext} \"\""
	FUNCechoAndFillFile "alias +gskCCnpcSpawn_Finished \"gskEchoOn; echo Finished Spawnings Already for this map $FUNCmapInfo_strMapName\""
	FUNCechoAndFillFile "alias -gskCCnpcSpawn_Finished \"gskEchoOff\""
	FUNCechoAndFillFile "clear" # before beggining each spawning, this is good
	FUNCechoAndFillFile "echo \"DO THESE NOW PLEASE!!!\""
	FUNCechoAndFillFile "echo \" - Stand up (will auto crouch to help fit and positioning).\""
	FUNCechoAndFillFile "echo \" - Enable and disable gskDevGodModeToggles and read the final status for each power, just to be sure all toggles are reset (as unfortunately we can't set them (right?)... only toggle... or NPC deployment may go out of control).\""
	FUNCechoAndFillFile "echo \" - Close the console. While you can bind +gskCCnpcSpawn_next to a key like F4 (that will work with the console opened), it will not work when releasing the key to execute -gskCCnpcSpawn_next.\""
	FUNCechoAndFillFile "echo \" - Hide your weapon (optional).\""
	FUNCechoAndFillFile "echo \"Now, slowly(?) and repeatedly press the key to spawn the next NPC: +gskCCnpcSpawn_next\""
	FUNCechoAndFillFile "echo \"You will be in developer mode and carefully teleported to the location and rotation required for the spawning and without triggering anything.\""
	FUNCechoAndFillFile "echo \"Obs.: your vision is blurred to the spawn and location be a surprise.\"" #TODO fadeout to completely hide spawnings? will make it impossible to detect issues tho.
	
	if egrep "^Unknown command: rm[0-9]*" -i "${strMapCfgFile}.condump.txt";then #help just type rm1 rm3 etc, will not be recognized as a command but will be logged!
		FUNCechoInfo "[WARN] removes detected, better edit to remove from that line up to 'gskSpawnHint' and rerun!" #TODO this can be scripted easily if the echo on the console is like: RemoveAbove=1 or Remove=1 or RM1; echo RM1; echo rm2
		echo "${strExecEdit} '${strMapCfgFile}.condump.txt'"
		echo "strFlCondump='${strMapCfgFile}.condump.txt' $0 ${astrAllParams[@]}"
	fi
	
	ls -l "$strMapCfgFile"
else # create spawner aliases
	strAliasMode=""
	case "$strSpawnerMode" in
		MoreFoes)
			astrNPC=("${astrNPCmoreFoes[@]}")
			strAliasMode="CCnpc" #CreateChaos NPCs
			;;
		Summoning)
			#astrNPC=("${!astrNPCsummonings_Cost[@]}")
			astrNPC=("${astrNPCsummon_ID[@]}")
			strAliasMode="GPSmn" #GamePlay Summoning
			;;
		*) echo "invalid strSpawnerMode='$strSpawnerMode'"; exit 1;;
	esac
	
	echo
	echo "// Total ${#astrNPC[@]} NPCs/Items"
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
		case "$strSpawnerMode" in
			MoreFoes)
				strShortName="${strNPC#mm_npc_create_}"
				;;
			Summoning)
				strShortName="[${astrNPCsummon_Type[$i]}] $(echo "${strNPC}" |sed -r -e 's@[+]*gskSummon(.*)@\1@g') HP${astrNPCsummon_Cost[${i}]}"
				;;
			*) echo "invalid strSpawnerMode='$strSpawnerMode'"; exit 1;;
		esac
		FUNCaliasNpcSpawner "${i}" "${strAliasMode}" "${strShortName}" "${#astrNPC[@]}"
	done
	echo
	echo "// NOW COPY THE ABOVE INTO THE CONFIG FILE //TODO auto replace the section"
fi

FUNCrefreshMount


