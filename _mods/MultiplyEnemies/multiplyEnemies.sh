#!/bin/bash

while [[ ! -f "./allMergerScriptsGenericConfig.sh" ]];do cd ..;done; source "./allMergerScriptsGenericConfig.sh"; FUNCminiModInit "$@"

: ${strPathSDK:="${strPathParent}/Might and Magic Dark Messiah SDK"} #help 
: ${nMultiply:=10} #help hardcore is 10-15 (too many will lag tho, tests on 3.2GHz CPU, it uses a single core for everything? ...)

: ${strMultToken:="DupMultHC"} #help used to detect if already multiplied

strMapList="l02_b1,l02_b2" #help comma separated
mapfile -t -d ',' astrMapList < <(echo -n "$strMapList") 

for strMap in "${astrMapList[@]}";do
	strVmf="${strPathSDK}/mm_content/mapsrc/${strMap}.vmf"
	declare -p strVmf
	if ! [[ -f "$strVmf" ]];then continue;fi
	#cp -v "$strVmf" "${strVmf}.$(date +'%Y_%m_%d-%H_%M_%S').bkp"
	
	nMaxID=$(egrep '"id"' "$strVmf" |tr -d '\t\r"' |awk '{print $2}' |sort -un |tail -n 1)
	nID=$((nMaxID+1000))
	declare -p nMaxID nID
	#jq '.entity | select(.targetname == "killer_in_house")' "$strVmf"
	
	declare -A astrExtraNPCs=() # beggining with '_' are custom setup here
	astrExtraNPCs[npc_necro_guard]="npc_necro_guard|npc_necro_guard_bow|_NpcNecroGuardShield"
	astrExtraNPCs[npc_necromancer]="npc_necro_guard_bow|npc_villager_undead|npc_undead"
	astrExtraNPCs[npc_necromancer_lord]="npc_necromancer|npc_necro_guard_bow|npc_villager_undead|npc_undead"
	
	: ${strNPCregex:="npc_necro_guard|npc_necro_guard_bow|npc_necromancer|npc_necromancer_lord|npc_spider_mini"}
	declare -A aNpcIdClass=()
	strFlData="$(mktemp)"
	egrep "classname.*(${strNPCregex})|targetname" "$strVmf" \
		|egrep "classname.*((${strNPCregex}))" -A1 \
		|sed -r -e 's@^--$@@g' \
		|sed '/^$/d' \
		|tr -d '\r\t"' \
		|tr ' ' '=' \
		|sed -n 'h;n;p;g;p' \
		|sed -r -e "s@targetname=(.*)@aNpcIdClass[\1]=@g" \
		|sed 'N;s/\n//' \
		|sed -r -e "s@(.*)=classname=(.*)@\1=\"\2\";@g" \
		|sort >"$strFlData"
	#cat "$strFlData"
	source "$strFlData"
	rm -vf "$strFlData"
	#declare -p aNpcIdClass |tr '[' '\n'
	for strNpcID in "${!aNpcIdClass[@]}";do
		egrep "${strNpcID}_${strMultToken}"
	done
	
	for((i=0;i<nMultiply;i++));do
		:
	done
done
