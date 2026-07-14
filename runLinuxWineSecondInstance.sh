#!/bin/bash

echo '
	Goal: no wait time after being defeated, instantly continue playing, no loading game waiting anymore!
	
	I guess this works only on Linux while using Wine to play Windows games (like in, 2 instances of the native same game on Linux will not even start the second instance, and the same will happen on Windows, but thru Wine it is another thing!).
	
	Main
		WINEPREFIX="$HOME/Wine/DarkMessiahOfMightAndMagic.win32"
		Setup it completely so the game runs perfectly.
		
	Create a new WINEPREFIX folder, like
		WINEPREFIX="$HOME/Wine/DarkMessiahOfMightAndMagic.win32/DarkMessiahOfMightAndMagic.win32.SecondSimultaneousInstance"
		Copy all folders from MAIN here, least ".../drive_c/.../Dark Messiah Might and Magic Single Player".
		That game folder will just be a symlink on the new WINEPREFIX.
		Just run the 2nd instance while the first is already running.
		You have to keep the background instance in sync with the latest savegame, so use it mainly when you reach a difficult area, like in, after MAIN finishes loading, put the 2nd instance to load (dont load together or both will crash).
		Now, when you are defeated put it to load and just switch to the other already loaded instance!
		
		TODO: May be, create a new folder to let the 2nd instance write files? but from tests, even overwriting the same files from the main instance, I still detected no problems yet.
		TODO: try to sync the game loadings to happen only after the other is not loading thru SIGSTOP. The quick.sav creation could be detected and trigger an auto load on the background instance thru like "xdotool type F9" macro on that window.
'

./runDarkMessiahOMM_Launcher.sh -2 "$@"
