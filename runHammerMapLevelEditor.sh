#!/bin/bash

set -Eeu

egrep "[#]help" "$0"

strSelfBN="$(basename "$0")"
pwd
if [[ ! -f "./${strSelfBN}" ]];then
	cd "$(dirname "$0")"
	pwd
	if [[ ! -f "../Dark Messiah Might and Magic Single Player/mm.exe" ]];then
		echo "ERROR: unable to find mm.exe"
		exit 1
	fi
fi

mkdir -vp "../Might and Magic Dark Messiah SDK"
cd "../Might and Magic Dark Messiah SDK"
pwd

: ${strBaseWindowsPath:='C:\Games'} #help
: ${strWindowsPathDMMM:="${strBaseWindowsPath}"'\Dark Messiah Might and Magic Single Player'} #help
: ${strWindowsPathSDK:="${strBaseWindowsPath}"'\Might and Magic Dark Messiah SDK'} #help

echo 'INFO:
	Based on instructions from: https://developer.valvesoftware.com/wiki/Dark_Messiah:_Single-Player_Level_Creation/SourceSDK
	
	The materials, models, scripts, shaders and resource folders are all the plain files from the full vpk extraction (I found no gcf files).
		When coping the files asked there to the SDK, overwrite all!
	From wine explorer.exe, navigate and copy the full path there into the GameConfig.txt (so no need to use windows env vars with %...%) like:
		C:\Games\Might and Magic Dark Messiah SDK
		C:\Games\Dark Messiah Might and Magic Single Player
	TODO: auto copy all files from these folders thru this script
	
	TIPS:
		l02_b1.vmf is the first good combat region ouside at menelag house.
		Maximize one of the 4 views and click inside it on  the top left corner into 3D shaded.
		To navigate on the map like in flying mode, toggle mouselook with Z key and use WASD (the mouse scroll can move forward and back too). Arrows keys to look around.
		On the right there is VisGroups, go on Auto and deselect all you can to unclutter.
		To add NPCs click on EntityTool icon on the left, then on the right Category/Entity and then a Object/npc...
'

strBkp="GameConfig.txt.$(basename "$0").bkp"
if [[ ! -f "bin/${strBkp}" ]];then
	cp -v "bin/GameConfig.txt" "bin/${strBkp}"
	echo '
"Configs"
{
	"SDKVersion"		"1"
	
	"Games"
	{
		"Dark Messiah"
		{
			"GameDir"		"'"${strWindowsPathDMMM}"'\mm"
			"hammer"
			{
				"GameData0"		"'"${strWindowsPathSDK}"'\bin\base.fgd"
				"GameData1"		"'"${strWindowsPathSDK}"'\bin\halflife2.fgd"
				"BSP"					"'"${strWindowsPathSDK}"'\bin\vbsp.exe"
				"Vis"					"'"${strWindowsPathSDK}"'\bin\vvis.exe"
				"Light"				"'"${strWindowsPathSDK}"'\bin\vrad.exe"
				"MapDir"			"'"${strWindowsPathSDK}"'\mm_content\mapsrc"
				"TextureFormat"		"5"
				"MapFormat"		"4"
				"DefaultTextureScale"		"0.250000"
				"DefaultLightmapScale"		"16"
				"DefaultSolidEntity"		"func_detail"
				"DefaultPointEntity"		"info_player_start"
				"GameExe"			"'"${strWindowsPathDMMM}"'\mm.exe"
				"GameExeDir"	"'"${strWindowsPathDMMM}"'"
				"BSPDir"			"'"${strWindowsPathDMMM}"'\mm\maps"
				"CordonTexture"		"tools\toolsskybox"
				"MaterialExcludeCount"		"0"
			}
		}
	}
}
' >bin/GameConfig.txt
fi

while [[ ! -f "mm/materials/editor/flatnocull.vmt" ]];do
	echo '
 For the "flatnocull.vmt", open a web browser and paste this "steam://install/218" that is "Source SDK Base 2007". It will then call the steam app to install it (3.8GB?). Check also "https://help.steampowered.com/en/wizard/HelpWithGame/?appid=218" on web browser.
 There is also Source SDK 2013 steam://install/243730 (7.5GB?).
 Obs.: But AI can also create an equivalent file for you (it will understand the context and the requirements by the filename. if you have problems, describe the problems and the AI will patch it), prompt: show me the contents of a file that does the equivalent to "flatnocull.vmt" required to run hammer.exe for dark messiah
'
done

export WINEARCH="win32"
export WINEPREFIX="$HOME/Wine/DarkMessiahOfMightAndMagic.win32"; #for now sync manually with launcher script #TODO automate this
export WINEDLLOVERRIDES="d3d9=b" #needs this otherwise it crashes

# some maybe tests only.. (not tested, was AI suggestions)
#export PROTON_USE_WINED3D=1
# Define your game and hammer paths (Adjust the Steam path if you installed it elsewhere)
#GAME_DIR="$HOME/Wine/DarkMessiahOfMightAndMagic.win32/drive_c/Games/Dark Messiah Might and Magic Single Player"
#HAMMER_EXE="$HOME/Wine/DarkMessiahOfMightAndMagic.win32/drive_c/Games/Might and Magic Dark Messiah SDK/bin/hammer.exe"
# 1. Force native WineD3D (OpenGL translation) instead of Vulkan to fix frozen frames
#export WINED3D_DISABLE_EXT_PALETTE=1
# 2. Prevent window focus drops in Ubuntu's GNOME desktop environment
#export XLIB_SKIP_ARGB_VISUALS=1

if [[ -n "$@" ]];then #help run custom command instead
	"$@"
else
	# 3. Launch Hammer targeting the Dark Messiah mod directory using system Wine
	#wine "$HAMMER_EXE" -dxlevel 90 -game "$GAME_DIR/mm"
	wine "bin/hammer.exe" -dxlevel 90
fi
