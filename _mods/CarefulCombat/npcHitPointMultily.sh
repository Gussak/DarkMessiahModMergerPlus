#!/bin/bash

# the HP multiplier at mm_game_settings.txt is working correctly, just at the docks war seems to have NPCs with hardcoded very low HP, no workaround I guess...
# but... for precise tweaking better use this script and a x1 multiplier at mm_game_settings.txt

if true;then
	set -Eeu
	
	strPathThisModFolderFull="$(pwd)"
	declare -p strPathThisModFolderFull
	
	strPathThisModFolderBN="$(basename "${strPathThisModFolderFull}")"
	declare -p strPathThisModFolderBN
	
	cd "../../"
	strPathMainModFolder="$(pwd)"
	source "./allMergerScriptsGenericConfig.sh"

	: ${bApplyHP:=false} #help
	while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do # checks if param is set
		if [[ "$1" == "--help" ]];then #help show this help
			#egrep "[#]help" "./allMergerScriptsGenericConfig.sh" "$0" |sed -r -e 's@^[ \t]*@@'
			SECFUNCshowHelpV2 "./allMergerScriptsGenericConfig.sh"
			SECFUNCshowHelpV2 "${strPathThisModFolderFull}/$0"
			exit 0
		elif [[ "$1" == "-a" || "$1" == "--apply" ]];then #help create patched files and their .kvpatch.json
			bApplyHP=true
		else
			echo "[invalid option] '$1'"
			$0 --help #$0 considers ./, works best anyway..
			exit 1
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
	
	: ${astrSpecialNpcs:="models/npc/leanna/npc_leanna.qct,models/npc/leanna_lich/npc_leanna_lich.qct"} #help comma separated
	: ${anSpecialNpcHP:="200,1200"} #help comma separated
	
	astrSpecialNpcs=($(echo "$astrSpecialNpcs" |tr ',' ' '))
	anSpecialNpcHP=($(echo "$anSpecialNpcHP" |tr ',' ' '))
	
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
		nNewHP=$((${anVanillaValues[$strFlNpc]} * nMultHPfinal))
		for((i=0;i<${#astrSpecialNpcs[@]};i++));do
			if [[ "$strFlNpc" == "${astrSpecialNpcs[i]}" ]];then
				#nMultHPfinal="${anSpecialNpcHP[i]}"
				nNewHP="${anSpecialNpcHP[i]}"
				break
			fi
		done
		strHint=""
		if((${anMaxOtherModsValues[$strFlNpc]} > nNewHP));then strHint="!";fi
		printf "$strFmt" "${anVanillaValues[$strFlNpc]}" "${anMaxOtherModsValues[$strFlNpc]}${strHint}" "$nNewHP" "${strFlNpc}"
		
		strPathModPatch="${strPathThisModFolderFull}/content/$(dirname "${strFlNpc}")"
		mkdir -p "${strPathModPatch}"
		
		strFlModded="${strPathModPatch}/$(basename "${strFlNpc}")"
		if [[ ! -f "${strFlModded}" ]];then
			cp "${astrFlVanillaScript[$strFlNpc]}" "${strPathModPatch}/"
			chmod u+w "$strFlModded"
		fi
		
		if $bApplyHP;then
			sed -i.bkp -r -e 's@(.*npc_health[^0-9]*)([0-9]*)(.*)@\1'"${nNewHP}"'\3@' "$strFlModded" #|grep npc_health
			
			"${strPathMainModFolder}/keyValuePatcher.py" create "${astrFlVanillaScript[$strFlNpc]}" "${strFlModded}"
			ls -l "${strFlModded}.kvpatch.json"
			cat "${strFlModded}.kvpatch.json";echo
			#read -n 1 -p "keyValuePatcher created: '${strFlModded}.kvpatch.json'"
		fi
	done

	##\
		#|egrep -vi "${strDownloadedModFilesRel}|${strDisabledTmpTestFolderRel}|ModLauncher|AdvancedSDK|OverlayFSworkDirDontTouchThis|IGNORE_LAYER|${strWriteLayer}|${strVanillaLayer}|${strMergedModsFolder}|${strGameInstallMainFolder}"
fi
