#!/bin/bash

# For AI that demands code in pdf files.

# AI prompt to tell it to behave: "Output all code as raw text without markdown code blocks. For indentation, use exactly one '.→' per nesting level (e.g., '.→.→' for level 2). For completely empty lines, output exactly one '§'. CRITICAL: Every single comment line starting with '#' must have at least one '.→' prepended to the front of it—even if it is a top-level comment (which will start with '.→#'). This prevents the markdown renderer from turning comments into titles. Every bracket '[ ]', brace '{ }', and parenthesis '( )' must remain standard."

set -Eeu
trap 'read;exit' ERR
#trap 'read;exit' EXIT

if [[ "${1-}" == --help ]];then
	egrep "[#]help" $0
	exit
fi

: ${strFlMainScriptName:="keyValuePatcher"} #help
: ${strMergerTool:="meld"} #help

if ! [[ "${1-}" == --xterm ]];then
	xterm -e "$0" --xterm
	exit
fi

FUNCkey() {
	ls -l "$1"&&:
}
strKeyWTabsDown=""
strKeyWTabsUp=""
while true;do
	
	strKeyWTabsDownNew="$(FUNCkey "${strFlMainScriptName}.AI.010.FakeTabs.RAW.py")"
	if [[ "$strKeyWTabsDownNew" != "$strKeyWTabsDown" ]];then #detects file changed
		echo "[$(date)]"
		
		set -x
		trash "${strFlMainScriptName}.AI.020.RealTabs.py"&&:
		sedEmptyLineMarkerRemove='s@§@@g'
		sedTabMarkerReplace='s@[.][→]@\t@g'
		sedAIbugFix1='s@^[.][→]# /usr/bin/env python3$@#!/usr/bin/env python3@'
		sedAIbugFix2='s@[.] #@\t#@g' # happens just before a explanation comment sometimes. It wont create '.→#' just '. #'
		sed -r \
			-e "$sedAIbugFix1" \
			-e "$sedEmptyLineMarkerRemove" \
			-e "$sedTabMarkerReplace" \
			-e "$sedAIbugFix2" \
			"${strFlMainScriptName}.AI.010.FakeTabs.RAW.py" >"${strFlMainScriptName}.AI.020.RealTabs.py"
		chmod ugo-w "${strFlMainScriptName}.AI.020.RealTabs.py" #grant you wont lose time on it, just merge content into final file thru merger tool
		$strMergerTool "${strFlMainScriptName}.AI.020.RealTabs.py" "${strFlMainScriptName}.py" #no double quotes so you can put params there
		set +x
		
		echo "[$(date)]"
		strKeyWTabsDown="$strKeyWTabsDownNew"
	fi
	
	strKeyWTabsUpNew="$(FUNCkey "${strFlMainScriptName}.py")"
	if [[ "$strKeyWTabsUpNew" != "$strKeyWTabsUp" ]];then #detects file changed
		echo "[$(date)]"
		set -x
		
		sedEraseSpecialComments='s@^#[|]#.*@@g'
		
		sed -r -e "$sedEraseSpecialComments" \
			"${strFlMainScriptName}.py" >"${strFlMainScriptName}.AI.035.RealTabsToReUploadAsPDF.py"
		pango-view --no-display --font="Monospace 10" \
			"${strFlMainScriptName}.AI.035.RealTabsToReUploadAsPDF.py" \
			-o "${strFlMainScriptName}.AI.035.RealTabsToReUploadAsPDF.pdf"
			
		# the AI interprets just normal code above and do the tab and newline tricks later, this is unnecessary
		if false;then
			sedPutEmptyLinesMarkerBack='s@^$@§@g'
			sedReplaceTabsWithFakeMarker='s@\t@.→@g'
			sed -r -e "$sedPutEmptyLinesMarkerBack" -e "$sedReplaceTabsWithFakeMarker" -e "$sedEraseSpecialComments" \
				"${strFlMainScriptName}.py" >"${strFlMainScriptName}.AI.030.WithFakeTabsToReUploadAsPDF.py"
			pango-view --no-display --font="Monospace 10" \
				"${strFlMainScriptName}.AI.030.WithFakeTabsToReUploadAsPDF.py" \
				-o "${strFlMainScriptName}.AI.030.WithFakeTabsToReUploadAsPDF.pdf"
		fi
		
		set +x
		
		strKeyWTabsUp="$strKeyWTabsUpNew"
	fi
	
	echo -ne "[$(date)][Press a key to check again.]\r"
	read -t 1 -n 1&&:
done
