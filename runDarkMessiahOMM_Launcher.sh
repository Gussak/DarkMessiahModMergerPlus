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

if [[ "${1-}" == "--help" ]];then
	egrep "[#]help" $0 #do not use this here yet: while [[ ! -f "./allMergerScriptsGenericConfig.sh" ]];do cd ..;done; source "./allMergerScriptsGenericConfig.sh"; FUNCminiModInit "$@"
	exit 0
fi

export WINEARCH="win32"

############################## INSTANCE
: ${nInstance:=0} #help
if [[ "${1-}" == "-1" ]];then #help first instance
	shift
	nInstance=1
elif [[ "${1-}" == "-2" ]];then #help second instance
	shift
	nInstance=2
fi
if((nInstance==0));then
	while true;do
		read -n 1 -p "FirstOrSecondInstance? 1)First, 2)Second (5s)" nChoice&&:
		case "$nChoice" in
			1)nInstance=1;;
			2)nInstance=2;;
			*)continue;;
		esac
		break
	done
fi
strAutoLoadDefault=""
case "$nInstance" in
	1)
		export WINEPREFIX="$HOME/Wine/DarkMessiahOfMightAndMagic.win32";
		strAutoLoadDefault=forceLoad
		;;
	2)
		export WINEPREFIX="$HOME/Wine/DarkMessiahOfMightAndMagic.win32/DarkMessiahOfMightAndMagic.win32.SecondSimultaneousInstance/";
		strAutoLoadDefault=forceIgnore
		;;
esac

############################# MAIN FOLDER
: ${strExecutable:="mm.exe"} #help
: ${strInstFolder:="$WINEPREFIX/drive_c/Games/Dark Messiah Might and Magic Single Player"} #help this may be an OverlayFS folder tho, and must be already mounted
while [[ ! -f "${strInstFolder}/${strExecutable}" ]];do read -t 3 -p "waiting mount of '${strInstFolder}'"&&:;done
cd "$strInstFolder" 

if [[ -n "$@" ]];then "$@";exit;fi #help you can run other commands with the correct wineprefix, try "bash" to just open a command line

############################ AUTO LOAD SAVEGAME
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
: ${strAutoLoad:=auto} #help # "auto" (let be decided by folder mode), "forceLoad" no matter if main or second instance folder, "forceIgnore" idem
if [[ "$strAutoLoad" == "auto" ]];then
	read -t 60 -n 1 -p "AutoLoadLastSavegame? 0)auto(default=${strAutoLoadDefault}), 1)forceLoad, 2)forceIgnore ($(date) + 60s)" nChoice&&:
	case "$nChoice" in
		0)strAutoLoad=auto;;
		1)strAutoLoad=forceLoad;;
		2)strAutoLoad=forceIgnore;;
		*)strAutoLoad=auto;;
	esac
fi
case "$strAutoLoad" in
	auto)
		case "$nInstance" in
			1)FUNCautoLoadLastSave enable;;
			2)FUNCautoLoadLastSave disable;; # so it can be run imediately as long the game is no being loaded simultaneously to not crash both instances
		esac
		;;
	forceLoad)
		FUNCautoLoadLastSave enable
		;;
	forceIgnore)
		FUNCautoLoadLastSave disable
		;;
	*) echo "INVALID OPTION: $strAutoLoad";read -n 1;;
esac

################################### RUN
astrOptList=(
	-novid #faster start time?
	
	# performance and no crashes. 32bits is limited to 2GB, heapsize increase stability also with the 4gb executable patcher
	-heapsize 2097152 +datacachesize "128" #helps with stability to avoid crashes? these smaller are not good?: 524288 1572864
	+map_background none #prevents loading startupscreen heavy data
	+mat_forcemanagedtextureintohardware 0 #helps prevent some crashes
	
	# hardcore
	+mm_game_easy_difficulty 0 
	+mm_game_hard_difficulty 1 
	+g_cap_difficulty 1 
	
	# just to be sure
	#+exec autoexec.cfg
	
	# game cfg tips from RTX mod (look for updates there)
	+mat_softwarelighting 0 +sv_cheats 1 +r_frustumcullworld 0 +r_portalsopenall 1 +mat_very_high_texture 1 +mat_picmip 0 +mat_colorcorrection 0 +r_drawdetailprops 1 +datacachesize 128 +r_rootlod 0 +r_lod -1 +r_modellodscale 0 +map_background none +r_occlusion 0 +r_PortalTestEnts 0 +r_propsmaxdist 99999
)

#TODO the other instance must be run after the menu of mods show up and is loaded, or the json changes may cause problems, for now just wait manually
wine "$strExecutable" "${astrOptList[@]}"
