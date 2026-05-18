#!/bin/bash

set -Eeux

source "./allMergerScriptsGenericConfig.sh"



#TESTS:
function FUNCtst1() {
	strScriptFileRelat="$1"

	strScriptFileRegex=".*/\(${strRegexEscKGMRF}\)/${strScriptFileRelat}\$"
	declare -p strScriptFileRegex

	IFS=$'\n' read -d '' -r -a astrListFoldersLayersOrderOriginal < <(
		find -L "${strPathParent}/" -iregex "${strGameInstallMainFolder}${strScriptFileRegex}" \
			|sort \
			|egrep "[.]layer" \
			|egrep -v "${strRegexFoldersToIgnore}|${strMergedModsFolder}|${strVanillaScriptsPath}|${strVanillaLayer}" \
				2>/dev/null
	)&&:
	echo;declare -p astrListFoldersLayersOrderOriginal |sed -r -e "$strSedArrayLn";echo
}



#EXEC
clear
FUNCtst1 "$@"
