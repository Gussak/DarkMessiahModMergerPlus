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

while [[ ! -f "./allMergerScriptsGenericConfig.sh" ]];do cd ..;done; source "./allMergerScriptsGenericConfig.sh"; FUNCminiModInit "$@"

function FUNCwindowHelper() {
	#set -x
	local lnWId=-1
	: ${cmdRemoveWindowDecorations:="windowtweaks"} #help https://gist.github.com/AquariusPower/113f4559a4ac8ccb0225a89b9c74c0ea
	: ${strWindowName:="Wine Desktop"} #help when set to emulate desktop on winecfg it is: "Wine Desktop"
	while true;do
		echo -n .
		sleep 1
		
		lnWId="$(xdotool search "${strWindowName}")"
		if [[ -z "$lnWId" ]];then continue;fi
		
		if which "$cmdRemoveWindowDecorations";then
			"${cmdRemoveWindowDecorations}" -d $lnWId
			echo "decorations OFF"
		fi
		
		break
	done
	
	: ${bAutoClickRun:=false} #help this is not really necessary and may cause trouble if you try to use the mouse or button is not where it wants
	if $bAutoClickRun;then
	if which ScriptEchoColor;then echoc --say "don't touch your mouse please";fi
	read -p "[blind wait the ModLauncher window show up]" -t 5 #TODO try `perceptualdiff` to check if the button is showing there
	
	# continue from ModLaucher button by using mods (blind click)
	: ${nX:=683} #help where the mouse shall be placed to click on the ModLauncher continue button
	: ${nY:=507} #help
	xdotool mousemove $nX $nY;
	xdotool click --window $lnWId 1
	if which ScriptEchoColor;then echoc --say "thanks";fi
	fi
	
	#read -p "[hit a key to exit]" -t 60
};export -f FUNCwindowHelper;

if ! pgrep -fa DMMM_windowHelper;then
	(xterm -title DMMM_windowHelper -e bash -c "while true;do FUNCwindowHelper;done" & disown)
fi
