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

bChkVpkExec=true # for allMergerScriptsGenericConfig.sh
while [[ ! -f "./allMergerScriptsGenericConfig.sh" ]];do cd ..;done; source "./allMergerScriptsGenericConfig.sh"; FUNCminiModInit "$@"

#strExec="$HOME/.local/bin/vpk"
#if [[ ! -f "$strExec" ]];then
	#set -x
	#sudo apt install python3-pip
	#pip install vpk
	#set +x
#fi


#: ${strExtFolder:="${strPathParent}/Dark Messiah Might and Magic Single Player.layer004.VanillaExtractedTextFiles.IGNORE_LAYER"} #help
: ${strExtFolder:="${strVanillaScriptsPath}"} #help

mkdir -vp "$strExtFolder/mm"
if ! cp -vf "${strVanillaLayer}/mm/gameinfo.txt" "$strExtFolder/mm/";then
	FUNCechoInfo "[it is important to copy 'gameinfo.txt' from vanilla folder too as it may be patched and is not present in vpk files]" 
	FUNCexit 1
fi

mkdir -vp "$strExtFolder"
ls "${strVanillaLayer}/vpks/depot_"*"_dir.vpk" |while read strFlDir;do
	"$strVpkExec" -re "$strScriptsExtRegexNorm" -x "$strExtFolder" "$strFlDir"
done

