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

while [[ ! -f "./allMergerScriptsGenericConfig.sh" ]];do cd ..;done; source "./allMergerScriptsGenericConfig.sh"; FUNCminiModInit "$@"

: ${bVerbose:=false};export bVerbose #help

: ${strTextHint:="hltv_status|maxplayers|player_death"};export strTextHint #help this shows up on the last writing to that file, after that you only need to wait for 5s!

: ${strFlHint:="${strGameInstallMainFolder}/${strGameSubRelatFolderWriteAllHere}/demoheader.tmp"};export strFlHint #help the hint file is never recreated. It stays there, it seems to be emptied and receive new fresh data, so it's creation time is useless.

: ${nIgnoreTinyStringsSize:=10};export nIgnoreTinyStringsSize #help these tiny strings are probably useless here TODO: just filter out if not: [0-9a-zA-Z_]*

function FUNCdetectPidToPause() { # the one that has no focus
	#set -x
	nWFocId="$(xdotool getwindowfocus)"&&:
	nWFocNm="$(xdotool getwindowname $nWFocId)"&&:
	nWFocPid="$(xdotool getwindowpid $nWFocId)"&&:
	
	bPauseAll=false
	if ! strWineprefixWFocus="$(strings /proc/$nWFocPid/environ |grep WINEPREFIX)";then
		bPauseAll=true;
	fi
	
	# multidimentional array simulated: [PidGM] = PidFM WindowID WINEPREFIX (the link between them is WINEPREFIX)
	declare -g anPidGm=($(pgrep -f "Dark Messiah.*mm.exe"))
	declare -g aPidGm_PidFM=() # the PidFM is from explorer.exe (filemanager FM) and not from the game as wine is running in desktop single window mode
	declare -g aPidGm_WindowID=()
	declare -g aPidGm_WINEPREFIX=()
	declare -g aPidGm_bFocus=()
	
	for nPidGm in "${anPidGm[@]}";do
		strWineprefixGm="$(strings /proc/$nPidGm/environ |grep WINEPREFIX)"
		aPidGm_WINEPREFIX[$nPidGm]="$strWineprefixGm"
	done
	
	mapfile -t astrLn < <(wmctrl -l -p |grep "Wine Desktop" |awk '{print "_nW=" $1 ";_nPidFM=" $3 ";"}')
	for strLn in "${astrLn[@]}";do eval "${strLn}";
		strWineprefixFm="$(strings /proc/$_nPidFM/environ |grep WINEPREFIX)"
		#for((i=0;i<${#aPidGm_WINEPREFIX[@]};i++));do
		#echo "DEBUG:${!aPidGm_WINEPREFIX[@]}"
		#declare -p _nPidFM _nW
		for nPidGm in ${!aPidGm_WINEPREFIX[@]};do
			#echo "if [[ \"$strWineprefixFm\" == \"${aPidGm_WINEPREFIX[$nPidGm]}\" ]];then"
			if [[ "$strWineprefixFm" == "${aPidGm_WINEPREFIX[$nPidGm]}" ]];then
				aPidGm_PidFM[$nPidGm]="$_nPidFM"
				aPidGm_WindowID[$nPidGm]="$(printf %d $_nW)"
				if((nWFocId==${aPidGm_WindowID[$nPidGm]}));then aPidGm_bFocus[$nPidGm]=true; else aPidGm_bFocus[$nPidGm]=false; fi
			fi
		done
		#declare -p aPidGm_PidFM
	done
	
	#nPidGmExecFocus=0
	##for((i=0;i<${#anPidGm[@]};i++));do
	#for nPidGm in "${anPidGm[@]}";do
		#strWineprefixGm="$(strings /proc/$nPidGm/environ |grep WINEPREFIX)"
		#if [[ "$strWineprefixGm" == "$strWineprefixWFocus" ]];then
			#nPidGmExecFocus=$nPidGm
			#break;
		#fi
	#done
	#nPidGmExecOther=0
	#for nPidGm in "${anPidGm[@]}";do
		#if((nPidGmExecFocus == nPidGm));then continue;fi
		#nPidGmExecOther=$nPidGm
		#break;
	#done
	
	#declare -p nWFocId nWNm nWPid anPidGm nPidGmExecFocus >&2
	if $bVerbose;then
		declare -p anPidGm aPidGm_PidFM aPidGm_WindowID aPidGm_WINEPREFIX aPidGm_bFocus bVerbose
	fi
	
	#declare -g FUNCdetectPidToPause_nPidGmNoFocus=$nPidGmExecOther
	#declare -g FUNCdetectPidToPause_nWindowNoFocus=$nWindowOther
};export -f FUNCdetectPidToPause

function FUNCtest() {
	FUNCdetectPidToPause
}
if [[ "${1-}" == --test ]];then FUNCtest;exit;fi

function FUNCstringsDump() { #help <index> use this to dump demoheader.tmp strings for clues
	local lstrFlSnapshot="${1}"; #help the backup index generated by ... . must be like ex.: 000000007 (fixed 9 decimal places with zeros on the left)
	strings "${lstrFlSnapshot}" \
		|tr -d ' \t\r' \
		|sed -r -e 's@^.{1,'${nIgnoreTinyStringsSize}'}$@@g' \
		|sort -u >"${lstrFlSnapshot}.Strings.txt"
};export -f FUNCstringsDump
function FUNCmonitorChanges() {
	local lfLoopDelay
	: ${lfLoopDelay:=0.33} #help_FUNCmonitorChanges
	
	local lstrFlNewest="$(ls -1tr "${strFlHint}.SnapShot_ID_"*".bkp" |tail -n 1)"&&:
	#local lstrFlNewest="$(ls -1 "${strFlHint}.SnapShot_ID_"*".bkp" |sort |tail -n 1)"&&:
	declare -p lstrFlNewest
	
	# init with newest file
	local lnID=0
	if [[ -n "$lstrFlNewest" ]];then
		#local lnID="${lstrFlNewest#${strFlHint}.}"
		lnID="$(echo "$lstrFlNewest" |sed -r -e 's@.*[.]SnapShot_ID_([0-9]*)[.].*@\1@')"
		declare -p lnID
		lnID=$((10#$lnID))
		((lnID++))&&: #next
		declare -p lnID
	fi
	
	local lnSz=0;
	local lnIndex=0
	local lstrFlSnapshotPrev=""
	while true;do 
		local lnSzNew=$(stat -c %s "$strFlHint");
		#local lnDtTm=$(stat -c %W "$strFlHint"); # creation time
		local lnDtTmNew=$(stat -c %Y "$strFlHint"); # modification time
		if(( lnSz != lnSzNew || lnDtTm != lnDtTmNew));then
			# loop control
			lnSz=$lnSzNew;
			lnDtTm=$lnDtTmNew
			
			echo
			
			local lstrID="$(printf %09d $lnID)"
			local lstrIndex="$(printf %09d $lnIndex)"
			local lstrFlSnapshot="${strFlHint}.SnapShot_ID_${lstrID}.Index_${lstrIndex}.bkp"
			cp -vf "$strFlHint" "$lstrFlSnapshot";
			
			FUNCstringsDump "${lstrFlSnapshot}"
			
			((lnIndex++))&&:;
			#ls --time-style=full-iso -l "$strFlHint"*"${lstrIndex}"*;
			ls --time-style=full-iso -l "${lstrFlSnapshotPrev}.Strings.txt" "${lstrFlSnapshot}.Strings.txt" &&:
			
			#clear;mapfile -t aFl < <(ls -1tr "${strFlHint}.SnapShot_ID_1777875194.Index_"*".bkp.Strings.txt");for strFl in "${aFl[@]}";do echo; ls --time-style=full-iso -l "$strFl"; comm -13 "$strFlPrev" "$strFl"; strFlPrev="$strFl"; done
			if [[ -f "$lstrFlSnapshotPrev" ]];then set -x; comm -13 "${lstrFlSnapshotPrev}.Strings.txt" "${lstrFlSnapshot}.Strings.txt" &&:; set +x; fi
			
			# prepare next
			if egrep "${strTextHint}" "$strFlHint";then
				((lnID++))&&: # begin next hint detection
				lnIndex=0
			fi
			
			lstrFlSnapshotPrev="$lstrFlSnapshot"
		fi;
		
		sleep ${lfLoopDelay};
	done
};export -f FUNCmonitorChanges

iMonCh=0
if [[ "${1-}" == "-m" ]];then shift;iMonCh=1;fi #help monitor changes and dump strings xterm
if [[ "${1-}" == "-M" ]];then shift;iMonCh=2;fi #help monitor changes and dump strings
case $iMonCh in
	1)
		if ! pgrep -fa DarkMessiah_FUNCmonitorChanges;then
			(xterm -maximized -title DarkMessiah_FUNCmonitorChanges -e FUNCmonitorChanges & disown)
		fi
		;;
	2) FUNCmonitorChanges;exit;;
	*);;
esac

export nScrWhalf=$(($(xdotool getdisplaygeometry |awk '{print $1}') / 2 ))

function FUNCpauseAfterLoad() {
	: ${bPauseOnlyNoFocusInstance:=false} #help :D
	while true;do
		nThisRunTime=$(date +%s)
		while true;do
			echo -ne "=============================== $(date) ================================\r"
			sleep 1
			
			FUNCdetectPidToPause
			#anPidGm=($(pgrep -f "C:[\].*[\]mm.exe"))
			
			: ${bExitIfGameExits:=false} #help
			if $bExitIfGameExits;then
				if ! ps -p ${anPidGm[@]};then exit;fi
			fi
			
			: ${bTestFoundHint:=false} #help
			if ! $bTestFoundHint;then
				if(( $(stat -c %Y "$strFlHint") < nThisRunTime ));then
					continue
				fi
				
				if ! egrep --quiet "${strTextHint}" "$strFlHint";then
					continue
				fi
			fi
			
			: ${fSleepAfterHintFound:=3.0} #help
			read -n 1 -t $fSleepAfterHintFound -p "hit a key to SIGSTOP game"&&:
			
			#FUNCdetectPidToPause
			for nPidGm in "${anPidGm[@]}";do #use case for 2 instances only
				#if $bPauseOnlyNoFocusInstance && ((FUNCdetectPidToPause_nPidNoFocus != 0 && nPidGm != FUNCdetectPidToPause_nPidNoFocus));then continue;fi
				if $bPauseOnlyNoFocusInstance && ${aPidGm_bFocus[$nPidGm]};then continue;fi # ignores focused window
				
				kill -SIGSTOP $nPidGm
				if which ScriptEchoColor;then echoc --say "Game Loaded";fi
				#while ! yad --title="DarkMessiah:helper" --text="Dark Messiah of MM\n Game Finished Loading\n SigStopped\n Continue NOW?" --geometry=1x1+$nScrWhalf+0 --undecorated;do :;done; # not --on-top because it cant be too small :(
				#while ! yad --geometry=1x1+$nScrWhalf+0 --title="DarkMessiah:helper" --center --no-buttons;do :;done; # not --on-top because it cant be too small :(
				
				export strTitle="DarkMessiah:FinishedLoading:${nPidGm}"
				function FUNCminimizePopup() {
					while true;do
						if nWIdPopup="$(wmctrl -l |grep "$strTitle" |awk '{print $1}')";then
							#sleep 1 # or the window will not be read to be minized..
							xdotool windowminimize --sync $(printf %d $nWIdPopup)&&:
							break
						fi
						sleep 0.33
					done
				}
				FUNCminimizePopup&

				yad --geometry=500x1+$nScrWhalf+0 --title="$strTitle" --on-top --no-buttons --no-focus &&: #unable to popup below :(, it should not receive imediate focus but should be focusable!!! unable to prevent it starting --on-top, so keep it there; no buttons, just hold the flow here
				kill -SIGCONT $nPidGm
				
				set -x
				xdotool windowactivate ${aPidGm_WindowID[$nPidGm]}
				xdotool windowfocus    ${aPidGm_WindowID[$nPidGm]}
				set +x
			done
			
			break # to update nThisRunTime for the next game load
		done
	done
};export -f FUNCpauseAfterLoad;

#set -x
if ! pgrep -fa DarkMessiah_FUNCpauseAfterLoad;then
	: ${bXterm:=true}
	if $bXterm;then
		(xterm -maximized -title DarkMessiah_FUNCpauseAfterLoad -e bash -c "FUNCpauseAfterLoad" & disown);
	else
		FUNCpauseAfterLoad
	fi
else
	echo "already running"
fi
