#!/bin/bash

#do not use this here yet: while [[ ! -f "./allMergerScriptsGenericConfig.sh" ]];do cd ..;done; source "./allMergerScriptsGenericConfig.sh"; FUNCminiModInit "$@"

export WINEARCH="win32"

b2ndInst=false
if [[ "${1-}" == "-2" ]];then #help second instance
	shift
	b2ndInst=true
	export WINEPREFIX="$HOME/Wine/DarkMessiahOfMightAndMagic.win32/DarkMessiahOfMightAndMagic.win32.SecondSimultaneousInstance/"
else
	export WINEPREFIX="$HOME/Wine/DarkMessiahOfMightAndMagic.win32"
fi

: ${strExecutable:="mm.exe"} #help
: ${strInstFolder:="$WINEPREFIX/drive_c/Games/Dark Messiah Might and Magic Single Player"} #help this may be an OverlayFS folder tho, and must be already mounted
while [[ ! -f "${strInstFolder}/${strExecutable}" ]];do read -t 3 -p "waiting mount of '${strInstFolder}'"&&:;done
cd "$strInstFolder" 

function FUNCautoLoadLastSave() {
	strFl="_mods/core/user_settings.json"
	if [[ "$1" == enable ]];then
		# removing from ignore will activate it
		jq '.ignore -= ["AutoLoadLastQuickSave"]' "$strFl" | sponge "$strFl"
	else #disable
		# adding to ignore will deactivate it on the list
		jq '.ignore += ["AutoLoadLastQuickSave"]' "$strFl" | sponge "$strFl"
	fi
}
if $b2ndInst;then
	FUNCautoLoadLastSave disable # so it can be run imediately as long the game is no being loaded simultaneously to not crash both instances
else
	FUNCautoLoadLastSave enable
fi

if [[ -n "$@" ]];then "$@";exit;fi #help you can run other commands with the correct wineprefix

astrOptList=(
	-novid #faster start time?
	
	# performance and no crashes. 32bits is limited to 2GB, heapsize increase stability also with the 4gb executable patcher
	-heapsize 2097152 +datacachesize "128" #helps with stability to avoid crashes? not good?: 524288 1572864
	+map_background none #prevents loading startupscreen heavy data
	+mat_forcemanagedtextureintohardware 0 #helps prevent some crashes
	
	# hardcore
	+mm_game_easy_difficulty 0 
	+mm_game_hard_difficulty 1 
	+g_cap_difficulty 1 
	
	# just to be sure
	#+exec autoexec.cfg
	
	# game cfg tips from RTX mod
	+mat_softwarelighting 0 +sv_cheats 1 +r_frustumcullworld 0 +r_portalsopenall 1 +mat_very_high_texture 1 +mat_picmip 0 +mat_colorcorrection 0 +r_drawdetailprops 1 +datacachesize 128 +r_rootlod 0 +r_lod -1 +r_modellodscale 0 +map_background none +r_occlusion 0 +r_PortalTestEnts 0 +r_propsmaxdist 99999
)

#TODO the other instance must be run after the menu of mods show up and is loaded, or the json changes may cause problems, for now just wait manually
wine "$strExecutable" "${astrOptList[@]}"
