#!/bin/bash

#	BSD 3-Clause License
#
#	Copyright (c) 2026, Gussak
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

set -Eeu
trap 'read -p ExitingOrNot;exit' ERR
#trap 'read;exit' EXIT

if [[ "${1-}" == --help ]];then
	echo "For AI that demands code in pdf files."
	echo "AI prompt to tell it to behave:"
	echo "Output all code as raw text without markdown code blocks. For indentation, use exactly one '.→' per nesting level (e.g., '.→.→' for level 2). For completely empty lines, output exactly one '§'. CRITICAL: Every single comment line starting with '#' must have at least one '.→' prepended to the front of it—even if it is a top-level comment (which will start with '.→#'). This prevents the markdown renderer from turning comments into titles. Every bracket '[ ]', brace '{ }', and parenthesis '( )' must remain standard."
	egrep "[#]help" $0
	exit
fi
#: ${bXterm:=true} #help
#if $bXterm;then
	#(xterm -e $0 "$@" & disown)
	#exit 0
#fi

if [[ $# -gt 0 ]] && [[ -f "$1" ]];then
	if [[ "$1" =~ .*[.](sh|py|cpp)$ ]];then
		strFlFullScriptName="$1"
		shift
		strFlMainScriptName="$(echo "$strFlFullScriptName" |sed -r -e 's@(.*)[.]([^.]*)@\1@g')"
		strFlMainScriptExt="$( echo "$strFlFullScriptName" |sed -r -e 's@(.*)[.]([^.]*)@\2@g')"
	fi
fi

: ${strFlMainScriptName:="keyValuePatcher"};export strFlMainScriptName #help
: ${strFlMainScriptExt:="py"};export strFlMainScriptExt #help
: ${strMergerTool:="meld"};export strMergerTool #help

FUNCkey() {
	ls -l "$1"&&:
}
strKeyWTabsDown=""
strKeyWTabsUp=""
while true;do
	echo "[INFO]  <> <> <> JUST PRESS ENTER <> <> <>"
	
	strKeyWTabsDownNew="$(FUNCkey "${strFlMainScriptName}.AI.010.FakeTabs.RAW.${strFlMainScriptExt}")"
	if [[ "$strKeyWTabsDownNew" != "$strKeyWTabsDown" ]];then #detects file changed
		echo "[$(date)]"
		
		set -x
		trash "${strFlMainScriptName}.AI.020.RealTabs.${strFlMainScriptExt}"&&:
		sedEmptyLineMarkerRemove='s@§@@g'
		sedTabMarkerReplace='s@[.][→]@\t@g'
		sedAIbugFix1='s@^[.][→]# /usr/bin/env python3$@#!/usr/bin/env python3@'
		sedAIbugFix2='s@[.] #@\t#@g' # happens just before a explanation comment sometimes. It wont create '.→#' just '. #'
		sed -r \
			-e "$sedAIbugFix1" \
			-e "$sedEmptyLineMarkerRemove" \
			-e "$sedTabMarkerReplace" \
			-e "$sedAIbugFix2" \
			"${strFlMainScriptName}.AI.010.FakeTabs.RAW.${strFlMainScriptExt}" >"${strFlMainScriptName}.AI.020.RealTabs.${strFlMainScriptExt}"
		chmod ugo-w "${strFlMainScriptName}.AI.020.RealTabs.${strFlMainScriptExt}" #grant you wont lose time on it, just merge content into final file thru merger tool
		$strMergerTool "${strFlMainScriptName}.AI.020.RealTabs.${strFlMainScriptExt}" "${strFlMainScriptName}.${strFlMainScriptExt}" #no double quotes so you can put params there
		set +x
		
		echo "[$(date)]"
		strKeyWTabsDown="$strKeyWTabsDownNew"
	fi
	
	strKeyWTabsUpNew="$(FUNCkey "${strFlMainScriptName}.${strFlMainScriptExt}")"
	if [[ "$strKeyWTabsUpNew" != "$strKeyWTabsUp" ]];then #detects file changed
		echo "[$(date)]"
		set -x
		
		sedEraseSpecialComments='s@^#[|]#.*@@g'
		
		sed -r -e "$sedEraseSpecialComments" \
			"${strFlMainScriptName}.${strFlMainScriptExt}" >"${strFlMainScriptName}.AI.035.RealTabsToReUploadAsPDF.${strFlMainScriptExt}"
		pango-view --no-display --font="Monospace 10" \
			"${strFlMainScriptName}.AI.035.RealTabsToReUploadAsPDF.${strFlMainScriptExt}" \
			-o "${strFlMainScriptName}.AI.035.RealTabsToReUploadAsPDF.pdf"
			
		# the AI interprets just normal code above and do the tab and newline tricks later, this is unnecessary
		if false;then
			sedPutEmptyLinesMarkerBack='s@^$@§@g'
			sedReplaceTabsWithFakeMarker='s@\t@.→@g'
			sed -r -e "$sedPutEmptyLinesMarkerBack" -e "$sedReplaceTabsWithFakeMarker" -e "$sedEraseSpecialComments" \
				"${strFlMainScriptName}.${strFlMainScriptExt}" >"${strFlMainScriptName}.AI.030.WithFakeTabsToReUploadAsPDF.${strFlMainScriptExt}"
			pango-view --no-display --font="Monospace 10" \
				"${strFlMainScriptName}.AI.030.WithFakeTabsToReUploadAsPDF.${strFlMainScriptExt}" \
				-o "${strFlMainScriptName}.AI.030.WithFakeTabsToReUploadAsPDF.pdf"
		fi
		
		set +x
		
		strKeyWTabsUp="$strKeyWTabsUpNew"
	fi
	
	echo -ne "[$(date)][Press a key to check again.]\r"
	read -p "$LINENO" -t 1 -n 1&&:
done
