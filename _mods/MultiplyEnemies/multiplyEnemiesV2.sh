#!/bin/bash

while [[ ! -f "./allMergerScriptsGenericConfig.sh" ]];do cd ..;done; source "./allMergerScriptsGenericConfig.sh"; FUNCminiModInit "$@"

: ${strPathSDK:="${strPathParent}/Might and Magic Dark Messiah SDK"} #help 
: ${nMultiply:=3} #help too many will lag tho, tests on 3.2GHz CPU, it uses a single core for everything?
: ${strMultToken:="DupMultHC"} #help used to detect if already multiplied
: ${strDBGnpcIdFilterRegex:=""} #help
declare -p nMultiply strMultToken strPathSDK strDBGnpcIdFilterRegex

: ${strMapList:="l02_b1,l02_b2"} #help comma separated
mapfile -t -d ',' astrMapList < <(echo -n "$strMapList") 

#declare -A aMap_NpcFirstFoundEntLn=()
## these are based on vanilla .vmf files, changed files will differ so it also needs the md5sum
#aMap_NpcFirstFoundEntLn[l02_b1_4ee4febf333ce791bd93942253d8fcb1]="316521"
#aMap_NpcFirstFoundEntLn[l02_b2_1f2d529785eed57d3b332b0a8b75f0e1]="366480"

: ${strNPCallowedClasses:="npc_necro_guard,npc_necro_guard_bow,npc_necromancer,npc_necromancer_lord,npc_spider_mini,npc_spider_regular,npc_spider_giant,npc_undead,npc_villager_undead"} #help
strNPCallowedClassesRegex=$(echo "$strNPCallowedClasses" |tr ',' '|')
mapfile -t astrNPCallowedClassList < <(echo "$strNPCallowedClasses" |tr ',' '\n')

# more variety and challenge
declare -A astrClass_ExtraNpcClasses=() # beggining with '_' are custom setup here. These are the npcs that will be added if the key matches. The more they appear the more weight they have to spawn, so you can repeat them. They cycle to first.
astrClass_ExtraNpcClasses[npc_necro_guard]="npc_necro_guard_bow|_NpcNecroGuardShield|npc_necromancer"
#astrClass_ExtraNpcClasses[npc_necro_guard_bow]="npc_necro_guard_bow|_NpcNecroGuardShield|npc_necromancer"
astrClass_ExtraNpcClasses[npc_necro_guard_bow]="npc_necromancer|npc_undead|npc_undead"
astrClass_ExtraNpcClasses[npc_necromancer]="npc_undead|npc_villager_undead|npc_necro_guard_bow"
astrClass_ExtraNpcClasses[npc_necromancer_lord]="npc_undead|npc_villager_undead|npc_necro_guard_bow|npc_necromancer"
astrClass_ExtraNpcClasses[npc_spider_mini]="npc_spider_regular|npc_spider_mini|npc_spider_mini|npc_spider_mini"
astrClass_ExtraNpcClasses[npc_spider_regular]="npc_spider_regular|npc_spider_mini"
astrClass_ExtraNpcClasses[npc_spider_giant]="npc_spider_regular"
astrClass_ExtraNpcClasses[npc_undead]="npc_undead|npc_undead|npc_villager_undead"
astrClass_ExtraNpcClasses[npc_villager_undead]="npc_undead|npc_villager_undead|npc_villager_undead"

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

function FUNCappendFood() {
	local lstrNpcId="$(echo "${!aNpcId_origin[@]}" |awk '{print $1}')" #first
	echo '
entity
{
	"id" "'"${nGlobalCurrentID}"'"
	"classname" "item_food_bread01_cooked"
	"combinability" "1"
	"angles" "0 0 0"
	"model" "models/items/provisions/bread01/bread01_cooked.mdl"
	"combinetarget1enable" "1"
	"combinetarget2enable" "1"
	"combinetarget3enable" "1"
	"combinetarget4enable" "1"
	"combinetarget5enable" "1"
	"combinetarget6enable" "1"
	"combinetarget7enable" "1"
	"combinetarget8enable" "1"
	"combinetarget9enable" "1"
	"combinetarget10enable" "1"
	"physdamagescale" "0.1"
	"inertiaScale" "1.0"
	"fademindist" "-1"
	"fadescale" "1"
	"spawnflags" "257"
	"UseSpeedToCalculateSoundVolume" "1"
	"origin" "'"${aNpcId_origin[$lstrNpcId]}"'"
	editor
	{
		"color" "220 30 220"
		"visgroupid" "27"
		"visgroupshown" "1"
		"visgroupautoshown" "1"
		"logicalpos" "[3500 -13268]"
	}
}
'	
	((nGlobalCurrentID++))&&:
}

function FUNCappendNPCs() {
	local lstrFl="$1";shift
	local lstrNpcID="$1";shift
	#local lstrClass="$1";shift
	#local lnNumericGlobalID="$1";shift
	
	declare -p lstrNpcID
	
	local lstrClassOrig="${aNpcId_classname[$lstrNpcID]}"
	#declare -p lstrClassOrig astrClass_ExtraNpcClasses
	mapfile -t lastrClassList < <(echo "${astrClass_ExtraNpcClasses[$lstrClassOrig]}" |tr '|' '\n')
	
	nExtraNpcClassIndex=0
	for((iM=1;iM<=nMultiply;iM++));do
		strTargetName="${lstrNpcID}_${strMultToken}_$(printf %03d $iM)"
		if egrep "${strTargetName}" "$lstrFl";then continue;fi
		
		#dont use. the angle must be identical too to not leak, bad: nAngleY=$(( iM * (360/nMultiply) ))&&:
		
		nQuiverAmmo=$((iM+6))&&:
		
		#declare -p nExtraNpcClassIndex lastrClassList
		lstrClass="${lastrClassList[$nExtraNpcClassIndex]}"
		((nExtraNpcClassIndex++))&&:
		if((nExtraNpcClassIndex >= ${#lastrClassList[*]}));then nExtraNpcClassIndex=0;fi
		
		rangeweapon="0"
		additionalshield="0"
		additionalequipment="0"
		weaponmodel="0"
		case "${lstrClass}" in
			npc_necro_guard)
				additionalequipment="weapon_arx_short_sword"
				weaponmodel="models/Items/Weapons/Sword_Guard/Sword_Guard.mdl"
				;;
			_NpcNecroGuardShield)
				lstrClass="npc_necro_guard" # needs to update to the game classname
				additionalequipment="weapon_arx_short_sword"
				weaponmodel="models/Items/Weapons/Sword_Guard/Sword_Guard.mdl"
				additionalshield="weapon_mm_shield_necroguard"
				;;
			npc_necro_guard_bow)
				additionalequipment="weapon_arx_short_sword"
				weaponmodel="models/Items/Weapons/Sword_Guard/Sword_Guard.mdl"
				rangeweapon="weapon_arxcrossbow"
				# cant have shield and bow as will prevent firing the bow (bug as it wont unequip the shield to use the bow)
				;;
			npc_necromancer)
				additionalequipment="weapon_mm_staff_combat"
				;;
			npc_necromancer_lord)
				additionalequipment="weapon_mm_hook"
				weaponmodel="models/Items/Weapons/hook/hook.mdl"
				;;
		esac
		
		strOrigin="${aNpcId_origin[$lstrNpcID]}"
		# the compiler uses origin as "ID" for the NPCs on error logs... :(
		: ${bDBGoriginIdTrick:=false} #help
		if $bDBGoriginIdTrick;then
			astrOrigin=($strOrigin)
			nY="$(echo "${astrOrigin[1]}" |sed -r -e 's@(.*)[.].*@\1@g')"
			#echo "nY=$nY ${astrOrigin[1]}"
			nY=$((nY+iM))&&:
			astrOrigin[1]=$nY
			strOrigin="${astrOrigin[@]}"
			declare -p strOrigin
		fi
		
		: ${bApplyAsHiddenNpc:=false} #help hidden npcs required a triggered spawner?
		if $bApplyAsHiddenNpc;then
			echo '
hidden
{
' >>"${lstrFl}.ToAppend.vmf"
		fi
		# trying to easy CPU with sleepstate wakeradius wakesquad
		echo '
	entity
	{
		"id" "'"${nGlobalCurrentID}"'"
		"classname" "'"${lstrClass}"'"
		"targetname" "'"${strTargetName}"'"
		"model" "'"${astrNpcModel[$lstrClass]}"'"
		"additionalequipment" "'"${additionalequipment}"'"
		"weaponmodel" "'"$weaponmodel"'"
		"additionalshield" "'"${additionalshield}"'"
		"shieldmodel" "models/Items/Armors/shield_guard/shield_guard.mdl"
		"QuiverAmmo" "'"${nQuiverAmmo}"'"
		"QuiverModel" "models/items/weapons/Quiver_guard/quiver_guard.mdl"
		"rangeweapon" "'"$rangeweapon"'"
		"purse" "item_food_bread01_cooked"
		"origin" "'"${strOrigin}"'"
		"angles" "'"${aNpcId_angles[$lstrNpcID]}"'"
		"squadname" "'"${aNpcId_squadname[$lstrNpcID]}"'"
		
		"sleepstate" "1"
		"wakeradius" "15"
		"wakesquad" "1"
		"physdamagescale" "10"
		"EnableSummonSpider" "1"
		
		"combinability" "1"
		"renderfx" "0"
		"rendermode" "0"
		"renderamt" "255"
		"rendercolor" "255 255 255"
		"disablereceiveshadows" "0"
		"hintlimiting" "0"
		"usetruemovement" "0"
		"IgnoreEntInNav" "0"
		"healthreferencevalue" "0"
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
		if $bApplyAsHiddenNpc;then
			echo '
}
' >>"${lstrFl}.ToAppend.vmf"
		fi

		((nGlobalCurrentID++))&&:
	
	done
	
}

for strMap in "${astrMapList[@]}";do
	echo
	
	strVmf="${strPathSDK}/mm_content/mapsrc/${strMap}.vmf"
	declare -p strVmf
	if ! [[ -f "$strVmf" ]];then continue;fi
	#cp -v "$strVmf" "${strVmf}.$(date +'%Y_%m_%d-%H_%M_%S').bkp"
	
	if egrep "_${strMultToken}_" "$strVmf";then
		ls -l "${strVmf}.BeforeMultiplyEnemies.vmf" "${strVmf}" &&:
		if FUNCaskYesNo "[WARN] file already patched, restore backup and proceed?";then
			if cp -vf "${strVmf}.BeforeMultiplyEnemies.vmf" "${strVmf}";then
				# without the cleanup it may not properly update during compilation?
				FUNCtrash "${strPathSDK}/mm_content/mapsrc/${strMap}.bsp"
				FUNCtrash "${strPathSDK}/mm_content/mapsrc/${strMap}.log"
				FUNCtrash "${strPathSDK}/mm_content/mapsrc/${strMap}.prt"
				FUNCtrash "${strPathSDK}/mm_content/mapsrc/${strMap}.vmx"
			else
				exit 1
			fi
		else
			exit 1;
		fi
	else
		cp -v "$strVmf" "${strVmf}.BeforeMultiplyEnemies.vmf"
	fi
	
	strMD5="$(md5sum "$strVmf" |awk '{print $1}')"
	echo -n >"${strVmf}.ToAppend.vmf"
	strVmfData="$(cat "$strVmf" |tr -d '\r')"
	
	nMaxID=$(echo "$strVmfData" |egrep '"id"' |tr -d '\t\r"' |awk '{print $2}' |sort -un |tail -n 1)
	declare -g nGlobalStartAddID=$((nMaxID+1000)) #could be just +1 I guess
	declare -g nGlobalCurrentID=$nGlobalStartAddID
	declare -p nMaxID nGlobalCurrentID
	#jq '.entity | select(.targetname == "killer_in_house")' "$strVmf"
	
	declare -A aNpcId_classname=()
	declare -A aNpcId_origin=()
	declare -A aNpcId_angles=()
	declare -A aNpcId_squadname=()
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
	#mapfile -t aEntLnList < <(echo "$strVmfData" |egrep '^entity$' -n |sed -r -e 's@^([0-9]*):.*@\1@g') #only npc entities that are not hidden (they have no indentation)
	nFirstNpcValidClassLn="$(echo "$strVmfData" |egrep "^\s*\"classname\"\s*\"(${strNPCallowedClassesRegex})\"$" -n |head -n 1 |sed -r -e 's@^([0-9]*):.*@\1@g')"
	for nEntLn in "${aEntLnList[@]}";do
		if((nEntLn>nFirstNpcValidClassLn));then
			nInitLn=$nEntLnPrev
			break
		fi
		nEntLnPrev=$nEntLn
	done
	((nInitLn-=2))&&: #just in case it is a hidden entity
	declare -p nInitLn
	
	: ${nDBGinitLn:=-1} #help
	if((nDBGinitLn>0));then nInitLn=$nDBGinitLn;fi
	nLn=$((nInitLn-1))&&: #because it inc first at while loop below
	nEntInitLn=-1
	iSkipSubNesting=0
	targetname="";classname="";origin="";angles="";squadname=""
	: ${nDBGtestLim:=0} #help
	nFound=0
	strFlDB="$(mktemp)"
	#nEntLnIndex=0
	nLnHiddenNpc=-1
	echo "$strVmfData" |tail -n +"${nInitLn}" |while read strLn;do
		((nLn++))&&:
		#declare -p strLn
		#nEntLn=${aEntLnList[$nEntLnIndex]}
		
		if [[ "$strLn" =~ ^[\t]*hidden$ ]];then
			nLnHiddenNpc=$nLn
			continue
		fi
		
		if [[ "$strLn" =~ ^[\t]*entity$ ]];then
		#if [[ "$strLn" =~ ^entity$ ]];then #only npc entities that are not hidden (they have no indentation)
			if(( nLnHiddenNpc == (nLn-2) ));then continue;fi # skip hidden NPCs
			nEntInitLn="$nLn"
			iSkipSubNesting=-1 # the next line with '{' is from "entity"
			continue
		fi
		
		if((nEntInitLn != -1));then
			if [[ "$strLn" =~ ^[\t]*[{]$ ]];then ((iSkipSubNesting++))&&:;continue;fi
			if [[ "$strLn" =~ ^[\t]*[}]$ ]];then
				if((iSkipSubNesting>0));then ((iSkipSubNesting--))&&:;continue;fi
				aNpcId_classname[$targetname]="$classname"
				aNpcId_origin[$targetname]="$origin"
				aNpcId_angles[$targetname]="$angles"
				aNpcId_squadname[$targetname]="$squadname"
				echo "FOUND: $targetname $classname $squadname angles='$angles' origin='$origin' (Ln: $nEntInitLn)"
				#declare -p aNpcId_classname aNpcId_origin >"$strFlDB" #always overwrite with full data (could just append tho)
				echo 'aNpcId_classname['"$targetname"']="'"$classname"'"' >>"$strFlDB"
				echo 'aNpcId_origin['"$targetname"']="'"$origin"'"' >>"$strFlDB"
				echo 'aNpcId_angles['"$targetname"']="'"$angles"'"' >>"$strFlDB"
				echo 'aNpcId_squadname['"$targetname"']="'"$squadname"'"' >>"$strFlDB"
				nEntInitLn=-1
				((nFound++))&&:
				if((nFound==nDBGtestLim));then break;fi
				continue
			fi
			#### NPC ID
			if [[ "$strLn" =~ .*"targetname".* ]];then
				targetname="$(echo "$strLn" |tr -d '"' |awk '{print $2}')"
				continue
			fi
			#### data
			if [[ "$strLn" =~ .*"classname".* ]];then
				classname="$(echo "$strLn" |tr -d '"' |awk '{print $2}')"
				if ! [[ "$classname" =~ ^${strNPCallowedClassesRegex}$ ]];then
					nEntInitLn=-1 # to ignore and seek next entity
					echo -ne "skip classname='$classname'            \r"
				fi
				continue
			fi
			if [[ "$strLn" =~ .*"squadname".* ]];then
				squadname="$(echo "$strLn" |tr -d '"' |awk '{print $2}')"
				continue
			fi
			if [[ "$strLn" =~ .*"origin".* ]];then
				origin="$(echo "$strLn" |sed -r -e 's@\s*"origin"\s*"(.*)"\s*$@\1@g')"
				continue
			fi
			if [[ "$strLn" =~ .*"angles".* ]];then
				angles="$(echo "$strLn" |sed -r -e 's@\s*"angles"\s*"(.*)"\s*$@\1@g')"
				continue
			fi
		else
			echo -ne "$nLn\r"
		fi
	done;cat "$strFlDB";source "$strFlDB";rm -v "$strFlDB"
	
	#declare -p aNpcId_classname
	for strNpcID in "${!aNpcId_classname[@]}";do
		if [[ -n "$strDBGnpcIdFilterRegex" ]] && ! [[ "$strNpcID" =~ ${strDBGnpcIdFilterRegex} ]];then continue;fi
		if [[ "$strNpcID" =~ .*_${strMultToken}_.* ]];then continue;fi #skip new dups
		FUNCappendNPCs "$strVmf" "$strNpcID"
	done
	FUNCappendFood >>"${strVmf}.ToAppend.vmf"
	cat "${strVmf}.ToAppend.vmf" >>"$strVmf"
	ls -l "${strVmf}.BeforeMultiplyEnemies.vmf" "${strVmf}.ToAppend.vmf" "$strVmf"
	echo "TOTAL ADDED: $((nGlobalStartAddID-nGlobalCurrentID))"
done
