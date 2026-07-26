#!/bin/bash

# AI gen WIP

TARGET_DIR="."
strFlIn=""
if [[ -f "${1-}" ]];then
	strFlIn="$1" #help
elif [[ -d "${1-}" ]];then
	TARGET_DIR="$1"
fi


# Target directory defaults to current directory if not specified
#TARGET_DIR="${1:-.}"

echo "=================================================="
echo "Scanning for Source Engine KeyValue errors in: $TARGET_DIR"
echo "=================================================="

astrFlList=()
if [[ -f "$strFlIn" ]];then
	astrFlList=("$strFlIn")
else
	# Find all common text/config extensions used by the Source Engine
	mapfile -t astrFlList < <(find "$TARGET_DIR" -type f \( -name "*.cfg" -o -name "*.res" -o -name "*.txt" -o -name "*.vmt" \))
fi

nTotErr=0
for file in "${astrFlList[@]}";do
    
    # Flag to track if the current file has issues
    HAS_ERROR=0
    ERROR_MSG=""

    # 1. Check for UTF-8 with BOM or UTF-16 Encoding
    # Source Engine prefers plain ANSI or raw UTF-8 (without BOM)
    hexBOM="$(head -c 2 "$file" | xxd -p)"
    file_type=$(file -b "$file")
    #if [[ "$file_type" == *"BOM"* || "$file_type" == *"UTF-16"* ]]; then
    if [[ "$hexBOM" == "fffe" || "$file_type" == *"UTF-16"* ]]; then
				if [[ "$file" =~ mm_.*_english.txt ]];then
					:
				else
					((HAS_ERROR++))&&:
					ERROR_MSG+="\n  -> [ENCODING] Invalid encoding format: '$file_type' (Engine requires ANSI/UTF-8 without BOM)"
				fi
    fi

    # 2. Check for Smart/Curly Quotes (copied from browsers/Word)
    # Character codes: E2 80 9C (“), E2 80 9D (”), E2 80 98 (‘), E2 80 99 (’)
    if grep -q -P "[\x{201C}\x{201D}\x{2018}\x{2019}]" "$file" 2>/dev/null; then
        ((HAS_ERROR++))&&:
        smart_lines=$(grep -n -P "[\x{201C}\x{201D}\x{2018}\x{2019}]" "$file" | awk -F: '{print $1}' | paste -sd, -)
        ERROR_MSG+="\n  -> [QUOTES] Smart/Curly quotes detected on line(s): $smart_lines"
    fi

    # 3. Check for Odd Numbers of Standard Quotes (unclosed quote blocks)
    # Counts total standard double quotes and checks if the remainder is odd
    quote_count=$(tr -cd '"' < "$file" | wc -c)
    if (( quote_count % 2 != 0 )); then
        ((HAS_ERROR++))&&:
        ERROR_MSG+="\n  -> [QUOTES] Uneven number of straight quotes ($quote_count total). An asset path is unclosed."
    fi

    # 4. Check Bracket Balance (Nested KeyValues structure)
    open_brackets=$(tr -cd '{' < "$file" | wc -c)
    close_brackets=$(tr -cd '}' < "$file" | wc -c)
    if (( open_brackets != close_brackets )); then
        ((HAS_ERROR++))&&:
        ERROR_MSG+="\n  -> [SYNTAX] Mismatched curly brackets! (Found $open_brackets '{' and $close_brackets '}')"
    fi

    # Print results if errors were caught
    if [ $HAS_ERROR -gt 0 ]; then
        echo -e "\n\033[0;31m[CRITICAL]\033[0m Issues found in: $file"
        echo -e "$ERROR_MSG"
        echo
    else
			echo -ne "OK: $file <> <> <>\r"
    fi
		
		((nTotErr+=HAS_ERROR))&&:
done

echo -e "\n=================================================="
echo "Scan complete (total errors $nTotErr)."
echo "=================================================="

if [ $HAS_ERROR -gt 0 ]; then
	exit 1
fi
exit 0
