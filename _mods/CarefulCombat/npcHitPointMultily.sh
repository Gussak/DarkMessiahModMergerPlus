#!/bin/bash

if true;then
	set -Eeu
	
	strPathModFolder="$(dirname "$(realpath "$0")")"
	declare -p strPathModFolder
	
	cd "../../"
	source "./allMergerScriptsGenericConfig.sh"

	#FUNCechoInfo 
	echo "You can reapply this patch changing the HP multiplier."
	
	: ${bVerbose=false} #help
	
	cd "$strPathParent"
	#IFS=$'\n' read -d '' -r -a astrList < <(egrep "npc_health" -R "${astrGrepIncludesExt[@]}" "${strPathParent}/"* |egrep -v "${strGameInstallMainFolder}/" &&:)&&:
	IFS=$'\n' read -d '' -r -a astrList < <(egrep "npc_health" -R --include="*.qct" "${strPathParent}/"* |egrep -v "${strGameInstallMainFolder}/" |tr -d '\r' |sort -u &&:)&&:
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
	: ${strSpecialNpcRegex:=".*(leanna).*"} #help
	: ${nSpecialNpcFurtherMult:=20} #help
	
	nColW=7
	astrSortFlNPCs=($(for str in "${!anVanillaValues[@]}";do echo "$str";done |sort))
	declare -p astrSortFlNPCs
	strFmt="%-${nColW}s %-${nColW}s %-${nColW}s %s\n"
	echo
	printf "$strFmt" "Vanilla" "MaxOtherMods" "Mult" "FlNPC"
	printf "$strFmt" "Vnl" "MaxOM" "Mult" "FlNPC"
	for strFlNpc in "${astrSortFlNPCs[@]}";do
		#declare -p strFlNpc
		if [[ "$strFlNpc" =~ ${strSpecialNpcRegex} ]];then
			nMultHPfinal=$((nMultHP*nSpecialNpcFurtherMult));
		else
			nMultHPfinal=$nMultHP
		fi
		nNewHP=$((${anVanillaValues[$strFlNpc]} * nMultHPfinal))
		strHint=""
		if((${anMaxOtherModsValues[$strFlNpc]} > nNewHP));then strHint="!";fi
		printf "$strFmt" "${anVanillaValues[$strFlNpc]}" "${anMaxOtherModsValues[$strFlNpc]}${strHint}" "$nNewHP" "${strFlNpc}"
		
		strPathModPatch="${strPathModFolder}/content/$(dirname "${strFlNpc}")"
		mkdir -vp "${strPathModPatch}"
		
		strModFilePatch="${strPathModPatch}/$(basename "${strFlNpc}")"
		if [[ ! -f "${strModFilePatch}" ]];then
			cp -v "${astrFlVanillaScript[$strFlNpc]}" "${strPathModPatch}/"
			chmod -v u+w "$strModFilePatch"
		fi
		
		: ${bApplyHP:=false} #help
		if $bApplyHP;then
			sed -i.bkp -r -e 's@(.*npc_health[^0-9]*)([0-9]*)(.*)@\1'"${nNewHP}"'\3@' "$strModFilePatch" #|grep npc_health
		fi
	done

	##\
		#|egrep -vi "${strDownloadedModFilesRel}|${strDisabledTmpTestFolderRel}|ModLauncher|AdvancedSDK|OverlayFSworkDirDontTouchThis|IGNORE_LAYER|${strWriteLayer}|${strVanillaLayer}|${strMergedModsFolder}|${strGameInstallMainFolder}"
fi
