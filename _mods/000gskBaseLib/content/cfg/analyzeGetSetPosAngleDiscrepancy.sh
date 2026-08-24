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

# to generate, while flying: getpos; copy/paste set...; close console; open console; getpos; ex.:
	#] getpos
	#setpos 2213.215332 -3293.702393 -67.647461;setang 48.241478 -70.745461 -0.008232
	#] setpos 2213.215332 -3293.702393 -67.647461;setang 48.241478 -70.745461 -0.008232
	#(close/open console)
	#] getpos 
	#setpos 2215.900146 -3301.388184 -2.175611;setang 48.246964 -70.745461 -0.007869
	#] clear

: ${bVerbose:=false} #help

# repeated a few times:
astrTestData[l02_b1]='
setpos 2213.215332 -3293.702393 -67.647461;setang 48.241478 -70.745461 -0.008232
setpos 2215.900146 -3301.388184 -2.175611;setang 48.246964 -70.745461 -0.007869
setpos 2218.584961 -3309.074463 63.295425;setang 48.252453 -70.745461 -0.008057
setpos 2221.270020 -3316.761230 128.765701;setang 48.257942 -70.745468 -0.007876
'

astrTestData[l02_b2]='
setpos -3782.283447 -11133.138672 -88.090324;setang 41.272606 78.556099 -0.003627
setpos -3780.784668 -11125.742188 -21.663368;setang 41.277138 78.547577 -0.003626
setpos -3779.285400 -11118.345703 44.762939;setang 41.282627 78.542084 -0.003627
'

apX=()
apY=()
apZ=()
aaX=()
aaY=()
aaZ=()

for strMapIDchk in "${!strMapID[@]}";do echo strMapIDchk;done
: ${strMapID:="l02_b1"} #help
mapfile -t astrLn < <(echo "${astrTestData[${strMapID}]}")

FUNCposAngXYZ() {
	if ! eval "$(echo "$1" |sed -r -e 's@setpos ([0-9.-]*) ([0-9.-]*) ([0-9.-]*)\s*;\s*setang ([0-9.-]*) ([0-9.-]*) ([0-9.-]*)@declare -g pX=\1 pY=\2 pZ=\3 aX=\4 aY=\5 aZ=\6@g')";then
		echo "[ERROR] $0 FUNCposAngXYZ: '$1'" >&2
		exit 1
	fi
}

FUNCfixLine() {
	# NEVER CHANGE THESE VALUES!!! or all prepared spawnings may require to be re-tested!!!
	# To use new values, better create a version in the spawning files like "..._FixPosAngV001.cfg"
	
	# this would be "..._FixPosAngV000.cfg"
	pX="$(bc <<< "${pX} -  2.685")"
	pY="$(bc <<< "${pY} +  7.686")"
	pZ="$(bc <<< "${pZ} - 65.471")"
	aX="$(bc <<< "${aX} -  0.005487")"

	strFixedLine="setpos $pX $pY $pZ;setang $aX $aY $aZ"
	echo "$strFixedLine"
}

if [[ "${1-}" == "-f" ]];then #help <strSetPosAngLineToBeFixed>
	shift
	strSetPosAngLineToBeFixed="$1"
	FUNCposAngXYZ "$strSetPosAngLineToBeFixed"
	if $bVerbose;then echo "$strSetPosAngLineToBeFixed" >&2;fi
	FUNCfixLine
	exit
fi

for((i=0;i<${#astrLn[@]};i++));do
	strLn="${astrLn[$i]}"
	if [[ -z "$strLn" ]];then continue;fi
	
	#strLn="$(echo "$strLn" |sed -r -e 's@setpos ([0-9.-]*) ([0-9.-]*) ([0-9.-]*);setang ([0-9.-]*) ([0-9.-]*) ([0-9.-]*)@pX=\1;pY=\2;pZ=\3;aX=\4;aY=\5;aZ=\6@g')"
	#eval "$strLn"
	FUNCposAngXYZ "$strLn"
	
	declare -p strLn pX pY pZ aX aY aZ >&2
	apX+=($pX)
	apY+=($pY)
	apZ+=($pZ)
	aaX+=($aX)
	aaY+=($aY)
	aaZ+=($aZ)
done

FUNCdiff() {
	while [[ $# -gt 0 ]];do
		declare -n arrayChk="$1"
		eval "declare -p $1"
		
		#AI:
		#Prompts to recreate this chat (selfChatLinkEasySelect)
		#* linux command line to show the flat diff between previous and next number in a list, no matter if increasing or decreasing
		#awk '{ if (NR>1) { print sqrt(($0-prev)^2) } prev=$0 }' input.txt
		#* add signal to the diff if next number  is lower
		#awk '{ if (NR>1) { diff = $0 - prev; print (diff < 0 ? "-" : "") sqrt(diff^2) } prev=$0 }' input.txt
		#* Generate a codebox with a bullet list of only the prompts I have sent you in this conversation. Add this text on it: "Prompts to recreate this chat (selfChatLinkEasySelect)"
		echo "${arrayChk[@]}" |tr ' ' '\n' |awk '{ if (NR>1) { diff = $0 - prev; print (diff < 0 ? "-" : "") sqrt(diff^2) } prev=$0 }'  >&2
		
		shift
	done
}
FUNCdiff apX apY apZ
FUNCdiff aaX aaY aaZ
exit

echo 'Test Result:
	declare -a apX=([0]="2213.215332" [1]="2215.900146" [2]="2218.584961" [3]="2221.270020")
	2.68481
	2.68482
	2.68506
	declare -a apY=([0]="-3293.702393" [1]="-3301.388184" [2]="-3309.074463" [3]="-3316.761230")
	-7.68579
	-7.68628
	-7.68677
	declare -a apZ=([0]="-67.647461" [1]="-2.175611" [2]="63.295425" [3]="128.765701")
	65.4719
	65.471
	65.4703
	declare -a aaX=([0]="48.241478" [1]="48.246964" [2]="48.252453" [3]="48.257942")
	0.005486
	0.005489
	0.005489
	declare -a aaY=([0]="-70.745461" [1]="-70.745461" [2]="-70.745461" [3]="-70.745468")
	0
	0
	-7e-06
	declare -a aaZ=([0]="-0.008232" [1]="-0.007869" [2]="-0.008057" [3]="-0.007876")
	0.000363
	-0.000188
	0.000181
'

#TIP: cat condump.txt |egrep "^\s*classname:" |sort -u |egrep -v "prop_phys|prp_ph|prop_py|prop_dyn" |sed -r -e 's@\s*(classname:)\s*([a-z_]*).*@give \2@g' #for alias +gskDevEntDumpInfoAimed "gskEchoON; ent_setname tmp; ent_dump tmp" //this destroys the item name


# 
#] alias testSetPos "setpos -1900.477661 -4557.024414 366.751709"
#] alias testSetAng "setang 0.428890 -11.012145 0.00605"
#] alias gskWaitPosAng gskWait333ms
#] alias testSetPosAng "testSetPos;testSetAng; gskWaitPosAng; testSetPos;testSetAng; gskWaitPosAng; getpos"
#setpos -1898.316040 -4557.445801 410.743408;setang 0.438047 -11.025432 0.006239
