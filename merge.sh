#!/bin/bash

set -x
if true;then
	# example of configuring easy merging
	# it is configured for my system, customize it to yours.

	if [[ "${1-}" == --all ]];then
		export bFollowFolderLayersOrder=true # for ./prepareAllModsPatchesForScriptFile.sh: this helps by merging last the Overhaul mod that is the last ordered mod folder layer on my system while using OverlayFS.
		export bShowFinalComparison=false # for ./prepareAllModsPatchesForScriptFile.sh: this should be set to 'true', but for a quick test is false. it is important to check all auto merged final result files to grant nothing weird is placed there.
		#allowing updating is more reliable #export bUpdateTodoList=false # for doItAllAutomaticallyIfPossible.sh->findAllConflictingModdedFiles.sh: no need to update it that often. If already merged it will be quickly skipped. Only if mods' order changes or a new one is added, then run it once.
		export KEYVALUE_VERBOSE_OPTIONS="ERRORS_CORRECTED" # for ./keyValuePatcher.py
		./doItAllAutomaticallyIfPossible.sh
		exit 0
	fi

	# single file mode
	export bFollowFolderLayersOrder=true
	./prepareAllModsPatchesForScriptFile.sh "$@"
fi
