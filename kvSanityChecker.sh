#!/bin/bash

# BSD 3-Clause License
#
# Copyright (c) 2026, Gussak<https://github.com/Gussak>
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice, this
#  list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice,
#  this list of conditions and the following disclaimer in the documentation
#  and/or other materials provided with the distribution.
#
# 3. Neither the name of the copyright holder nor the names of its
#  contributors may be used to endorse or promote products derived from
#  this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# AI gen WIP

while [[ ! -f "./allMergerScriptsGenericConfig.sh" ]];do cd ..;done; source "./allMergerScriptsGenericConfig.sh"; FUNCminiModInit "$@"

#help tip: run at least this only for crucial brackets: clear;bChkBOM=false bChkStdQuotes=false bChkCurlyQuotes=false ./kvSanityChecker.sh ../Dark\ Messiah\ Might\ and\ Magic\ Single\ Player/_mods/FinalMergedScriptsMaxPriority/
#help tip: symple check all layers with ./kvSanityChecker.sh .. #will log all possible problems (remember overrides only need fixing)
#TODO try to auto fix problems thru the merger scripts?

TARGET_DIR="."
strFlIn=""
if [[ -f "${1-}" ]];then
	strFlIn="$1" #help
elif [[ -d "${1-}" ]];then
	TARGET_DIR="$1"
fi

strFlLog="$(basename "$0").log"
FUNCtrash "$strFlLog"
echo -n >"$strFlLog"

# Target directory defaults to current directory if not specified
#TARGET_DIR="${1:-.}"

echo "==================================================" >&2
echo "Scanning for Source Engine KeyValue errors in: $TARGET_DIR" >&2
echo "==================================================" >&2

astrFlList=()
if [[ -f "$strFlIn" ]];then
	astrFlList=("$strFlIn")
else
	: ${strMatchGlob:="*.ain|*.cfg|*.dat|*.gam|*.lst|*.qc|*.qct|*.rc|*.res|*.scr|*.smd|*.txt|*.vcd|*.vdf|*.vmt"} #help
	: ${strExcludeGrepRegex:="demoheader.tmp.*|.Trash|condump*.txt"} #help
	
	acmdFind=()
	mapfile -t -d '|' astrMathList < <(echo "$strMatchGlob")
	for strMath in "${astrMathList[@]}";do
		if((${#acmdFind[*]} > 0));then acmdFind+=(-o);fi
		acmdFind+=(-name "$strMath")
	done
	# Find all common text/config extensions used by the Source Engine
	mapfile -t astrFlList < <(find "$TARGET_DIR" -type f \( "${acmdFind[@]}" \) |egrep -v "$strExcludeGrepRegex")
fi

nTotErr=0
astrFlProblemList=()
astrFlPBracketList=()
for file in "${astrFlList[@]}";do
	 
	# Flag to track if the current file has issues
	HAS_ERROR=0
	ERROR_MSG=""

	# Read the file's BOM to see if it's UTF-16 LE
	hexBOM="$(head -c 2 "$file" | xxd -p 2>/dev/null)"

	# Create a temporary UTF-8 text stream for grep/tr/wc tools to process safely
	if [[ "$hexBOM" == "fffe" ]]; then
			# File is UTF-16 LE: Decode it to UTF-8 dynamically
			file_content=$(iconv -f UTF-16LE -t UTF-8 "$file" 2>/dev/null)
	else
			# File is already standard: Read it as-is
			file_content=$(cat "$file")
	fi

	: ${bChkBOM:=true} #help
	if $bChkBOM;then
	 # 1. Check for UTF-8 with BOM or standard UTF-16 Encoding
	 file_type=$(file -b "$file")
	 # Allow fffe (UTF-16 LE with BOM) explicitly as requested, block others
	 if [[ "$hexBOM" == "fffe" ]]; then
			: 
	 elif [[ "$file_type" == *"UTF-16"* ]]; then
			if [[ "$file" =~ mm_.*_english.txt ]];then
					:
			else
					((HAS_ERROR++))&&:
					ERROR_MSG+="\n -> [ENCODING] Invalid encoding format: '$file_type' (Engine requires ANSI/UTF-8 or UTF-16 LE with BOM)"
					echo "${file} # ERROR: ENCODING" >>"$strFlLog"
			fi
	 fi
	fi

	: ${bChkCurlyQuotes:=true} #help
	if $bChkCurlyQuotes;then
	 # 2. Check for Smart/Curly Quotes in the sanitized content stream
	 if echo "$file_content" | grep -q -P "[\x{201C}\x{201D}\x{2018}\x{2019}]" 2>/dev/null; then
		 ((HAS_ERROR++))&&:
		 smart_lines=$(echo "$file_content" | grep -n -P "[\x{201C}\x{201D}\x{2018}\x{2019}]" | awk -F: '{print $1}' | paste -sd, -)
		 ERROR_MSG+="\n -> [QUOTES] Smart/Curly quotes detected on line(s): $smart_lines"
		 echo "${file} # ERROR: [QUOTES] Smart/Curly" >>"$strFlLog"
	 fi
	fi

	: ${bChkStdQuotes:=true} #help
	if $bChkStdQuotes;then
	 # 3. Check for Odd Numbers of Standard Quotes using sanitized content stream
	 quote_count=$(echo "$file_content" | tr -cd '"' | wc -c)
	 if (( quote_count % 2 != 0 )); then
		 ((HAS_ERROR++))&&:
		 ERROR_MSG+="\n -> [QUOTES] Uneven number of straight quotes ($quote_count total). An asset path is unclosed."
		 echo "${file} # ERROR: [QUOTES] Uneven $quote_count" >>"$strFlLog"
	 fi
	fi

	: ${bChkBracket:=true} #help
	if $bChkBracket;then
	 # 4. Check Bracket Balance using sanitized content stream
	 open_brackets=$(echo "$file_content" | tr -cd '{' | wc -c)
	 close_brackets=$(echo "$file_content" | tr -cd '}' | wc -c)
	 if (( open_brackets != close_brackets )); then
		 ((HAS_ERROR++))&&:
		 ERROR_MSG+="\n -> [SYNTAX] Mismatched curly brackets! (Found $open_brackets '{' and $close_brackets '}')"
		 astrFlPBracketList+=("${file}")
		 echo "${file} # ERROR(CRITICAL!): [SYNTAX] Mismatched curly brackets! (Found $open_brackets '{' and $close_brackets '}')" >>"$strFlLog"
	 fi
	fi

	# Print results if errors were caught
	if [ $HAS_ERROR -gt 0 ]; then
		echo -e "\n\033[0;31m[CRITICAL]\033[0m Issues found in:" >&2
		echo "${file}" 
		astrFlProblemList+=("${file}")
		echo -e "$ERROR_MSG" >&2
		echo >&2
	else
		echo -n . >&2
	fi
	((nTotErr+=HAS_ERROR))&&:
done


#declare -p astrFlProblemList astrFlPBracketList >&2

echo "Checking for fixed overrides:"
for strFl in "${astrFlProblemList[@]}";do
	strFlBN="$(basename "$strFl")"
	echo "Checking: $strFlBN" >&2
	if ! find "${strMergedModsFolder}/" -iname "$strFlBN" >/dev/null;then
		echo "[WARN] this file may not have a fixed override:" >&2
		echo "$strFl #IMPORTANT"
	fi
done
#for strFl in "${astrFlPBracketList[@]}";do
	#strFlBN="$(basename "$strFl")"
	#if ! find "${strMergedModsFolder}/" -iname "$strFlBN";then
		#echo "[WARN] this file may not have a fixed override:" >&2
		#echo "$strFl"
	#fi
#done

echo -e "\n==================================================" >&2
echo "Scan complete (total errors $nTotErr)." >&2
echo "==================================================" >&2

if [ $HAS_ERROR -gt 0 ]; then
	exit 1
fi
exit 0
