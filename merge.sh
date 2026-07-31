#!/bin/bash

#set -x
if true;then
	while [[ ! -f "./allMergerScriptsGenericConfig.sh" ]];do cd ..;done; source "./allMergerScriptsGenericConfig.sh"; FUNCminiModInit "$@"
	
	# example of configuring easy merging
	# it is configured for my system, customize it to yours.

	export bFollowFolderLayersOrder=true # for ./prepareAllModsPatchesForScriptFile.sh: this helps by merging last the Overhaul mod that is the last ordered mod folder layer on my system while using OverlayFS.
	export KEYVALUE_VERBOSE_OPTIONS="ERRORS_CORRECTED" # for ./keyValuePatcher.py
	if [[ "${1-}" == "--all" ]];then #help (work on all files possible) every other params after this go for ./doItAllAutomaticallyIfPossible.sh. Without this option, all params go for ./prepareAllModsPatchesForScriptFile.sh to process a single file with some default settings.
		shift
		
		#TODO just copy first file to final merged folder to let the script ./unifiedGameCfg.sh improve it #export strIgnoreSomeFiles="cfg/game.cfg" # for ./doItAllAutomaticallyIfPossible.sh: see ./unifiedGameCfg.sh
		
		export bShowFinalComparison=false # for (./doItAllAutomaticallyIfPossible.sh ->)./prepareAllModsPatchesForScriptFile.sh: this should be set to 'true', but for a quick test is false. it is important to check all auto merged final result files to grant nothing weird is placed there.
		#allowing updating is more reliable #export bUpdateTodoList=false # for doItAllAutomaticallyIfPossible.sh->findAllConflictingModdedFiles.sh: no need to update it that often. If already merged it will be quickly skipped. Only if mods' order changes or a new one is added, then run it once.
		export bMultiThread=true # for ./doItAllAutomaticallyIfPossible.sh
		#export nMultiThreadUsedCores=3 #has auto limit tho # for ./doItAllAutomaticallyIfPossible.sh
		#export nWaitBeforeExiting=10 # for (./doItAllAutomaticallyIfPossible.sh ->)./prepareAllModsPatchesForScriptFile.sh:
		./doItAllAutomaticallyIfPossible.sh "$@"
		#FUNCechoInfo "[IMPORTANT] Now run: ./unifiedGameCfg.sh"
		echo "[IMPORTANT] Now run: ./unifiedGameCfg.sh"
	else
		export bShowFinalComparison=true
		./prepareAllModsPatchesForScriptFile.sh -f "$@"
	fi

fi
