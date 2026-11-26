#!/bin/bash

# SPDX-License-Identifier: Apache-2.0

while [[ ! -f "./allMergerScriptsGenericConfig.sh" ]];do cd ..;done; source "./allMergerScriptsGenericConfig.sh"; FUNCminiModInit "$@"

if [[ "${1-}" != --update ]];then
	echo "Preparing: gskAllCommandsListCycle.cfg"
	$0 --update >gskAllCommandsListCycle.cfg
	cat gskAllCommandsListCycle.cfg
	exit
fi

astrBMCmd=(
	+gskKillTarget
	+gskKillTargetPiercing
	+gskKillBoss
	 gskNpcFullyHeal
	+gskNpcMarkedTelepathy
	+gskNpcMark
	 gskNpcMarkedTeleport
	+gskMagicTorch
	+gskSkillsErase
	+gskTeleMark
	+gskTeleMarkerSelectNext
	 gskTeleMarkerRecall
	+gskTeleMarkerDelete
	+gskTeleportUp
	+gskTeleportTargetPos
	+gskMoveThruWall
	+gskDestroyToMana #please aim at some irrelevant object first like dup weapons
	 gskCreateLifePotionFromOilJar # please aim at an oiljar first..
	+BloodyManaHardCore
	+BloodyAdrenaline
)
mapfile -t astrBMCmd < <(echo "${astrBMCmd[@]}" |tr ' ' "\n" |sort -u)

strFuncPrefix="gskAllCmds"
nLastIndex=$(( ${#astrBMCmd[@]} - 1 ))&&:
echo "// AUTO GENERATED WITH $(basename "$0"), DO NOT EDIT!"
echo
echo "// all cmds: selectable list"
echo
echo "alias +pauseCycleCmds \"pause;\" //to not pause, just erase the alias like: alias +pauseCycleCmds"
echo "alias -pauseCycleCmds \"pause;\" //to not pause, just erase the alias like: alias -pauseCycleCmds"
echo
for((i=0;i<${#astrBMCmd[@]};i++));do
	iPrev=$((i-1))&&:
	if((iPrev==-1));then iPrev=$(( ${#astrBMCmd[@]} - 1 ));fi
	
	iNext=$((i+1))&&:
	if(( iNext == ${#astrBMCmd[@]} ));then iNext=0;fi
	
	#strActivateIndexPrev="${strFuncPrefix}_acti_$( printf %03d $iPrev )"
	#strActivateIndexCurr="${strFuncPrefix}_acti_$( printf %03d $i     )"
	#strActivateIndexNext="${strFuncPrefix}_acti_$( printf %03d $iNext )"
	
	strKeyUpCmd=""
	if [[ "${astrBMCmd[$i]:0:1}" == '+' ]];then
		strKeyUpCmd="-${astrBMCmd[$i]:1}"
	fi
	echo "alias +${strFuncPrefix}_act_$(printf %03d $i) \"${astrBMCmd[$i]}\""
	echo "alias -${strFuncPrefix}_act_$(printf %03d $i) \"${strKeyUpCmd}\""
	
	strExtra=""
	if((i==0));then
		strExtra=" <> <> <> <> (total ${#astrBMCmd[@]}) <> <> <> <> "
	fi
	
	echo "alias +${strFuncPrefix}_sel_$(printf %03d $i) \"\
alias +${strFuncPrefix}_previous +${strFuncPrefix}_sel_$(printf %03d $iPrev); \
alias -${strFuncPrefix}_previous -${strFuncPrefix}_sel_$(printf %03d $iPrev); \
alias +${strFuncPrefix}_activate +${strFuncPrefix}_act_$(printf %03d $i    ); \
alias -${strFuncPrefix}_activate -${strFuncPrefix}_act_$(printf %03d $i    ); \
alias +${strFuncPrefix}_next     +${strFuncPrefix}_sel_$(printf %03d $iNext); \
alias -${strFuncPrefix}_next     -${strFuncPrefix}_sel_$(printf %03d $iNext); \
+pauseCycleCmds; \
gskEchoOn7; \
echo CycleCMD(${i}/${nLastIndex}):${astrBMCmd[$i]}$(FUNCcostHP "${astrBMCmd[$i]}") ${strExtra};\""
	echo "alias -${strFuncPrefix}_sel_$(printf %03d $i) \"gskEchoOff; -pauseCycleCmds\""
	echo
done
echo
echo "// all cmds: selection and activation controls"
echo "alias +${strFuncPrefix}_previous \"+${strFuncPrefix}_sel_000\""
echo "alias +${strFuncPrefix}_activate \"+${strFuncPrefix}_act_000\""
echo "alias +${strFuncPrefix}_next     \"+${strFuncPrefix}_sel_000\""
echo
#echo "// usage:" >&2
#echo "$(basename "$0") >gskAllCommandsListCycle.cfg" >&2

FUNCrefreshMount # after changes
