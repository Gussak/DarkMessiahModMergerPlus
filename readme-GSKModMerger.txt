# DarkMessiahModMergerPlus
Scripts to help merging DarkMessiahMM on Linux or expectedly CygWin too (for Windows). Plus mini mods.

Main idea is no free powers for the challenge. As I found no way to spend mana, all costs goes to HP thru `hurtme` cmd.    
You have to roleplay a highly challenging scenario, because you end up with access to full developer commands, so if you can't hold yourself about cheating, do not use this mod.    
Every map will be chaotic requiring careful resources management and sometime thinking on the best tactics (and several reloads muahaha xD).   

(This is WIP. The work scripts are being tested yet. If you have problems open an issue.)

___

This mod can be used to merge all other mods' scripts and text files thru diff, patch and merge apps.

Keep 'FinalMergedScriptsTopPriority' as last entry at '_mods/core/user_settings.json' of [Mod Launcher](https://github.com/KingDavidW/DarkMessiah-ModLauncher-Files).
___

# Key Value patcher

Use the python script `keyValuePatcher.py` to prepare Key Value based patches.   
They are very flexible.   
They are not like Code patches, they are just used to seek for a key and set it's value in the final file.  
They work at least for .qct and some .txt files too.  
I will describe it better later if needed.  
So your mod can be just a list of Keys and Values, and not an overriding file that erases other mods' file with lower priority in load order.  
They look like this in a json file ex.:
`npc_necroguard.qct.kvpatch`
```
{
    "$keyvalues.entity_data.level_1.npc_health": "378",
    "$keyvalues.entity_data.npc_health": "378"
}
```
As you can see, the script will seek for that nested key to set the value. and with `keyValuePatcher.py apply -a ...` it can append missing Keys, so nothing is lost or ignored.  
`keyValuePatcher.py` is generic and can be used for any file of any game or application.  
It detects nested structures with '{' ... '}', but these can also be set to other delimiters easily if needed by editing `keyValuePatcher.py`.  

___

The executable scripts are for Linux but can be run on Windows thru CygWin (check [Nice cygwin tips at 3.1 section.](https://www.nexusmods.com/7daystodie/mods/14?tab=description) ).   

To patch all mods into final merged files, it requires mods to be extracted and placed as folder layers at the same level the main game folder is.   

___

# Mod Patcher Usage (`bash` scripts)

1) There is a script to help you extract all text and script files from all vanilla VPK game data files.   
	 Vanilla script data files are necessary for the merger to work properly.   
	 It will is only necessary to merge when 2 or more modded files are present, otherwise a single mod script file will always win.   
	 `./extractVanillaScriptsTextsFromVPKs.sh`   
	
1.1) Now, to reconstruct my mini mods into final files that can be used directly OR merged with other mods, run this:
	 `strFilter="GSK_ModMerger_AndMiniMods" ./reconstructWorkFilesFromLonePatches.sh`
	 The filter must contain at least a unique part of the name of the folder where this project was extracted.  
	 Without the filter, it will try to reconstruct all not already reconstructed files from other mod folders that contain '.patch' files.  
	
2) Merging (or jump to (3)):
	
2.1) Install all mods into such layer folders and run:   
	 `./findAllConflictingModdedFiles.sh`   
	 This will find all files that need to be merged so yo get all features of all of them in a single final file.   
	 
2.2) prepare each merged final file running, ex.:   
	 `./prepareAllModsPatchesForScriptFile.sh scripts/spells.txt`   
	
3) Easier merging it all:     
	
3.1) this will do it all. Already prepared merged files will be skipped. Changes will be detected (like changing mod order or adding a new one with conflicting mergeable (mime type "text") files)      
	 `./doItAllAutomaticallyIfPossible.sh`     
	
3.2) OR read `merge.sh` contents, it is customized for my system. Customize it to yours:      
	 `./merge.sh --all`    
	 
Obs.: when the patch is based in a mod and not game vanilla extracted files, they use a cfg that ends with *.Vanilla.cfg to indicate what they were based on

___

Optional(Linux): OverlayFS can be run on these layers creating one writable folder, but just to prepare the merged files, it is not necessary.

If you have any tip that could make the merging proccess easier, mainly to non coders, just tell me thx! :)

___

Example of OverlayFS folders (I used ScriptEchoColor's `secOverrideMultiLayerMountPoint.sh` but you can do it manually too):

	Dark Messiah Might and Magic Single Player.layer000.TEMPLATE.IGNORE_LAYER #this is used to easily copy and create layers
	Dark Messiah Might and Magic Single Player.layer003.Vanilla #game files
	Dark Messiah Might and Magic Single Player.layer004.VanillaExtractedTextFiles.IGNORE_LAYER #this layer isnt necessary as all of it is at Vanilla compressed layer vpk files
	Dark Messiah Might and Magic Single Player.layer015.dm_advancedsdk_r10212
	Dark Messiah Might and Magic Single Player.layer020.ModLauncher_wos_dm_modlauncher_r10816_fixed
	Dark Messiah Might and Magic Single Player.layer030.mm-unlimitededition-1-4-1_all_in_one.1
	Dark Messiah Might and Magic Single Player.layer993.GSK_ModMerger_AndMiniMods
	
This structure is necessary also to let the merger scripts work properly. But you need to properly place each mod's extracted files inside them by following their instructions to create paths like `mm/scripts/...`, this way the merger script will know what to do. Any difficulties I can give tips.

Important! after editing files in the mod's folders layers, umount and remount or OverlayFS may fail!

___

# To create mods:

Run `reconstructWorkFilesFromLonePatches.sh`, it will use the patches and vanilla files to recreate the modded full file for that specific patch by it's side.   
Now, to further patch, edit the modded file (not the patch file).   
Before applying the patch with `prepareAllModsPatchesForScriptFile.sh` into the final merged folder, it will be recreated based on the changes of the modded file relatively to the vanilla file.

To create a new mod (or add a new modded file), copy the vanilla file, modify it and run the patcher `prepareAllModsPatchesForScriptFile.sh`, it will then create the patch file for the first time.

___

LINUX(troubleShutting):
<details>
  <summary>if trying to move and the game keeps toggling pause:</summary>
  
  Basically (on console):
  ```
  mat_antialias 0
  // unfocus the game into another app and wait it's sound kick in again, check if it worked. may need several seconds
  mat_antialias 4
  ```
  
  or run on console or bind `gskFixPauseBug` from `gskBaseLib.cfg` [000gskBaseLib](https://github.com/Gussak/DarkMessiahModMergerPlus/tree/main/_mods/000gskBaseLib) into some key
</details>
