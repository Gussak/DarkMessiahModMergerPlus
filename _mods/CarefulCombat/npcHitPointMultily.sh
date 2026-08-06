#!/bin/bash

#	BSD 3-Clause License
#
#	Copyright (c) 2026, Gussak
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

# the HP multiplier at mm_game_settings.txt is working correctly, just at the docks war seems to have NPCs with hardcoded very low HP, no workaround I guess...
# but... for precise tweaking better use this script and a x1 multiplier at mm_game_settings.txt

#set -Eeu

#if [[ ! -f "info.json" ]];then echo "[ERROR] run this at this minimod folder";FUNCexit 1;fi

while [[ ! -f "./allMergerScriptsGenericConfig.sh" ]];do cd ..;done; source "./allMergerScriptsGenericConfig.sh"; FUNCminiModInit "$@"
#strPathThisModFolderFull="$(pwd)"
#declare -p strPathThisModFolderFull

#strPathThisModFolderBN="$(basename "${strPathThisModFolderFull}")"
#declare -p strPathThisModFolderBN

#cd "../../"
#strPathMainModFolder="$(pwd)"
#source "./allMergerScriptsGenericConfig.sh"

: ${bApplyHP:=false} #help
while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do # checks if param is set
	if [[ "$1" == "--help" ]];then #help show this help
		#egrep "[#]help" "./allMergerScriptsGenericConfig.sh" "$0" |sed -r -e 's@^[ \t]*@@'
		SECFUNCshowHelpV2 "./allMergerScriptsGenericConfig.sh"
		SECFUNCshowHelpV2 "${strPathThisModFolderFull}/$0"
		FUNCexit 0
	elif [[ "$1" == "-a" || "$1" == "--apply" ]];then #help create patched files and their .kvpatch.json
		bApplyHP=true
	else
		echo "[invalid option] '$1'"
		$0 --help #$0 considers ./, works best anyway..
		FUNCexit 1
	fi
	shift&&:
done	

#FUNCechoInfo 
echo "You can reapply this patch changing the HP multiplier."

: ${bVerbose=false} #help

#IFS=$'\n' read -d '' -r -a astrList < <(egrep "npc_health" -R "${astrGrepIncludesExt[@]}" "${strPathParent}/"* |egrep -v "${strGameInstallMainFolder}/" &&:)&&:
IFS=$'\n' read -d '' -r -a astrList < <(
	cd "$strPathParent"
	egrep "npc_health" -R --include="*.qct" "${strPathParent}/"* \
		|egrep -v "${strPathThisModFolderFull}|${strGameInstallMainFolder}/|${strMergedModsFolderBN}|${strVanillaLayer}" \
		|tr -d '\r' \
		|sort -u \
		&&: \
)&&:
if $bVerbose;then
	declare -p astrList |sed -r -e "$strSedArrayNumToLn"
fi

function FUNChp() {
	echo "$1" |egrep -o "npc_health.*" |tr -d '"\r' |awk '{print $2}'&&:
	return 0
}

declare -A anVanillaValues=()
declare -A astrFlVanillaScript=()
declare -A anMaxOtherModsValues=()
declare -A anOtherModsValues=()
for strFlWork in "${astrList[@]}";do
	#echo "$strFlWork"
	strFlRelat="$(echo "$strFlWork" |egrep -oi "(${strRegexKGMRF}).*" |cut -d"/" -f2- |cut -d: -f1)"&&:
	nHPvalue="$(FUNChp "$strFlWork")"
	
	if [[ "$strFlWork" =~ ^${strVanillaScriptsPath}.* ]];then
		anVanillaValues["${strFlRelat}"]=$nHPvalue
		astrFlVanillaScript["${strFlRelat}"]="$strVanillaScriptsPath/mm/${strFlRelat}"
	fi
	
	#declare -p anMaxOtherModsValues strFlRelat strFlWork
	if [[ -n "${anMaxOtherModsValues[$strFlRelat]-}" ]];then
		if((nHPvalue > ${anMaxOtherModsValues[$strFlRelat]}));then
			anMaxOtherModsValues[${strFlRelat}]=$nHPvalue
		fi
		anOtherModsValues[${strFlRelat}]="${anOtherModsValues[${strFlRelat}]-}, $nHPvalue"
	else
		anMaxOtherModsValues[${strFlRelat}]=$nHPvalue
	fi
	#if((${#anMaxOtherModsValues[@]}==0));then
		#anMaxOtherModsValues[${strFlRelat}]=$nHPvalue
	#else
		#if((nHPvalue > ${anMaxOtherModsValues[$strFlRelat]}));then
			#anMaxOtherModsValues[${strFlRelat}]=$nHPvalue
		#fi
	#fi
done
if $bVerbose;then
	declare -p anVanillaValues |sed -r -e "$strSedArrayIDsToLn"
	declare -p anMaxOtherModsValues |sed -r -e "$strSedArrayIDsToLn"
fi

: ${nMultHP:=21} #help

astrSpecialNpcsTmp=(
	models/npc/leanna/npc_leanna.qct=*11
	models/npc/crow/npc_crow.qct=Vanilla
	models/npc/dog/npc_dog.qct=Vanilla
	models/npc/menelag/npc_menelag.qct=Vanilla
	models/npc/pig/pig.qct=Vanilla
	models/npc/orc/npc_orc.qct=*210
	models/npc/orc_chief/npc_orc_chief.qct=*42
	models/npc/necromancer/npc_necromancer.qct=*210
	models/npc/necromancer_lord/npc_necromancer_lord.qct=*210
	models/npc/necroguard/npc_necroguard.qct=*210
	models/npc/necroguard_undead/npc_necroguard_undead.qct=*126
	models/npc/necrocivilian/npc_necrocivilian.qct=*63
	models/npc/undead/npc_undead.qct=*420 # it is too slow. low HP would make sense if it was a crowd of 50. necromancers should be able to raise them. To compensate all that, make it a tank.
)
declare -p astrSpecialNpcsTmp |sed -r -e "$strSedArrayIDsToLn"
: ${astrSpecialNpcs:="$(echo "${astrSpecialNpcsTmp[*]}" |tr ' ' ',')"} #help comma separated. use file=NumericValue or file=Vanilla. All non hostiles (friendlies) and uniques, I am keeping vanilla, as we are intended to defend them right? it is about keeping it a challenging "defend them" quest (WIP).
#: ${anSpecialNpcHP:="200,1200"} #help comma separated

astrSpecialNpcs=($(echo "$astrSpecialNpcs" |tr ',' ' '))
declare -p astrSpecialNpcs
for((i=0;i<${#astrSpecialNpcs[@]};i++));do
	echo "astrSpecialNpcs[$i]=${astrSpecialNpcs[$i]}"
	strFl="$(echo "${astrSpecialNpcs[i]}" |sed -r -e 's@(.*)=(.*)@\1@')"
	nHP="$(  echo "${astrSpecialNpcs[i]}" |sed -r -e 's@(.*)=(.*)@\2@')"
	astrSpecialNpcs[$i]="$strFl"
	anSpecialNpcHP[$i]="$nHP"
done
#anSpecialNpcHP=($(echo "$anSpecialNpcHP" |tr ',' ' '))
declare -p astrSpecialNpcs anSpecialNpcHP

nColW=7
astrSortFlNPCs=($(for str in "${!anVanillaValues[@]}";do echo "$str";done |sort))
declare -p astrSortFlNPCs
strFmt="%-${nColW}s %-${nColW}s %-${nColW}s %s\n"
echo
printf "$strFmt" "Vanilla" "MaxAtOtherMods" "FinalHP" "FlNPC"
printf "$strFmt" "Vnl" "MaxOM" "FinHP" "FlNPC"
for strFlNpc in "${astrSortFlNPCs[@]}";do
	#declare -p strFlNpc
	nMultHPfinal=$nMultHP
	#if [[ "$strFlNpc" =~ ${strSpecialNpcRegex} ]];then
		#nMultHPfinal=$nSpecialNpcMult
	#else
		#nMultHPfinal=$nMultHP
	#fi
	nVanillaHP=$((${anVanillaValues[$strFlNpc]}))
	nNewHP=$((nVanillaHP * nMultHPfinal))
	#declare -p nVanillaHP nNewHP
	for((i=0;i<${#astrSpecialNpcs[@]};i++));do
		if [[ "$strFlNpc" == "${astrSpecialNpcs[i]}" ]];then
			nNewHPcheck="${anSpecialNpcHP[i]}"
			#declare -p nNewHPcheck
			if [[ "$nNewHPcheck" == Vanilla ]];then
				nNewHP="$((nVanillaHP+1))" # +1 is just a trick to grant the patch override
			elif [[ "${nNewHPcheck:0:1}" == "*" ]];then
				nNewHP=$((nVanillaHP * ${nNewHPcheck:1}))
			else
				nNewHP="$nNewHPcheck"
			fi
			break
		fi
	done
	#declare -p nVanillaHP nNewHP
	strHint=""
	strHint2=""
	if((${anMaxOtherModsValues[$strFlNpc]} > nNewHP));then strHint+="!";fi
	if((${anVanillaValues[$strFlNpc]} == (nNewHP - 1) ));then strHint2+="!";fi
	printf "$strFmt" "${anVanillaValues[$strFlNpc]}" "${anMaxOtherModsValues[$strFlNpc]}${strHint}" "${nNewHP}${strHint2}" "${strFlNpc}  # ${anOtherModsValues[${strFlNpc}]-}"
	
	strPathModPatch="${strPathThisModFolderFull}/content/$(dirname "${strFlNpc}")"
	mkdir -p "${strPathModPatch}"
	
	if $bApplyHP;then
		strFlModded="${strPathModPatch}/$(basename "${strFlNpc}")"
		
	#if [[ -f "${strFlModded}" ]];then
		#: ${bForceRecreate:=false} #help this will delete the copy of vanilla file that was patched and copy again from vanilla before repatching
		#if $bForceRecreate;then 
			FUNCtrash "${strFlModded}" >/dev/null
		#fi
	#fi
	#if [[ ! -f "${strFlModded}" ]];then
		cp "${astrFlVanillaScript[$strFlNpc]}" "${strPathModPatch}/"
		chmod u+w "$strFlModded"
		ln -sf "./$(basename "${strFlNpc}")" "${strFlModded}.DO_NOT_EDIT.AUTOGEN"
	#fi
	
		strKVPatch='
{
	"$keyvalues.entity_data.difficulty": "1.0",
	"$keyvalues.entity_data.dodge_on_kick_init_chance": "0.25",
	"$keyvalues.entity_data.level_1.difficulty": "1.0",
	"$keyvalues.entity_data.level_1.npc_health": "'"${nNewHP}"'",
	"$keyvalues.entity_data.level_1.ThrowPrecisionNbShootToIn": "2",
	"$keyvalues.entity_data.npc_health": "'"${nNewHP}"'",
	"$keyvalues.entity_data.TimeKnockedDownByPhysics": "10"'
		if [[ "${strFlNpc}" =~ .*undead.* ]];then
			strKVPatch+=',
	"$keyvalues.entity_data.life_stopflee": "1.0",
	"$keyvalues.entity_data.life_tobeg": "0.0",
	"$keyvalues.entity_data.life_toflee": "0.0"'
			#declare -p strKVPatch strFlNpc;read
		fi
			strKVPatch+='
}
';

		#help this is like manually typing the value there. Could may be use a json data created here to apply thru keyValuePatcher.py instead, may ne more robust (less prone to fail).
		# 1st apply a mini patch on the vanilla
		"${strPathMainModFolder}/keyValuePatcher.py" apply "${strFlModded}" <(echo "$strKVPatch") --prettify --append-missing
		#sed -i.bkp -r -e 's@(.*npc_health[^0-9]*)([0-9]*)(.*)@\1'"${nNewHP}"'\3@' "$strFlModded" #|grep npc_health
		"${strPathMainModFolder}/keyValuePatcher.py" create "${astrFlVanillaScript[$strFlNpc]}" "${strFlModded}"&&:;nRet=$?
		
		case $nRet in
			0) FUNCechoInfo "[Identical]";;
			1) 
				FUNCechoInfo "[Diff PATCH from MOD vs Vanilla creation (((OK))) ]"
				;;
			2) 
				FUNCechoInfo "[WARNING: diff trouble] try manually"; #this ever happens?
				"${strExecMerger}" "${astrFlVanillaScript[$strFlNpc]}" "$strFlModded";
				;;
			*) FUNCechoInfo "[ERROR: unrecognized diff return value]";FUNCexit 1;;
		esac
		
		ls -l "${strFlModded}.kvpatch.json"
		cat "${strFlModded}.kvpatch.json";echo
		#read -n 1 -p "keyValuePatcher created: '${strFlModded}.kvpatch.json'"
	fi
done

##\
	#|egrep -vi "${strDownloadedModFilesRel}|${strDisabledTmpTestFolderRel}|ModLauncher|AdvancedSDK|OverlayFSworkDirDontTouchThis|IGNORE_LAYER|${strWriteLayer}|${strVanillaLayer}|${strMergedModsFolder}|${strGameInstallMainFolder}"

if $bApplyHP;then
	FUNCrefreshMount # if it did not update, means OverlayFS needs refresing to sync with modified files.
else
	echo "[INFO] !!! Now run it with param --apply to generate the modded files and patches. !!!"
fi
