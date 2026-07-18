#!/bin/bash

while [[ ! -f "./allMergerScriptsGenericConfig.sh" ]];do cd ..;done; source "./allMergerScriptsGenericConfig.sh"; FUNCminiModInit "$@"

: ${strPathSDK:="${strPathParent}/Might and Magic Dark Messiah SDK"} #help 
: ${nMultiply:=10} #help hardcore is 10-15 (too many will lag tho, tests on 3.2GHz CPU, it uses a single core for everything? ...)
: ${strMultToken:="DupMultHC"} #help used to detect if already multiplied
declare -p nMultiply strMultToken strPathSDK

strMapList="l02_b1,l02_b2" #help comma separated
mapfile -t -d ',' astrMapList < <(echo -n "$strMapList") 

#declare -A aMap_NpcFirstFoundEntLn=()
## these are based on vanilla .vmf files, changed files will differ so it also needs the md5sum
#aMap_NpcFirstFoundEntLn[l02_b1_4ee4febf333ce791bd93942253d8fcb1]="316521"
#aMap_NpcFirstFoundEntLn[l02_b2_1f2d529785eed57d3b332b0a8b75f0e1]="366480"

: ${strNPCallowedClasses:="npc_necro_guard,npc_necro_guard_bow,npc_necromancer,npc_necromancer_lord,npc_spider_mini"} #help
strNPCallowedClassesRegex=$(echo "$strNPCallowedClasses" |tr ',' '|')
mapfile -t astrNPCallowedClassList < <(echo "$strNPCallowedClasses" |tr ',' '\n')

declare -A astrClass_ExtraNpcClasses=() # beggining with '_' are custom setup here. These are the npcs that will be added if the key matches. The more they appear the more weight they have to spawn, so you can repeat them.
astrClass_ExtraNpcClasses[npc_necro_guard]="_NpcNecroGuardShield|npc_necro_guard_bow|npc_necro_guard_bow|npc_necro_guard_bow"
astrClass_ExtraNpcClasses[npc_necro_guard_bow]="_NpcNecroGuardShield|npc_necro_guard_bow|npc_necro_guard_bow|npc_necro_guard_bow|npc_necro_guard_bow|npc_necro_guard_bow"
astrClass_ExtraNpcClasses[npc_necromancer]="npc_necro_guard_bow|npc_villager_undead|npc_undead|npc_villager_undead|npc_undead|npc_villager_undead|npc_undead"
astrClass_ExtraNpcClasses[npc_necromancer_lord]="npc_necromancer|npc_necro_guard_bow|npc_villager_undead|npc_undead|npc_villager_undead|npc_undead|npc_villager_undead|npc_undead"
astrClass_ExtraNpcClasses[npc_spider_mini]="npc_spider_mini"

declare -A astrNpcModel=()
astrNpcModel[npc_necro_guard]="models/npc/Necroguard/npc_necroguard.mdl"
astrNpcModel[npc_necro_guard_bow]="models/npc/Necroguard/npc_necroguard.mdl"
astrNpcModel[_NpcNecroGuardShield]="models/npc/Necroguard/npc_necroguard.mdl"
astrNpcModel[npc_necromancer]="models/NPC/Necromancer/Npc_necromancer.mdl"
astrNpcModel[npc_necromancer_lord]="models/NPC/Necromancer_Lord/Npc_Necromancer_Lord.mdl"
astrNpcModel[npc_spider_mini]="models/NPC/spider_mini/Npc_spider_mini.mdl"
astrNpcModel[npc_villager_undead]="models/npc/villager_undead/npc_villager_undead.mdl"
astrNpcModel[npc_undead]="models/NPC/Undead/Npc_undead.mdl"

# internal consistency checks
for npcClass1 in "${astrNPCallowedClassList[@]}";do
	bFoundClass=false
	for npcClass2 in "${!astrClass_ExtraNpcClasses[@]}";do
		if [[ "$npcClass1" == "$npcClass2" ]];then 
			bFoundClass=true
			break
		fi
	done
	if ! $bFoundClass;then
		echo "[ERROR] npcClass1='$npcClass1' not set at astrClass_ExtraNpcClasses"
		exit 1
	fi
done


function FUNCappendNPCs() {
	local lstrFl="$1";shift
	local lstrNpcID="$1";shift
	#local lstrClass="$1";shift
	#local lnNumericGlobalID="$1";shift
	
	declare -p lstrNpcID
	
	local lstrClassOrig="${aNpcId_Class[$lstrNpcID]}"
	#declare -p lstrClassOrig astrClass_ExtraNpcClasses
	mapfile -t lastrClassList < <(echo "${astrClass_ExtraNpcClasses[$lstrClassOrig]}" |tr '|' '\n')
	
	nExtraNpcClassIndex=0
	for((iM=1;iM<=nMultiply;iM++));do
		strTargetName="${lstrNpcID}_${strMultToken}_$(printf %03d $iM)"
		if egrep "${strTargetName}" "$lstrFl";then continue;fi
		
		nAngleY=$(( iM * (360/nMultiply) ))&&:
		
		nQuiverAmmo=$((iM+6))&&:
		
		#declare -p nExtraNpcClassIndex lastrClassList
		lstrClass="${lastrClassList[$nExtraNpcClassIndex]}"
		((nExtraNpcClassIndex++))&&:
		if((nExtraNpcClassIndex >= ${#lastrClassList[*]}));then nExtraNpcClassIndex=0;fi
		
		strRangedWeapon="0"
		strAdditionalShield="0"
		strAdditionalEquipment="0"
		case "${lstrClass}" in
			npc_necro_guard)
				strAdditionalEquipment="weapon_arx_short_sword"
				;;
			_NpcNecroGuardShield)
				strAdditionalEquipment="weapon_arx_short_sword"
				strAdditionalShield="weapon_mm_shield_necroguard"
				;;
			npc_necro_guard_bow)
				strAdditionalEquipment="weapon_arx_short_sword"
				strRangedWeapon="weapon_arxcrossbow"
				# cant have shield and bow as will prevent firing the bow (bug as it wont unequip the shield to use the bow)
				;;
		esac
		
		echo '
entity
{
	"id" "'"${nGlobalCurrentID}"'"
	"classname" "'"${lstrClass}"'"
	"targetname" "'"${strTargetName}"'"
	"model" "'"${astrNpcModel[$lstrClass]}"'"
	"additionalequipment" "'"${strAdditionalEquipment}"'"
	"weaponmodel" "models/Items/Weapons/Sword_Guard/Sword_Guard.mdl"
	"additionalshield" "'"${strAdditionalShield}"'"
	"shieldmodel" "models/Items/Armors/shield_guard/shield_guard.mdl"
	"QuiverAmmo" "'"${nQuiverAmmo}"'"
	"QuiverModel" "models/items/weapons/Quiver_guard/quiver_guard.mdl"
	"rangeweapon" "'"$strRangedWeapon"'"
	"purse" "item_food_bread01_cooked"
	"origin" "'"${aNpcId_Origin[$lstrNpcID]}"'"
	"angles" "0 '"${nAngleY}"' 0"
	
	"combinability" "1"
	"physdamagescale" "0.1"
	"renderfx" "0"
	"rendermode" "0"
	"renderamt" "255"
	"rendercolor" "255 255 255"
	"disablereceiveshadows" "0"
	"hintlimiting" "0"
	"usetruemovement" "0"
	"IgnoreEntInNav" "0"
	"healthreferencevalue" "0"
	"sleepstate" "0"
	"wakeradius" "0"
	"wakesquad" "0"
	"radiusforrandomattitude" "500"
	"health" "0"
	"DifficultyLevel" "0"
	"additionalhelmet" "0"
	"skin" "0"
	"disableheadcut" "0"
	"ShouldDropOrnament" "0"
	"UseSpeak" "0"
	"spawnflags" "4"
	editor
	{
		"color" "0 0 0"
		"visgroupid" "10"
		"visgroupid" "12"
		"visgroupshown" "1"
		"visgroupautoshown" "1"
		"logicalpos" "[0 0]"
	}
}
' >>"${lstrFl}.ToAppend.vmf"

		((nGlobalCurrentID++))&&:
	
	done
	
}

for strMap in "${astrMapList[@]}";do
	echo
	
	strVmf="${strPathSDK}/mm_content/mapsrc/${strMap}.vmf"
	declare -p strVmf
	if ! [[ -f "$strVmf" ]];then continue;fi
	#cp -v "$strVmf" "${strVmf}.$(date +'%Y_%m_%d-%H_%M_%S').bkp"
	
	strMD5="$(md5sum "$strVmf" |awk '{print $1}')"
	echo -n >"${strVmf}.ToAppend.vmf"
	strVmfData="$(cat "$strVmf" |tr -d '\r')"
	
	nMaxID=$(echo "$strVmfData" |egrep '"id"' |tr -d '\t\r"' |awk '{print $2}' |sort -un |tail -n 1)
	declare -g nGlobalCurrentID=$((nMaxID+1000)) #could be just +1 I guess
	declare -p nMaxID nGlobalCurrentID
	#jq '.entity | select(.targetname == "killer_in_house")' "$strVmf"
	
	declare -A aNpcId_Class=()
	declare -A aNpcId_Origin=()
	#mapfile -t aLnData < <(cat "$strVmf")
	#declare -p aLnData
	#set -x
	#strFlKey="${strMap}_${strMD5}"
	#declare -p strFlKey
	#if [[ -n "${aMap_NpcFirstFoundEntLn[${strFlKey}]-}" ]];then
		#nInitLn="${aMap_NpcFirstFoundEntLn[${strFlKey}]}"
	#else
		#nInitLn="$(echo "$strVmfData" |egrep '^\s*entity$' -n |head -n 1 |sed -r -e 's@^([0-9]*):.*@\1@g')"
	#fi
	#declare -p nInitLn
	
	nInitLn=1
	mapfile -t aEntLnList < <(echo "$strVmfData" |egrep '^\s*entity$' -n |sed -r -e 's@^([0-9]*):.*@\1@g')
	nFirstNpcValidClassLn="$(echo "$strVmfData" |egrep "^\s*\"classname\"\s*\"(${strNPCallowedClassesRegex})\"$" -n |head -n 1 |sed -r -e 's@^([0-9]*):.*@\1@g')"
	for nEntLn in "${aEntLnList[@]}";do
		if((nEntLn>nFirstNpcValidClassLn));then
			nInitLn=$nEntLnPrev
			break
		fi
		nEntLnPrev=$nEntLn
	done
	
	: ${nDBGinitLn:=-1} #help
	if((nDBGinitLn>0));then nInitLn=$nDBGinitLn;fi
	nLn=$((nInitLn-1))&&: #because it inc first at while loop below
	nEntInitLn=-1
	iSkipSubNesting=0
	targetname=""
	classname=""
	origin=""
	: ${nDBGtestLim:=0} #help
	nFound=0
	strFlDB="$(mktemp)"
	echo "$strVmfData" |tail -n +"${nInitLn}" |while read strLn;do
		((nLn++))&&:
		#declare -p strLn
		
		if [[ "$strLn" =~ ^[\t]*entity$ ]];then
			nEntInitLn="$nLn"
			iSkipSubNesting=-1 # the next line with '{' is from "entity"
			continue
		fi
		
		if((nEntInitLn != -1));then
			if [[ "$strLn" =~ ^[\t]*[{]$ ]];then ((iSkipSubNesting++))&&:;continue;fi
			if [[ "$strLn" =~ ^[\t]*[}]$ ]];then
				if((iSkipSubNesting>0));then ((iSkipSubNesting--))&&:;continue;fi
				aNpcId_Class[$targetname]="$classname"
				aNpcId_Origin[$targetname]="$origin"
				echo "FOUND: $targetname $classname origin='$origin' (Ln: $nEntInitLn)"
				#declare -p aNpcId_Class aNpcId_Origin >"$strFlDB" #always overwrite with full data (could just append tho)
				echo 'aNpcId_Class['"$targetname"']="'"$classname"'"' >>"$strFlDB"
				echo 'aNpcId_Origin['"$targetname"']="'"$origin"'"' >>"$strFlDB"
				nEntInitLn=-1
				((nFound++))&&:
				if((nFound==nDBGtestLim));then break;fi
				continue
			fi
			#### NPC ID
			if [[ "$strLn" =~ .*"targetname".* ]];then
				targetname="$(echo "$strLn" |tr -d '"' |awk '{print $2}')"
				#declare -p targetname
				continue
			fi
			#### data
			if [[ "$strLn" =~ .*"classname".* ]];then
				classname="$(echo "$strLn" |tr -d '"' |awk '{print $2}')"
				#declare -p classname
				if ! [[ "$classname" =~ ^${strNPCallowedClassesRegex}$ ]];then
					nEntInitLn=-1 # to ignore and seek next entity
					echo -ne "skip classname='$classname'            \r"
				fi
				continue
			fi
			if [[ "$strLn" =~ .*"origin".* ]];then
				origin="$(echo "$strLn" |sed -r -e 's@\s*"origin"\s*"(.*)"\s*$@\1@g')"
				#declare -p origin
				continue
			fi
		else
			echo -ne "$nLn\r"
		fi
	done;cat "$strFlDB";source "$strFlDB";rm -v "$strFlDB"
	
	#declare -p aNpcId_Class
	for strNpcID in "${!aNpcId_Class[@]}";do
		if [[ "$strNpcID" =~ .*_${strMultToken}_.* ]];then continue;fi #skip new dups
		FUNCappendNPCs "$strVmf" "$strNpcID"
	done
done
