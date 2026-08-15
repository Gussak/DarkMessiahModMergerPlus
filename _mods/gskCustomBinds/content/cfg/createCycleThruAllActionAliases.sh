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

if [[ "${1-}" != --update ]];then
	$0 --update >gskAllCommandsListCycle.cfg
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
	+gskTeleMark
	+gskTeleMarkerSelectNext
	gskTeleMarkerRecall
	+gskTeleMarkerDelete
	+gskTeleportUp
	+gskTeleportTargetPos
	+gskMoveThruWall
	+gskDestroyToMana
)

strFuncPrefix="gskAllCmds"
nLastIndex=$(( ${#astrBMCmd[@]} - 1 ))&&:
echo "// AUTO GENERATED WITH $(basename "$0"), DO NOT EDIT!"
echo
echo "// all cmds: selectable list"
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
	
	echo "alias +${strFuncPrefix}_sel_$(printf %03d $i) \"gskEchoOn; \
echo CycleCMD(${i}/${nLastIndex}):${astrBMCmd[$i]}; \
alias +${strFuncPrefix}_previous +${strFuncPrefix}_sel_$(printf %03d $iPrev); \
alias -${strFuncPrefix}_previous -${strFuncPrefix}_sel_$(printf %03d $iPrev); \
alias +${strFuncPrefix}_activate +${strFuncPrefix}_act_$(printf %03d $i    ); \
alias -${strFuncPrefix}_activate -${strFuncPrefix}_act_$(printf %03d $i    ); \
alias +${strFuncPrefix}_next     +${strFuncPrefix}_sel_$(printf %03d $iNext); \
alias -${strFuncPrefix}_next     -${strFuncPrefix}_sel_$(printf %03d $iNext); \
\""
	echo "alias -${strFuncPrefix}_sel_$(printf %03d $i) \"gskEchoOff\""
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
