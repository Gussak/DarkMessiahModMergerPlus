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

astrAliasList=()
function FUNCreplace() {
	# to replace
	local lstrReplaceWhatCmdID="${1}";shift
	local lstrReplaceWhatModelBN="${1}";shift
	local lstrReplaceWhatFolder="${1}";shift
	# to dup
	local lstrCopyFromModelFile="${1}";shift
	local lstrCopyFromRelatPath="${1}";shift
	
	if [[ -z "$lstrCopyFromModelFile" ]];then
		echo "was not overriden yet: ${lstrReplaceWhatCmdID}"
		return
	fi
	
	local lstrPathVanillaAllFiles="${strVanillaAllExtractedFilesPath}/mm/${lstrCopyFromRelatPath}/"

	if [[ ! -f "${lstrPathVanillaAllFiles}/${lstrCopyFromModelFile}.mdl" ]];then
		FUNCechoInfo "[ERROR] file '${lstrPathVanillaAllFiles}/${lstrCopyFromModelFile}.mdl' not found, did you extract all vanilla files from all VPKs?"
		exit 1
	fi

	mapfile -t astrFl < <(cd "${lstrPathVanillaAllFiles}/"; find ./ -type f -maxdepth 1 -mindepth 1 |sed -r -e 's@^./(.*)@\1@g')
	#declare -p astrFl;exit
	local lstrFl
	for lstrFl in "${astrFl[@]}";do
		mkdir -vp "${lstrReplaceWhatFolder}"
		local lstrFlTo="${lstrReplaceWhatFolder}/${lstrReplaceWhatModelBN}${lstrFl#${lstrCopyFromModelFile}}"
		if ! cp -vf "${lstrPathVanillaAllFiles}/$lstrFl" "$lstrFlTo";then
			declare -p lstrReplaceWhatCmdID lstrReplaceWhatModelBN lstrReplaceWhatFolder lstrCopyFromModelFile lstrCopyFromRelatPath
			FUNCechoInfo "ERROR: '${lstrPathVanillaAllFiles}/$lstrFl' '$lstrFlTo'"
			read -n 1
			exit 1
		fi
	done
	declare -p lstrReplaceWhatCmdID lstrReplaceWhatModelBN lstrReplaceWhatFolder lstrCopyFromModelFile lstrCopyFromRelatPath >"${lstrReplaceWhatFolder}/readmeSimulating-${lstrCopyFromModelFile}-THRU-${lstrReplaceWhatModelBN}.txt"
	
	astrAliasList+=("alias gskCreate_${lstrCopyFromModelFile} \"Test_CreateEntity ${lstrReplaceWhatCmdID}\"")
}

#FUNCreplace \
	#"item_food_bread02_cooked" \
	#"bread02_cooked" \
	#"models/items/provisions/bread02/" \
	#"l6_jar_oil" \
	#"models/props/furnitures/gob/l6_jar_oil/" \
	#""

nInputParamsSz=5

astrInputParams=( #TODO remove the useless to free the very limited slots
	#lstrReplaceWhatCmdID      lstrReplaceWhatModelBN	lstrReplaceWhatFolder	           lstrCopyFromModelFile	lstrCopyFromRelatPath
	"item_food_bread02_cooked" "bread02_cooked"  "models/items/provisions/bread02/"    "l6_jar_oil"   "models/props/furnitures/gob/l6_jar_oil/" 
	"item_food_bread02_row"    "bread02_raw"     "models/items/provisions/bread02/"    "barrel01"     "models/props/furnitures/humans/"
	"item_food_egg"            "egg"             "models/items/provisions/egg/"        "quiver_guard" "models/items/weapons/quiver_guard/"
	"item_food_food_ratio01"   "food_ratio01"    "models/items/provisions/food_ratio/" "money01" "models/items/jewels/money/"
	"item_food_garlic_piece01" "garlic_b1"       "models/items/provisions/garlic/"     "quiver_orc" "models/items/weapons/quiver_orc/"
	"item_food_garlic_piece02" "garlic_b2"       "models/items/provisions/garlic/"     "arrow_bal_exp" "models/items/weapons/arrows/"
	"item_food_garlic_piece03" "garlic_b3"       "models/items/provisions/garlic/"     "arrow_classic" "models/items/weapons/arrows/"
	"item_food_green_apple"    "green_apple"     "models/items/provisions/fruit/"      "l11_coin" "models/props/archi/l11/"
	"item_food_leek02"         "leek02"          "models/items/provisions/leeks/"      "l11_coin2" "models/props/archi/l11/"
	"item_food_leek03"         "leek03"          "models/items/provisions/leeks/"      "" ""
	"item_food_leeks"          "leeks"           "models/items/provisions/leeks/"      "" ""
	"item_food_mushroom_medium" "mushroom_medium" "models/items/provisions/mushroom/"  "" ""
	"item_food_mushroom_small"  "mushroom_small"  "models/items/provisions/mushroom/"  "" ""
	"item_food_red_apple"       "red_apple"       "models/items/provisions/fruit/"     "" ""
	"item_food_saucisson"       "saucisson01"     "models/items/provisions/saucisson/" "" ""	
)
mapfile -t astrDetectedDB < <(cat "${strPathMainModFolder}/_mods/BloodySummoner/content/cfg/bloodysummoner.cfg" |egrep "^//ERROR:MissingMDL:" |sed -r -e 's@.*MissingMDL:(.*)[/]([^/]*)[.]mdl.*Test_CreateEntity ([^;]*);.*@"\3" "\2" "\1/" "" ""@g')
#declare -p astrDetectedDB
#astrRemainingDetectedDB=()
for((i=0;i<${#astrInputParams[@]};i+=nInputParamsSz));do
	FUNCreplace "${astrInputParams[@]:$i:$nInputParamsSz}"
	#bFound=false
	for((j=0;j<${#astrDetectedDB[@]};j++));do
		#declare -p j astrDetectedDB
		if [[ "${astrDetectedDB[$j]}" =~ .*${astrInputParams[$i]}.* ]];then
			unset astrDetectedDB[$j]
			#bFound=true
			break
		fi
	done
	astrDetectedDB=("${astrDetectedDB[@]}")
	#if ! $bFound;then astrRemainingDetectedDB+=();fi
done
#if(( ${#astrDetectedDB[@]} != (${#astrInputParams[@]}/nInputParamsSz) ));then

if(( ${#astrDetectedDB[@]} > 0 ));then
	echo
	echo "[INFO] new free slots were detected and documented:"
	for strLn in "${astrDetectedDB[@]}";do
		echo "$strLn"
	done
	echo
fi
#fi

FUNCrefreshMount # after changes

echo
for strAlias in "${astrAliasList[@]}";do
	echo "${strAlias}"
done
echo
echo "# now place the above aliases in some mod, suggestion: BloodySummoner (will go to a summon list) and may be gskCustomBinds"

