#!/bin/bash

# The Clear BSD License
#
# Copyright (c) 2026, Gussak<https://github.com/Gussak>
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted (subject to the limitations in the disclaimer
# below) provided that the following conditions are met:
#
#      * Redistributions of source code must retain the above copyright notice,
#      this list of conditions and the following disclaimer.
#
#      * Redistributions in binary form must reproduce the above copyright
#      notice, this list of conditions and the following disclaimer in the
#      documentation and/or other materials provided with the distribution.
#
#      * Neither the name of the copyright holder nor the names of its
#      contributors may be used to endorse or promote products derived from this
#      software without specific prior written permission.
#
# NO EXPRESS OR IMPLIED LICENSES TO ANY PARTY'S PATENT RIGHTS ARE GRANTED BY
# THIS LICENSE. THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND
# CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
# PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
# BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER
# IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.


#we cant ex.: alias gskHurtMeFUNC hurtme, then use gskHurtMeFUNC 3, it wont work

: ${nHurtMeLim:=28} #help
: ${nLineLim:=1024} #help

# line limit is 1024 chars
function FUNCchkLineSz() {
	local lstr="$1"
	if((${#lstr} > nLineLim));then echo "[ERROR:${FUNCNAME[@]}:${BASH_LINENO[@]}] line too big ${#lstr} '${lstr}'";exit 1;fi
}

function FUNCerasers() {
	local lstrMainEraser="$1";shift
	local lstrToEraseBN="$1";shift
	local lnFrom="$1";shift
	local lnTo="$1";shift
	
	local lstrEraser="alias ${lstrMainEraser} \""
	for((i=lnFrom;i<=lnTo;i++));do
		lstrEraser+="alias ${lstrToEraseBN}$(printf %03d $i);"
	done
	if [[ "$lstrMainEraser" == gskHMHurtmeEraser1of3 ]];then
		lstrEraser+="alias gskHurtme500;"
	fi
	lstrEraser+="\""
	FUNCchkLineSz "$lstrEraser"
	echo "$lstrEraser"
}

function FUNChurmeLim() {
	local lstr
	for((j=0;j<$1;j++));do
		lstr+="hurtme ${nHurtMeLim}; gskWait33ms; "
	done
	FUNCchkLineSz "$lstr"
	echo "$lstr"
}

echo "// from $(basename "$0")"
for((i=1;i<=nHurtMeLim;i++));do #map hurtme without jumping is 28
	echo "alias gskHurtme$(printf %03d $i) \"hurtme $i\""
done
for((i=29;i<=100;i++));do #map hurtme without jumping is 28, and needs a minimum wait to properly work
	if((  i < (${nHurtMeLim}*1) ));then
		echo "alias gskHurtme$(printf %03d $i) \"$(FUNChurmeLim 1); hurtme $(( i - nHurtMeLim*(1-1) ))\""
	elif((i < (${nHurtMeLim}*2) ));then
		echo "alias gskHurtme$(printf %03d $i) \"$(FUNChurmeLim 1); hurtme $(( i - nHurtMeLim*(2-1) ))\""
	elif((i < (${nHurtMeLim}*3) ));then
		echo "alias gskHurtme$(printf %03d $i) \"$(FUNChurmeLim 2); hurtme $(( i - nHurtMeLim*(3-1) ))\""
	elif((i < (${nHurtMeLim}*4) ));then
		echo "alias gskHurtme$(printf %03d $i) \"$(FUNChurmeLim 3); hurtme $(( i - nHurtMeLim*(4-1) ))\""
	fi
done
echo "alias gskHurtme500 \"$( FUNChurmeLim $((500/${nHurtMeLim})) ); hurtme $(( 500 - ((500/${nHurtMeLim})*${nHurtMeLim}) )); \""
FUNCerasers gskHMHurtmeEraser1of3 "gskHurtme"  1  33
FUNCerasers gskHMHurtmeEraser2of3 "gskHurtme" 34  66
FUNCerasers gskHMHurtmeEraser3of3 "gskHurtme" 67 100

################
echo "// from $(basename "$0")"
for((i=1;i<=10;i++));do
	echo "alias gskManaReg$(printf %03d $i) \"mm_player_time_to_add_mana 0.$(printf %02d $i)\""
done
FUNCerasers "gskManaRegEraser" "gskManaReg" 1 10
