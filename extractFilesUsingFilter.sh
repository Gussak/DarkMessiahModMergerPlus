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

while [[ ! -f "./allMergerScriptsGenericConfig.sh" ]];do cd ..;done; source "./allMergerScriptsGenericConfig.sh"; FUNCminiModInit "$@"

strMatch="$1" #help if [--all] will extract all files
bAll=false;if [[ "$strMatch" == --all ]];then bAll=true;fi

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

: ${strExtFolder:="${strPathSelf}/Extracted.Quick.TMP"} #help
mkdir -vp "$strExtFolder"

if $bAll;then
	for strFlVpk in "${astrFlVpk[@]}";do
		"$strVpkExec" -x "$strExtFolder" "$strFlVpk"
	done
else
	IFS=$'\n' read -d '' -r -a astrFlEx < <(
		for strFlVpk in "${astrFlVpk[@]}";do
			"$strVpkExec" "$strFlVpk" -l;
		done |egrep "$strMatch" -i |sort -u
	)&&:
	#declare -p astrFlEx |sed -r -e 's@\[@\n\[@g' >&2
	for strFlEx in "${astrFlEx[@]}";do echo "$strFlEx";done

	: ${bDoExtract:=true} #help
	if $bDoExtract;then
		for strFlEx in "${astrFlEx[@]}";do
			for strFlVpk in "${astrFlVpk[@]}";do
				"$strVpkExec" -x "$strExtFolder" --filter "$strFlEx" "$strFlVpk"
			done
		done
	fi
fi
