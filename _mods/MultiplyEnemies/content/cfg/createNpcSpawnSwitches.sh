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

lstrUseThisSector=""
while [[ ! -f "./allMergerScriptsGenericConfig.sh" ]];do cd ..;done; source "./allMergerScriptsGenericConfig.sh"; FUNCminiModInit "$@"

: ${strSpawnerMode:=Summoning} #help "MoreFoes" or "Summoning"

: ${strFlDBsummoningsTmp:=""} #help internal use
if [[ -f "$strFlDBsummoningsTmp" ]];then
	source "$strFlDBsummoningsTmp"
else
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
			FUNCcostHP "${strAliasSummon}" >/dev/null
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
		FUNCfillByType "FriendlyNPCs"  "^[+]gskSummonGuard$|[+]gskSummonWizard$|[+]gskSummonGuardBow$|[+]gskSummonGuardMini$|villager" #friendly NPCs
		FUNCfillByType "EtcNPCs"       "corpse" #etc NPCs
		FUNCfillByType "FoeNPCs"       "necroguard|necromancer|spider|facehugger|undead" #foe NPCs
		FUNCfillByType "POTIONS"       "potion"
		FUNCfillByType "DummyNPCs"     "crow|seagull|dog|pig" #harmless NPCs
		FUNCfillByType "FOOD"          "leek|bread|rib|fish|chicken|banana|food|fibs|garlic|ham|mushroom|pie" #food
		FUNCfillByType "Weapons/Tools" "club|staff|sword" #tools/weapons
		FUNCfillByType "Simulated"     "gskSummonSim" #items otherwise impossible to be spawned
		#FUNCfillByType --not "${FUNCfillByType_regexAlreadyUsed}" #everything else
		FUNCfillByType --not "ETC" ".*" #everything else
	fi
	#mapfile -t astrNPCsummonings_Cost < <(for strLnData in "${astrNPCsummoningsLines[@]}";do echo "$strLnData";done |awk '{print $2}' |sort -u)
	#declare -p astrNPCsummonings_Cost |sed -r -e "$strSedArrayIDsToLn"
	astrDBlist=(astrNPCsummoningsLines astrNPCsummonTmp_ID astrNPCsummon_Cost FUNCfillByType_astrAlreadyUsed astrNPCsummon_ID)
	declare -p "${astrDBlist[@]}" |sed -r -e "$strSedArrayIDsToLn"
	
	export strFlDBsummoningsTmp="$(mktemp)"
	declare -p "${astrDBlist[@]}" >"$strFlDBsummoningsTmp"
fi

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

function FUNCposAngEchoOrCmdPipe() { # it is impossible (?) to let console echo cmd print ';', so the only way it so use like ':' instead
	local lstr="${1-}"
	
	if [[ -z "$lstr" ]];then read lstr;fi
	
	if [[ "$lstr" =~ .*\;.* ]];then
		echo "$lstr" |tr ';' ':'
	else
		echo "$lstr" |tr ':' ';'
	fi
}
FUNCposAngAsCmd()       { echo "$1" |tr ':' ';' |sed -r -e 's@^\s*|\s*$@@g'; }
FUNCposAngAsEcho()      { echo "$1" |tr ';' ':' |sed -r -e 's@^\s*|\s*$@@g'; }
FUNCposAngAsEchoShort() { echo "$1" |tr ';' ':' |sed -r -e 's@^\s*|\s*$@@g' -e 's@[.][0-9]*@@g'; } # removes float precision

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
gskSpawnHintData; \
echo ${strSpawnCommand}; echo ${strSpawnCommand}; \
${strSpawnCommand}; \
\"" #this way, it creates a reusable log to quickly place all NPCs again!!! OBS.: getpos 2 times is because the engine bugs and may not print one character some times
	echo "alias -gsk${lstrType}Spawn_${liCurrentIndex} \"\
ent_setname gskSpawnNameOk; \
\"" #it is important to wait the spawn happen before assigning a name to it
}

: ${strExecEdit:=geany} #help
: ${bAutoFixMissingChars:=true} #help the engine may not print all charaters in a line, so usually repeating the command will provide a 2nd line with the missing char

function FUNCchkSpawnHintData() {
	local lstrSpawnHintDataKeyRef="echo gskSpawnHint; gskTargetPos;gskTargetPos; getpos;getpos; " #this was the last sync alias value
	local lstrSpawnHintDataKeyCheck="$(egrep "^alias\s*gskSpawnHintData\s+" "${strPathMainModFolder}/_mods/000gskBaseLib/content/cfg/gskBaseLib.cfg" |sed -r -e 's@.*\"(echo gskSpawnHint.*)\".*@\1@g')"
	if [[ "$lstrSpawnHintDataKeyRef" != "$lstrSpawnHintDataKeyCheck" ]];then
		declare -p lstrSpawnHintDataKeyRef lstrSpawnHintDataKeyCheck
		FUNCexit 1 "gskSpawnHintData is not in sync. update lstrSpawnHintDataKeyRef and the code support here."
	fi
}


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
	FUNCchkCfgScriptLineSz "$1"
#	echo "$1" |tee -a "$strMapCfgFile"
	echo "$1" >>"$strMapCfgFile"
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
		shift;lstrMapAndSector="${1}"
		lstrMapAndSector="${lstrMapAndSector#gskmap_}"
		lstrMapAndSector="${lstrMapAndSector%.cfg}"
		lstrUseThisMap="$(     echo "$lstrMapAndSector" |sed -r -e 's@(.*)-(.*)@\1@g')"
		if [[ "$lstrMapAndSector" =~ .*[-].* ]];then
			lstrUseThisSector="$(echo "$lstrMapAndSector" |sed -r -e 's@(.*)-(.*)@\2@g')"
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

if [[ -n "$lstrUseThisSector" ]] && [[ "$lstrUseThisSector" =~ .*[.].* ]];then
	FUNCexit 1 "invalid sector, put no dots on it: '$lstrUseThisSector'"
fi

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
	
#help @InfoID="Log flood Issue workaround" having to save many condumps and merge them (as they have a size limit) due to flooded unstoppable warn log messages, after merging them all there may happen several dup spawns, use this (it will turn all multine entry into a single line, sort it unique and restore it into multiline) ex.: egrep "^(gskSpawnHint|setpos|[+]*gskSummon|dummy|gskmsg)" condumpMerged.txt |sed -r -e 's@(gskSpawnHint).*@\1 @g' |tr -d '\n' |sed -r -e 's@gskSpawnHint@\n&@g'|sort -u |sed -r -e 's@setpos@\nsetpos@g' -e 's@mm_npc@\nmm_npc@g' -e 's@([+]*gskSummon)@\n\1@g' |sed -r -e 's@(.*)(Set the name of .*)$@\1@g' -e 's@(.*)(Unknown command: .*)$@\1@g' >condumpClean.txt; egrep "^map " condumpMerged.txt >>condumpClean.txt #Tho the best way is to just find a previous save where there is no flood on the log (as I couldnt determine the cause of the problem).
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

function FUNCspawnFlags() { #help based on https://developer.valvesoftware.com/wiki/Npc_ministrider#Flags
	local lnFlags=0
	local lastrFlags=(FS_AIonAfterSeen FS_FALL FS_QUIET "${@-}")
	#while [[ $# -gt 0 ]];do
	for lstrFlagAdd in "${lastrFlags[@]}";do
		if [[ -z "$lstrFlagAdd" ]];then continue;fi
		case "$lstrFlagAdd" in # Flag Spawn (flags for spawning)
			FS_AIonAfterSeen) ((lnFlags+=1))&&: ;; # wont detect player if player dont see it? May be good to create enemies with each other that will only fight after we see them! May also easy on CPU?
			FS_QUIET) ((lnFlags+=2))&&: ;; #initially quiet until in rage, excellent for surprises
			FS_FALL) ((lnFlags+=4))&&: ;; #initially fall instead of teleport to ground
			FS_DropHealing) ((lnFlags+=8))&&: ;; #on death
			FS_LongRangeView) ((lnFlags+=256))&&: ;;
			FS_TANK) ((lnFlags+=16384))&&: ;; #cant be pushed
			*) FUNCexit 1 "invalid spawnflag '$lstrFlagAdd'";;
		esac
		#shift
	done
	echo "$lnFlags"
	return 0
}

function FUNCsectionID() {
	echo "gskSpawn_${lstrUseThisSector}_$(printf %03d ${1})" #Spawner Section Begin At Target
}

: ${nSpawnTriggerLinkedLimit:=16} #help :(
function FUNCappendToSpawnTrigger() {
	if [[ -z "${strSpawnTriggerLine}" ]];then return 0;fi
	
	local lbCreateNewSection=true
	local liTargetIndex=0
	
	local lstrSTRegex="^gskSpawnTriggerID\s*([0-9]*)\s*([a-zA-Z0-9_-]*)\s*(.*)"
	local lstrLogicRelayID="$(         echo "$strSpawnTriggerLine" |sed -r -e "s@${lstrSTRegex}@\1@g")"
	local lstrLogicRelayOnTrigger="$(  echo "$strSpawnTriggerLine" |sed -r -e "s@${lstrSTRegex}@\2@g")"
	local lstrLogicRelaySpawnParams="$(echo "$strSpawnTriggerLine" |sed -r -e "s@${lstrSTRegex}@\3@g")"
	local lnSTTemplateBeginIndex=0
	
	local lstrSTSectionID="$(FUNCsectionID ${liTargetIndex})"
	local lnSTTemplateBeginSection=0
	
	while true;do
		#if((lnSTTemplateBeginSection>0));then
		if $lbCreateNewSection;then
			#help KEEPINFO: "OnStartTouch" should be nested inside "connections" (like: ```... "connections" { "OnStartTouch" ...```), but it seems  that everything starting with "On" automatically goes into "connections" so no need to provide the nesting here!
			echo '
		"modify:entity"
		{
			"TargetMarkers"
			{
				"id"	"'"${lstrLogicRelayID}"'"
			}
			"add:key"
			{
				"'"${lstrLogicRelayOnTrigger}"'" "'"${lstrSTSectionID}${lstrLogicRelaySpawnParams}"'"
			}
		}
		' >>"${strFlMapadds}"
		
			echo '
		"add:entity"
		{
			"classname" "point_template"
			"combinability" "1"
			"spawnflags" "2"
			"targetname" "'"${lstrSTSectionID}"'"
			"origin" "0 0 0"
		}' >>"${strFlMapadds}"
			#lstrSpawnTriggerID="${lstrSTSectionID}"
			lnSTTemplateBeginIndex=1
			
			lbCreateNewSection=false
		#else
			#lstrSpawnTriggerID="${strSpawnTriggerID}"
			##lnSTTemplateBeginIndex=$nSpawnTriggerTemplateBeginIndex
		fi
		
		echo '
		"modify:entity"
		{
			"TargetMarkers"
			{
				"targetname"	"'"${lstrSTSectionID}"'"
			}
			"add:key"
			{
		' >>"${strFlMapadds}"
		
		#local li
		local lstrTargetName
		local lnSTTemplateIndex=$lnSTTemplateBeginIndex
		while true;do
			#for((li=lnSTTemplateBeginSection;li<${#astrTriggeredSpawnerTargetNameList[@]};li++));do
			if((liTargetIndex == ${#astrTriggeredSpawnerTargetNameList[@]}));then break;fi
			
			#local lnIndex=$((lnSTTemplateBeginIndex+li))
			#local lnIndex=$lnSTTemplateIndex
			#if((lnIndex>nSpawnTriggerLinkedLimit));then FUNCechoInfo "[WARN] lnIndex=$lnIndex > $nSpawnTriggerLinkedLimit";fi
			if((lnSTTemplateIndex==nSpawnTriggerLinkedLimit));then #not greater than limit because the last slot will be used to link the next section
				#lnSTTemplateBeginSection=$lnSTTemplateIndex
				#lstrSTSectionID="gskSpawnerSectionBegin${lnSTTemplateBeginSection}"
				#lstrSTSectionID="gskSpawn_${lstrUseThisSector}_$(printf %03d ${liTargetIndex})" #Spawner Section Begin At Target
				lstrSTSectionID="$(FUNCsectionID ${liTargetIndex})"
				lstrTargetName="$lstrSTSectionID"
				lbCreateNewSection=true
			else
				lstrTargetName="${astrTriggeredSpawnerTargetNameList[$liTargetIndex]}"
				((liTargetIndex++))&&:
			fi
			
			echo '
				"Template'"$(printf %02d $lnSTTemplateIndex)"'" "'"${lstrTargetName}"'"' >>"${strFlMapadds}"
			
			if $lbCreateNewSection;then break;fi
			
			((lnSTTemplateIndex++))&&:
		done
		
		echo '
			}
		}' >>"${strFlMapadds}"
		
		if ! $lbCreateNewSection;then break;fi
	done
}

astrTriggeredSpawnerTargetNameList=()

function FUNCentityName() {
	echo "gskSpawn_${lstrUseThisSector}_${strCount}"
}

function FUNCmapadds() {
	local lstrSummonCmd="$1"
	
	#((anTargetPosXYZ[z]+=1))&&: #height (this fix is needed?)
	anTargetPosXYZ[z]="$(bc <<< "${anTargetPosXYZ[z]}+1")" #height (this fix is needed?)
	
	((anTargetAngXYZ[y]+=180))&&: #rotation look at dir, inverse of where player is looking at when spawned it 
	if((anTargetAngXYZ[y]>180));then anTargetAngXYZ[y]=$((${anTargetAngXYZ[y]}-360));fi
	
	local lstrFlAddTmp="$(mktemp)"
	
	local lstrTargetName="$(FUNCentityName)"
	
	echo '
		"add:entity"
		{
			"targetname"  "'"${lstrTargetName}"'"
			"origin"      "'"${anTargetPosXYZ[x]} ${anTargetPosXYZ[y]} ${anTargetPosXYZ[z]}"'"
			"angles"      "'"${anTargetAngXYZ[x]} ${anTargetAngXYZ[y]} ${anTargetAngXYZ[z]}"'"
			"spawnflags"  "'"$(FUNCspawnFlags)"'"
			"physdamagescale" "1.0"
			"radiusforrandomattitude" "500"
' >>"$lstrFlAddTmp"

	local lbCommentOut=false
	local lnHeightDisplacement=0
	local lstrIgnore=""
	case "$lstrSummonCmd" in
		"+gskSummonGuard")
			echo '
			"classname"   "npc_human_guard"
			"model" "models/npc/guard/npc_guard.mdl"
			"additionalequipment" "weapon_arx_short_sword"
			"spawnflags"  "'"$(FUNCspawnFlags FS_LongRangeView)"'"' >>"$lstrFlAddTmp"
			;; 
		"+gskSummonGuardMini")
			lnHeightDisplacement=5
			echo '
			"classname"   "npc_human_guard"
			"model" "models/npc/guard/npc_guard_shrinked.mdl"
			"spawnflags"  "'"$(FUNCspawnFlags FS_LongRangeView)"'"' >>"$lstrFlAddTmp"
			;; 
		"+gskSummonGuardBow")
			echo '
			"classname"   "npc_human_guard_bow"
			"model" "models/npc/guard/npc_guard.mdl"
			"additionalequipment" "weapon_arx_short_sword"
			"QuiverAmmo" "8"
			"rangeweapon" "weapon_arxcrossbow"
			"QuiverModel" "models/items/weapons/Quiver_guard/quiver_guard.mdl"
			"spawnflags"  "'"$(FUNCspawnFlags FS_LongRangeView)"'"' >>"$lstrFlAddTmp"
			;; 
		"+gskSummonGuardShield")
			echo '
			"classname"   "npc_human_guard_bow"
			"model" "models/npc/guard/npc_guard.mdl"
			"additionalequipment" "weapon_arx_short_sword"
			"QuiverAmmo" "8"
			"rangeweapon" "weapon_arxcrossbow"
			"QuiverModel" "models/items/weapons/Quiver_guard/quiver_guard.mdl"
			"spawnflags"  "'"$(FUNCspawnFlags FS_DropHealing FS_LongRangeView)"'"' >>"$lstrFlAddTmp"
			;; 
		mm_npc_create_necro_guard_bow|"gskSummonNecroGuardBow")
			echo '
			"classname"   "npc_necro_guard_bow"
			"model" "models/npc/Necroguard/npc_necroguard.mdl"
			"additionalequipment" "weapon_arx_short_sword"
			"QuiverAmmo" "12"
			"rangeweapon" "weapon_arxcrossbow"
			"QuiverModel" "models/items/weapons/Quiver_guard/quiver_guard.mdl"
			"spawnflags"  "'"$(FUNCspawnFlags FS_LongRangeView)"'"' >>"$lstrFlAddTmp"
			;; 
		mm_npc_create_necro_guard_shield|"gskSummonNecroGuardShield")
			echo '
			"classname"   "npc_necro_guard"
			"model" "models/npc/Necroguard/npc_necroguard.mdl"
			"additionalequipment"	"weapon_arx_short_sword"
			"additionalshield" "weapon_mm_shield_necroguard"
			"spawnflags"  "'"$(FUNCspawnFlags FS_DropHealing FS_LongRangeView)"'"' >>"$lstrFlAddTmp"
			;;
		mm_npc_create_necromancer|"gskSummonNecromancer")
			echo '
			"classname" "npc_necromancer_lord"
			"model" "models/NPC/Necromancer/Npc_necromancer.mdl"
			"additionalequipment" "weapon_mm_staff_combat"
			"spawnflags"  "'"$(FUNCspawnFlags FS_DropHealing FS_LongRangeView)"'"' >>"$lstrFlAddTmp"
			;;
		mm_npc_create_necromancer_lord|"+gskSummonNecromancerLord")
			echo '
			"classname" "npc_necromancer_lord"
			"model" "models/NPC/necromancer_lord/npc_necromancer_lord.mdl"
			"additionalequipment" "weapon_mm_hook"
			"spawnflags"  "'"$(FUNCspawnFlags FS_DropHealing FS_LongRangeView)"'"' >>"$lstrFlAddTmp"
			#"weaponmodel" "models/Items/Weapons/hook/hook.mdl"
			;;
		mm_npc_create_undead|gskSummonUndead)
			echo '
			"classname" "npc_undead"
			"model" "models/NPC/Undead/Npc_undead.mdl"
			"spawnflags" "16384"
			"SmellRadius" "300"
			"spawnflags"  "'"$(FUNCspawnFlags FS_TANK)"'"' >>"$lstrFlAddTmp"
			if((iSpawnCount%3 <= 1));then # bury 66% of the configured to spawn
				echo '
			"UnburrowRadius" "200"
			"UnburrowChanceOverride" "1.0"' >>"$lstrFlAddTmp"
			fi
			;;
		"gskSummonSpiderRegular")
			lnHeightDisplacement=7
			echo '
			"classname" "npc_spider_regular"
			"model" "models/NPC/Spider_Regular/Npc_Spider_Regular.mdl"
			"spawnflags"  "'"$(FUNCspawnFlags)"'"' >>"$lstrFlAddTmp"
			;;
		"gskSummonSpiderMini")
			lnHeightDisplacement=5
			echo '
			"classname" "npc_spider_mini"
			"model" "models/NPC/spider_mini/Npc_spider_mini.mdl"
			"spawnflags"  "'"$(FUNCspawnFlags)"'"' >>"$lstrFlAddTmp"
			;;
		"gskSummonPotionMana")
			lnHeightDisplacement=5
			echo '
			"classname" "item_potion_mana"
			"model" "models/items/provisions/potions/Mana_potion.mdl"
			"spawnflags"  "'"$(FUNCspawnFlags)"'"' >>"$lstrFlAddTmp"
			;;
		"gskSummonPotionLife")
			lnHeightDisplacement=5
			echo '
			"classname" "item_potion_life"
			"model" "models/items/provisions/potions/Life_potion.mdl"
			"spawnflags"  "'"$(FUNCspawnFlags)"'"' >>"$lstrFlAddTmp"
			;;
		"gskSummonSword") # is bugging, not spawning correctly, unequipable
			lstrIgnore="UnnecessaryAsPlayerCanSummon"
			lnHeightDisplacement=10
			echo '
			"classname" "prop_physics"
			"model" "models/Items/Weapons/Sword_short/Sword_short.mdl"
			"spawnflags"  "'"$(FUNCspawnFlags)"'"' >>"$lstrFlAddTmp"
			;;
		"gskSummonStaff") # is bugging, not spawning correctly, unequipable
			lstrIgnore="UnnecessaryAsPlayerCanSummon"
			lnHeightDisplacement=10
			echo '
			"classname" "prop_physics"
			"model" "models/Items/Weapons/staff_wood/staff_wood.mdl"
			"spawnflags"  "'"$(FUNCspawnFlags)"'"' >>"$lstrFlAddTmp"
			;;
		"gskSummonClub") # is bugging, not spawning correctly, unequipable
			lstrIgnore="UnnecessaryAsPlayerCanSummon"
			lnHeightDisplacement=10
			echo '
			"classname" "prop_physics"
			"model" "models/Items/Weapons/Club/Club.mdl"
			"spawnflags"  "'"$(FUNCspawnFlags)"'"' >>"$lstrFlAddTmp"
			;;
		"gskSkillPointAdd") #TODO doesnt work....
			#"targetname" "'"${lstrTargetName}"'_gskGive1SkillPoint"
			echo '
			"classname" "npc_spider_mini"
			"model" "models/NPC/spider_mini/Npc_spider_mini.mdl"
			"connections"
			{
				"OnDeath" "mm_player_inputs,GiveSkillPoints,1,0,1,1,gskmap"
			}
			"spawnflags"  "'"$(FUNCspawnFlags)"'"' >>"$lstrFlAddTmp"
			;;
		"gskSummonCoin")
			echo '
			"classname" "prop_physics"
			"model" "models/items/jewels/money/money02.mdl"
			' >>"$lstrFlAddTmp"
			;;
		"gskSummonCrow")
			echo '
			"classname" "npc_crow"
			"model" "models/npc/crow/npc_crow.mdl"
			' >>"$lstrFlAddTmp"
			;;
		"gskSummonSeagull")
			echo '
			"classname" "npc_seagull"
			"model" "models/npc/seagull/npc_seagull.mdl"
			' >>"$lstrFlAddTmp"
			;;
		"gskSummonPig")
			echo '
			"classname" "npc_pig"
			"model" "models/npc/pig/pig.mdl"
			' >>"$lstrFlAddTmp"
			;;
		*)
			lbCommentOut=true
			echo '
			"targetname"   "'"${lstrTargetName}"'_TODO_FixMissingSupportFor_'"${lstrSummonCmd}"'"' >>"$lstrFlAddTmp"
			;;
	esac
	
	if((lnHeightDisplacement!=0));then
		anTargetPosXYZ[z]="$(bc <<< "${anTargetPosXYZ[z]}+${lnHeightDisplacement}")"
		echo '
			"origin"      "'"${anTargetPosXYZ[x]} ${anTargetPosXYZ[y]} ${anTargetPosXYZ[z]}"'"' >>"$lstrFlAddTmp"
	fi
	
	if [[ -n "$lstrIgnore" ]];then
		echo '
			"targetname"  "IGNORED_'"${lstrIgnore}"'"' >>"$lstrFlAddTmp"
		lbCommentOut=true
	fi
	
	echo '
		}
' >>"$lstrFlAddTmp"
	
	if $lbCommentOut;then
		cat "$lstrFlAddTmp" \
			|egrep -v "^$" \
			|sed -r -e 's@.*@//&@g' \
			>>"${strFlMapadds}"
	else # success
		cat "$lstrFlAddTmp" \
			|egrep -v "^$" \
			>>"${strFlMapadds}"
		if [[ -n "${strSpawnTriggerLine}" ]];then
			astrTriggeredSpawnerTargetNameList+=("$lstrTargetName")
		fi
	fi
	
	rm "$lstrFlAddTmp"
}

if $bCreateSpawnsForCurrentMap;then
	if [[ -n "$lstrUseThisMap" ]];then # this comes from the specified params options like -M
		# rework using a (probably) carefully edited CLEAN file
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
	
	strMapCfgFile="$(FUNCmapCfg "${FUNCmapInfo_strMapName}" "${lstrUseThisSector}")"
	#if $bUpdateCondumpBkp || [[ ! -f "${strMapCfgFile}.condump.txt" ]];then
	if [[ -f "${strMapCfgFile}.condump.txt" ]];then
		cp -v "${strMapCfgFile}.condump.txt" "${strMapCfgFile}.condump.txt.$(FUNCdtFlNm).bkp"
	fi
	if ! cmp "$strFlCondump" "${strMapCfgFile}.condump.txt";then
		cp -vf "$strFlCondump" "${strMapCfgFile}.condump.txt"
	fi

	mkdir -vp "../mapadds/${FUNCmapInfo_strMapName}"
	strFlMapadds="../mapadds/${FUNCmapInfo_strMapName}/${strMapCfgFile}.MapAdds.txt"
	echo -n >"$strFlMapadds"
	echo '
"mapadd_keyvalues"
{
	"PreInitialize"
	{	
' >>"$strFlMapadds"
	
	# clean condump file is good for git
	strFlCondumpCleanNew="${strMapCfgFile}.condump_CLEAN.txt.NEW.txt"
	strFlCondumpClean="${strMapCfgFile}.condump_CLEAN.txt"
	if [[ "$strFlCondump" == "$strFlCondumpClean" ]];then
		strUseThisCondump="${strFlCondumpClean}.TMP.txt"
		cp -vf "$strFlCondumpClean" "${strUseThisCondump}"&&:
		strFlCondump="$strUseThisCondump"
	fi
	#if ! $bUsingCleanCondump;then
		#strMapMessages="$(egrep "(gskMapMessage|gskmsg)\ .*" "$strFlCondumpClean")"
		cp -vf "$strFlCondumpClean" "$strFlCondumpClean.$(FUNCdtFlNm).bkp"&&:
		echo "$FUNCmapInfo_strMapStatus" >"$strFlCondumpCleanNew" #trunc/init
		echo "$FUNCmapInfo_strMapStatus" >>"$strFlCondumpCleanNew"
		#echo "$strMapMessages" >>"$strFlCondumpCleanNew"
	#fi
	FUNCprepareCleanDataOriginBkp() {
		#if $bUsingCleanCondump;then return 0;fi
		local j
		for((j=0;j<iTotEntryDataLines;j++));do
			local lstrLine="${astrAllLines[$((iLnDataIni+j))]}"
			local lstrExtra=""
			if [[ "$lstrLine" =~ ^gskSpawnHint.* ]];then 
				lstrExtra="  // ( $((iSpawnCount+1))/${nTotSpawns} )";
			fi
			lstrLine="$(echo "${lstrLine}" |sed -r -e 's@(^gskSpawnHint[^ ]*).*@\1@g')"
			echo "${lstrLine} ${lstrExtra}" >>"$strFlCondumpCleanNew"
		done
	}
	#bUsingCleanCondump=false;if [[ "$strFlCondump" == "$strFlCondumpClean" ]];then bUsingCleanCondump=true;fi
	#if ! $bUsingCleanCondump;then
		#cp -vf "$strFlCondumpClean" "$strFlCondumpClean.$(FUNCdtFlNm).bkp"&&:
		#echo "$FUNCmapInfo_strMapStatus" >"$strFlCondumpCleanNew"
		#echo "$FUNCmapInfo_strMapStatus" >>"$strFlCondumpCleanNew"
	#fi
	#FUNCprepareCleanDataOriginBkp() {
		#if $bUsingCleanCondump;then return 0;fi
		#for((j=0;j<iTotEntryDataLines;j++));do
			#local lstrLine="${astrAllLines[$((iLnDataIni+j))]}"
			#local lstrExtra="";if [[ "$lstrLine" =~ ^gskSpawnHint.* ]];then lstrExtra="  // ( $((iSpawnCount+1))/${nTotSpawns} )";fi
			#echo "${lstrLine}${lstrExtra}" >>"$strFlCondumpCleanNew"
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
	strCmdsErasers="gskManaRegEraser; gskHMHurtmeEraser1of3; gskHMHurtmeEraser2of3; gskHMHurtmeEraser3of3; alias gskSmnWORK gskSmnWORKmoreFoes; alias gskSpawnHintDataErasable echo ErasedHintData" #erasers are  to avoid messing the player HP and Mana pools and remove effects that slowdown things like placing more foes at least
	#strCmdsON=" gskEchoOn; +duck; gskDevGodModeToggles; gskEffect100; ${strCmdsErasers}; alias gskWaitInteractDev gskWait333ms; " # do not use host_timescale 0.01 as it will mess teleporting. +duck is to help to fit yourself in smaller places causing less issues
	strCmdsON=" gskEchoOn; +duck; gskDevGodModeToggles; gskEffect100; status;status; ${strCmdsErasers}; " # do not use host_timescale 0.01 as it will mess teleporting. +duck is to help to fit yourself in smaller places causing less issues. map data is to help on recreating the file with new lines of data later
	strCmdsOFF=" -duck; gskDevGodModeToggles; gskEffectOFF; gskEchoOff; +gskReloadCfgs " # +gskReloadCfgs is to restore what was erased
	FUNCechoAndFillFile "alias +gskCCnpcSpawn_next \"${strCmdsON}; +gskCCnpcSpawn_$( printf %03d $((iSpawnCount)) )\"" # initializes with some dev toggles
	FUNCechoAndFillFile "alias gskSndSpawned \"play arkane/fix_inter/book_close.wav\""
	#for((i=0;i<${#astrSpawnHintList[@]};i+=iDataLines));do
	astrFinalMessages=()
	strFinalMessages=""
	
	#help @InfoID="Map final messages" put this on the condump ex.: gskMapMessage Your message...
	mapfile -t astrFinalMessages < <(egrep "(gskMapMessage|gskmsg)\ .*" "$strFlCondump" |sed -r -e 's@.*(gskMapMessage|gskmsg) (.*)@\2@g')
	for((iMsg=0;iMsg<${#astrFinalMessages[@]};iMsg++));do
		if ! FUNCvalidateConsoleEchoMsg "${astrFinalMessages[$iMsg]}";then
			FUNCexit 1
		fi
		strFinalMessages+="echo ${astrFinalMessages[$iMsg]}; "
		echo "gskMapMessage ${astrFinalMessages[$iMsg]}" >>"$strFlCondumpCleanNew"
	done
	
	#help @InfoID="Use existing spawn trigger" put this on the condump ex. for L02_B1: gskSpawnTriggerID tim_spwaner (then in the line below put this ex.: gskSpawnTriggerBeginIndex 2) #TODO may be seek other mods for mapadd files looking for last Template[0-9]* to start from, also look at .vmf file but not everyone may have the hammer sdk installed...
	strSpawnTriggerLine=""
	if egrep "^gskSpawnTriggerID" "$strFlCondump";then
		strSpawnTriggerLine="$(egrep "^gskSpawnTriggerID" "$strFlCondump")"
		#strSpawnTriggerID="$(      egrep "^gskSpawnTriggerID"         "$strFlCondump" |awk '{print $2}')"
		#nSpawnTriggerTemplateBeginIndex="$(egrep "gskSpawnTriggerBeginIndex" "$strFlCondump" |awk '{print $2}')"
		echo "${strSpawnTriggerLine}" >>"$strFlCondumpCleanNew"
		#echo "gskSpawnTriggerBeginIndex $nSpawnTriggerTemplateBeginIndex" >>"$strFlCondumpCleanNew"
	fi
	
	#: ${bCollectTargetPos:=true} #help temporary to update with old files
	bCollectTargetPos=true
	if ! egrep -q "prop at .* missing modelname" "$strFlCondump";then bCollectTargetPos=false;fi
	iTotEntryDataLines=7
	if ! $bCollectTargetPos;then ((iTotEntryDataLines-=2))&&:;fi
	
	for((i=0;i<${#astrAllLines[@]};i++));do
		#set -x
		strMODE=SpawnNPC
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
			
			function FUNCeditCondumpAtLn() {
				FUNCechoInfo "[ERROR:invalidPOS] ( the engine sometimes do not print some letters!!! :O ), FailFixBiggestLineConflictFor: $1"
				"$strExecEdit" "$strFlCondump:$((iLnData+1))"
				FUNCexit 1 "you need to re-run the script"
			}
			
			if $bCollectTargetPos;then
				((iLnData++))&&:;strTargetPos="${astrAllLines[$iLnData]}"
				((iLnData++))&&:;strTargetPosChk="${astrAllLines[$iLnData]}" #as engine may not print one char! :O
				if ! strTargetPos="$(FUNCreturnBiggestLinePipe "$strTargetPos" "$strTargetPosChk")";then FUNCeditCondumpAtLn "TargetPos";fi
			fi
			
			((iLnData++))&&:;strSelfPosAngleCmd="${astrAllLines[$iLnData]}"
			((iLnData++))&&:;strSelfPosAngleCmdChk="${astrAllLines[$iLnData]}" #as engine may not print one char! :O
			if ! strSelfPosAngleCmd="$(FUNCreturnBiggestLinePipe "$strSelfPosAngleCmd" "$strSelfPosAngleCmdChk")";then FUNCeditCondumpAtLn "SelfPosAngle";fi
			strSelfPosAngleCmd="$(FUNCposAngAsCmd "$strSelfPosAngleCmd")"
			strSelfPosAngleCmdFixed="$(FUNCfixPosAng "${strSelfPosAngleCmd}")"

			bInteractUseMode=false
			strAliasValue=""
			strAliasValue+="alias gskPosR $(echo "${strSelfPosAngleCmdFixed}" |sed -r -e 's@(.*);(.*)@\1@g'); "
			strAliasValue+="alias gskAngR $(echo "${strSelfPosAngleCmdFixed}" |sed -r -e 's@(.*);(.*)@\2@g'); "
			strAliasValue+="gskPosR;gskAngR;gskWait333ms; gskPosR;gskAngR;gskWait333ms; gskPosR;gskAngR;gskWait333ms; " # it is repeated a few times with a small delay because the engine does not teleport the player, it interpolates like a super fast fly!!! right? also, if there is acceleration before teleporting, that acceleration remains after teleporting causing a displacement right?
			strAliasValueLift=""
			strAliasInfo=""
			strAliasInfo+="echo Spawning:${strCountShow}/${nTotSpawns} >>> $( crc32 <(echo "$(FUNCposAngAsCmd "$strSelfPosAngleCmd" |tr -d ' ')") ) <<<; " #help @InfoID="DetectMissingSpawnings" grep "DetectMissingSpawnings" thisScript.sh
			#help DetectMissingSpawnings how to use ex.: colordiff <(egrep ">>> [^ ]* <<<" -io "gskmap_L00.cfg"|sort) <(egrep ">>> [^ ]* <<<" -io "gskmap_L00-01_NewToReplace.cfg"|sort) #where 01_NewToReplace was generated from a new fresh condump
			strAliasInfo+="echo PosAng Asked=[$(FUNCposAngAsEchoShort "$strSelfPosAngleCmd")]; " # asked when creting while flying as god and from that condump
			strAliasInfo+="echo PosAng Fixed=[$(FUNCposAngAsEchoShort "$strSelfPosAngleCmdFixed")]; " # expectedly fixed because the engine has that discrepance when restoring pos/ang
			bSetName=true
			case "$strMODE" in
				SpawnNPC)
					((iLnData++))&&:;strSpawnCommand="$(    echo "${astrAllLines[$iLnData]}" |awk '{print $1}')"
					((iLnData++))&&:;strSpawnCommandChk="$( echo "${astrAllLines[$iLnData]}" |awk '{print $1}')"
					if ! strSpawnCommand="$(FUNCreturnBiggestLinePipe "$strSpawnCommand" "$strSpawnCommandChk")";then FUNCeditCondumpAtLn "SpawnCommand";fi
					#if [[ "$strNPC" != "$strNPCchk" ]];then
						#if $bAutoFixMissingChars;then
							#if((${#strNPCchk} > ${#strNPC}));then
								#strNPC="$strNPCchk"
							#fi
						#fi
					#fi
					
					if [[ "$strSpawnCommand" == "+gskInteractUseMoreFoes" ]];then
						bSetName=false;
						#strAliasValue+="mm_host_timescale 10; gskWait333ms; "
					elif [[ "$strSpawnCommand" =~ ^dummy.* ]];then #help it usually comes with a hint like dummyJustTeleportHere
						bSetName=false;
					elif [[ "$strSpawnCommand" == "gskSkillPointAdd" ]];then
						bSetName=false;
					else
						FUNCvalidateNPC "$strSpawnCommand" "$strFlCondump" "$iLnData"
					fi
					#strAliasInfo+=":${strSpawnCommand#mm_npc_create_}; "
					strAliasValue+="${strAliasInfo}; "
					: ${bDumpCurrentPosAng:=false} #help dumping the existing configured pos/ang is much more consistent as the game engine provides modified pos/ang after setpos setang when you getpos :(
					if $bDumpCurrentPosAng;then
						strAliasValue+="gskSpawnHintData; "
					else
						strPosAngEcho="echo $(FUNCposAngAsEcho "$strSelfPosAngleCmd")" #must be the collected from clean dump file (not the fixed pos/ang)
						FUNCchkSpawnHintData \
						               "echo gskSpawnHint; gskTargetPos;gskTargetPos; getpos;getpos; " #DO NOT EDIT THIS PARAM, IT MUST BE IN SYNC!
						strAliasValue+="echo gskSpawnHint; gskTargetPos;gskTargetPos; ${strPosAngEcho};${strPosAngEcho}; "
					fi
					# Keep strSpawnCommand as last important detected line of command data (anything after it may deprecate or be temporary).
					strAliasValue+="echo ${strSpawnCommand};echo ${strSpawnCommand}; ${strSpawnCommand}; getpos;getpos; gskSndSpawned; echo FinishedSpawning:${strCountShow} <<<>>>; " # it is important to wait a bit after the real command otherwise it may teleport and execute 2 or more commands elsewhere. TODO getpos here is to compare with the original and try to provide a better restore positioning one day. It is after the last important line strSpawnCommand but may be reused automatically temporarily.
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
				FUNCechoAndFillFile "alias -gskCCnpcSpawn_${strCount} \"ent_setname $(FUNCentityName); ${strAliasValueLift}; \""
			else
				FUNCechoAndFillFile "alias -gskCCnpcSpawn_${strCount} \"\""
			fi
			
			if $bCollectTargetPos;then
				declare -gA anTargetPosXYZ="$(FUNCxyzArray "$(echo "$strTargetPos" |sed -r -e 's@.*prop at (.*) missing modelname.*@\1@g')")"
				declare -gA anTargetAngXYZ="$(FUNCxyzArray --integer "$(echo "$strSelfPosAngleCmd" |tr -d '\r' |sed -r -e 's@.*setang (.*)@\1@g')")"
				FUNCmapadds "$strSpawnCommand"
			fi
			
			echo "${strCountShow}/${nTotSpawns}: $strSpawnCommand" #progress
			
			((iSpawnCount++))&&:
			
			if(( iTotEntryDataLines != (iLnData - iLnDataIni + 1) ));then
				FUNCechoInfo "[ERROR:DEV] invalid iTotEntryDataLines=$iTotEntryDataLines iLnData=$iLnData iLnDataIni=$iLnDataIni"
				exit 1
			fi
			i=$iLnData # jump skip, next loop will be +1
		fi
	done
	
	FUNCappendToSpawnTrigger
	echo '
	}
}
' >>"$strFlMapadds"
	
	#FUNCechoAndFillFile "alias +gskCCnpcSpawn_${strCountNext} \"echo FinishedSpawnings; gskSndDONE; ${strRestorePosInTheEnd}; ${strCmdsOFF}; -gskInteractUseDev; alias gskCCnpcSpawn_next +gskCCnpcSpawn_Finished; \"" #this also prevents continuing thru some previous list entries of a previous test run or map may be. -gskInteractUseDev is to grant next +gskInteractUseDev wont break.
	FUNCechoAndFillFile "alias +gskCCnpcSpawn_${strCountNext} \"echo FinishedSpawnings; gskSndDONE; ${strRestorePosInTheEnd}; ${strCmdsOFF}; alias +gskCCnpcSpawn_next +gskCCnpcSpawn_Finished; alias -gskCCnpcSpawn_next -gskCCnpcSpawn_Finished; save gskFinishedSpawnings_${FUNCmapInfo_strMapName}; condump; pause; \"" # using finish alias also prevents continuing thru some previous list entries of a previous test run or map may be.
	FUNCechoAndFillFile "alias -gskCCnpcSpawn_${strCountNext} \"\""
	FUNCechoAndFillFile "alias +gskCCnpcSpawn_Finished \"gskEchoOn; ${strFinalMessages}; echo Finished Spawnings Already for this map $FUNCmapInfo_strMapName\""
	FUNCechoAndFillFile "alias -gskCCnpcSpawn_Finished \"gskEchoOff\""
	FUNCechoAndFillFile "clear" # before beggining each spawning, this is good
	FUNCechoAndFillFile "echo \"DO THESE NOW PLEASE!!! (super important to avoid toggles getting unsynchronized)\""
	FUNCechoAndFillFile "echo \"All below is to confirm you are in a normal gameplay mode, (each command you can double click, Ctrl+C, TAB, Ctrl+V, and run 1 or 2 times to be sure they are correct ). So you need to be sure:\""
	FUNCechoAndFillFile "echo \"                                    COMMAND\""
	FUNCechoAndFillFile "echo \" Be sure You are standing:          -duck\""
	FUNCechoAndFillFile "echo \" Be sure You cannot fly (OFF):      NoClip\""
	FUNCechoAndFillFile "echo \" Be sure Foes can detect you (OFF): NoTarget\""
	FUNCechoAndFillFile "echo \" Be sure AI is (Enabled):           AI_Disable\""
	FUNCechoAndFillFile "echo \" Be sure You are not immune (OFF):  Buddha\""
	FUNCechoAndFillFile "echo \"A simple way is:\""
	FUNCechoAndFillFile "echo \" - Stand up (as will auto crouch to help fit and positioning).\""
	FUNCechoAndFillFile "echo \" - Enable and disable gskDevGodModeToggles and read the final status for each power, just to be sure all toggles are reset (as unfortunately we can't set them (right?)... only toggle... or NPC deployment may go out of control).\""
	FUNCechoAndFillFile "echo \" - Close the console. While you can bind +gskCCnpcSpawn_next to a key like F4 (that will work with the console opened), it will not work when releasing the key to execute -gskCCnpcSpawn_next.\""
	FUNCechoAndFillFile "echo \" - Hide your weapon (optional).\""
	FUNCechoAndFillFile "echo \"Now, repeatedly press the key to spawn the next NPC: +gskCCnpcSpawn_next, but WAIT for the finished spawn sound or it will BUG(spawns 2 or more in a single location)!!!\""
	FUNCechoAndFillFile "echo \"You will be in developer mode and carefully teleported to the location and rotation required for the spawning and without triggering anything.\""
	FUNCechoAndFillFile "echo \"Obs.: your vision is blurred to the spawn and location be a surprise.\"" #TODO fadeout to completely hide spawnings? will make it impossible to detect issues tho.
	
	if egrep "^Unknown command: rm[0-9]*" -i "${strMapCfgFile}.condump.txt";then #help just type rm1 rm3 etc, will not be recognized as a command but will be logged!
		FUNCechoInfo "[WARN] removes detected, better edit to remove from that line up to 'gskSpawnHint' and rerun!" #TODO this can be scripted easily if the echo on the console is like: RemoveAbove=1 or Remove=1 or RM1; echo RM1; echo rm2
		echo "${strExecEdit} '${strMapCfgFile}.condump.txt'"
		echo "strFlCondump='${strMapCfgFile}.condump.txt' $0 ${astrAllParams[@]}"
		FUNCwait10s "continue"
	fi
	
	if egrep "TODO" "$strFlMapadds";then
		ls -l "$strFlMapadds"
		FUNCwait10s "There are not supported spawnings or other TODOs at mapadds file."
	fi
	
	cat "$strFlCondumpCleanNew" >"$strFlCondumpClean" #after all went well
	ls -l "$strMapCfgFile"
else # create spawner aliases
	strAliasMode=""
	case "$strSpawnerMode" in
		MoreFoes)
			if ! FUNCaskYesNo "Do not use, prefer only the Summoning list. Continue anyway? Will be deprecated soon.";then exit;fi
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
	
	echo >gskSummonList.cfg #trunc/init
	echo "// Total ${#astrNPC[@]} NPCs/Items" |tee -a "gskSummonList.cfg"
	echo "alias mm_npc_create_facehugger \"mm_npc_create npc_facehugger models/NPC/Facehugger/Npc_Facehugger.mdl\"" |tee -a "gskSummonList.cfg"
	
	# these could work but the engine do not allow it. The NPC is created but the special item (bread or potion) is badly positioned at feet and on death it just vanishes.
	#  mm_npc_create npc_necro_guard_bow models/npc/Necroguard/npc_necroguard.mdl item_food_bread01_cooked weapon_arx_short_sword  weapon_arxcrossbow
	#  mm_npc_create npc_necro_guard_bow models/npc/Necroguard/npc_necroguard.mdl item_potion_life weapon_arx_short_sword weapon_arxcrossbow
	#  mm_npc_create npc_necro_guard models/npc/Necroguard/npc_necroguard.mdl item_potion_life item_potion_life weapon_arx_short_sword weapon_mm_shield_necroguard
	
	for((i=0;i<${#astrNPC[@]};i++));do
		strSpawnCommand="${astrNPC[$i]}"
		iNext=$((i+1))&&:
		if(( i == (${#astrNPC[@]}-1) ));then
			iNext=0
		fi
		case "$strSpawnerMode" in
			MoreFoes)
				strShortName="${strSpawnCommand#mm_npc_create_}"
				;;
			Summoning)
				strShortName="[${astrNPCsummon_Type[$i]}] $(echo "${strSpawnCommand}" |sed -r -e 's@[+]*gskSummon(.*)@\1@g') HP${astrNPCsummon_Cost[${i}]}"
				;;
			*) echo "invalid strSpawnerMode='$strSpawnerMode'" >&2; exit 1;;
		esac
		FUNCaliasNpcSpawner "${i}" "${strAliasMode}" "${strShortName}" "${#astrNPC[@]}" |tee -a "gskSummonList.cfg"
	done
	echo
	echo "// NOW COPY THE ABOVE INTO SOME CONFIG FILE (but is already at gskSummonList.cfg)"
fi

FUNCrefreshMount
