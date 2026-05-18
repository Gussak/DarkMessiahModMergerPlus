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

source "./allMergerScriptsGenericConfig.sh"

strMatch="$1" #help

bChkVpkExec=true

#strExec="$HOME/.local/bin/vpk"
#if [[ ! -f "$strExec" ]];then
	#set -x
	#sudo apt install python3-pip
	#pip install vpk
	#set +x
#fi

#cd "${strPathParent}"/*Vanilla*/vpks/ ########################################
cd "${strVanillaLayer}/vpks/" ########################################
IFS=$'\n' read -d '' -r -a astrFlVpk < <(ls *_dir.vpk)&&:
declare -p astrFlVpk |sed -r -e 's@\[@\n\[@g' >&2

IFS=$'\n' read -d '' -r -a astrFlEx < <(
	for strFlVpk in "${astrFlVpk[@]}";do
		"$strVpkExec" "$strFlVpk" -l;
	done |egrep "$strMatch" -i |sort -u
)&&:
#declare -p astrFlEx |sed -r -e 's@\[@\n\[@g' >&2
for strFlEx in "${astrFlEx[@]}";do echo "$strFlEx";done

: ${bDoExtract:=true} #help
if $bDoExtract;then
	: ${strExtFolder:="${strPathSelf}/Extracted.Quick.TMP"} #help
	mkdir -vp "$strExtFolder"
	for strFlEx in "${astrFlEx[@]}";do
		for strFlVpk in "${astrFlVpk[@]}";do
			"$strVpkExec" -x "$strExtFolder" --filter "$strFlEx" "$strFlVpk"
		done
	done
fi
