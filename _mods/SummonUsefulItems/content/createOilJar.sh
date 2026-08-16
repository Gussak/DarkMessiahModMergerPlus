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
	local lstrReplaceWhatCmdID="$1";shift
	local lstrReplaceWhatModelBN="$1";shift
	local lstrReplaceWhatFolder="$1";shift
	local lstrCopyFromModelFile="$1";shift
	local lstrCopyFromRelatPath="$1";shift
	
	local lstrPathVanillaAllFiles="${strVanillaAllExtractedFilesPath}/mm/${lstrCopyFromRelatPath}/"

	if [[ ! -f "${lstrPathVanillaAllFiles}/${lstrCopyFromModelFile}.mdl" ]];then
		FUNCechoInfo "[ERROR] file '${lstrPathVanillaAllFiles}/${strModelFile}.mdl' not found, did you extract all vanilla files from all VPKs?"
		exit 1
	fi

	mapfile -t astrFl < <(ls -1 "${lstrPathVanillaAllFiles}/")
	local lstrFl
	for lstrFl in "${astrFl[@]}";do
		mkdir -vp "${lstrReplaceWhatFolder}"
		local lstrFlTo="${lstrReplaceWhatFolder}/${lstrReplaceWhatModelBN}${lstrFl#${lstrCopyFromModelFile}}"
		cp -vf "${lstrPathVanillaAllFiles}/$lstrFl" "$lstrFlTo"
	done
	declare -p lstrReplaceWhatCmdID lstrReplaceWhatModelBN lstrReplaceWhatFolder lstrCopyFromModelFile lstrCopyFromRelatPath >"${lstrReplaceWhatFolder}/readme_Simulating_${lstrCopyFromModelFile}.txt"
	
	astrAliasList+=("alias gskCreateOilJar \"Test_CreateEntity ${lstrReplaceWhatCmdID}\"")
}

FUNCreplace \
	"item_food_bread02_cooked" \
	"bread02_cooked" \
	"models/items/provisions/bread02/" \
	"l6_jar_oil" \
	"models/props/furnitures/gob/l6_jar_oil/" \
	""
	
#strModelFile="bread02_raw"; FUNCreplace "item_food_bread02_row"    "${strModelFile}" "models/props/furnitures/gob/${strModelFile}" "models/items/provisions/bread02/bread02_raw.mdl"

#//ERROR:MissingMDL:models/items/provisions/bread02/bread02_raw.mdl: alias gskSummon_bread02_row "Test_CreateEntity item_food_bread02_row; gskHurtme015; gskSmnWORK" //yes, it is row for the item id and raw for the mdl error on log...
#alias gskSummon_chicken_roasted "Test_CreateEntity item_food_chicken_roasted; gskHurtme015; gskSmnWORK"
#//ERROR:MissingMDL:models/items/provisions/egg/egg.mdl: alias gskSummon_egg "Test_CreateEntity item_food_egg; gskHurtme015; gskSmnWORK"
#//ERROR:MissingMDL:models/items/provisions/food_ratio/food_ratio01.mdl: alias gskSummon_food_ratio01 "Test_CreateEntity item_food_food_ratio01; gskHurtme015; gskSmnWORK"
#//ERROR:MissingMDL:models/items/provisions/garlic/garlic_b1.mdl: alias gskSummon_garlic_piece01 "Test_CreateEntity item_food_garlic_piece01; gskHurtme015; gskSmnWORK"
#//ERROR:MissingMDL:models/items/provisions/garlic/garlic_b2.mdl: alias gskSummon_garlic_piece02 "Test_CreateEntity item_food_garlic_piece02; gskHurtme015; gskSmnWORK"
#//ERROR:MissingMDL:models/items/provisions/garlic/garlic_b3.mdl: alias gskSummon_garlic_piece03 "Test_CreateEntity item_food_garlic_piece03; gskHurtme015; gskSmnWORK"
#//ERROR:MissingMDL:models/items/provisions/fruit/green_apple.mdl: alias gskSummon_green_apple "Test_CreateEntity item_food_green_apple; gskHurtme015; gskSmnWORK"
#//ERROR:MissingMDL:models/items/provisions/leeks/leek02.mdl: alias gskSummon_leek02 "Test_CreateEntity item_food_leek02; gskHurtme015; gskSmnWORK"
#//ERROR:MissingMDL:models/items/provisions/leeks/leek03.mdl: alias gskSummon_leek03 "Test_CreateEntity item_food_leek03; gskHurtme015; gskSmnWORK"
#//ERROR:MissingMDL:models/items/provisions/leeks/leeks.mdl: alias gskSummon_leeks "Test_CreateEntity item_food_leeks; gskHurtme015; gskSmnWORK"
#//TODO:ThisCouldBeSpawnedAtMoreFoes: alias gskSummon_magic_toad "Test_CreateEntity item_food_magic_toad; gskHurtme015; gskSmnWORK"
#//ERROR:MissingMDL:models/items/provisions/mushroom/mushroom_medium.mdl: alias gskSummon_mushroom_medium "Test_CreateEntity item_food_mushroom_medium; gskHurtme015; gskSmnWORK"
#//ERROR:MissingMDL:models/items/provisions/mushroom/mushroom_small.mdl: alias gskSummon_mushroom_small "Test_CreateEntity item_food_mushroom_small; gskHurtme015; gskSmnWORK"
#//ERROR:MissingMDL:models/items/provisions/fruit/red_apple.mdl: alias gskSummon_red_apple "Test_CreateEntity item_food_red_apple; gskHurtme015; gskSmnWORK" //But on L02_A? (before menelag gate) near the hidden combat staff, there is a red apple!!! how??? also in another house there!
#//ERROR:MissingMDL:models/items/provisions/saucisson/saucisson01.mdl: alias gskSummon_saucisson "Test_CreateEntity item_food_saucisson; gskHurtme015; gskSmnWORK"


FUNCrefreshMount # after changes

echo
for strAlias in "${astrAliasList[@]}";do
	echo "${strAlias}"
done
echo
echo "# now place the above aliases in some mod, suggestion: BloodySummoner (will go to a summon list) and may be gskCustomBinds"

