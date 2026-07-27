#!/bin/bash

# 7z wont restore symlinks

astrFlNot=(
	'*.log' '*.bkp' "*.NEWLY_PATCHED"	"*.NEWLY_PATCHED.rej" '*.SUCCESS.cfg' # temp files
	#	'*.qct' patched are ok like a backup
	'./.git' 
	'./tmp' 
	'./Extracted.Quick.TMP' 
	'./GSK_ModMerger_AndMiniMods_Release*' 
	'./GSK_ModMerger_AndMiniMods_FullBkp*' 
	'./Dark Messiah Might and Magic Single Player.layer*' 
	'./__pycache__' 
	'./_SaveGamesWithNPCsAdded' 
)
strRegexExclude="dummy"
for strFlNot in "${astrFlNot[@]}";do
	strRegexExclude+="|$(echo "${strFlNot}" |sed -r -e 's@[.]@[.]@g' -e 's@[*]@.*@g')"
done
declare -p strRegexExclude
mapfile -t astrFlList < <(find ./ -type f -or -xtype f |egrep -v "${strRegexExclude}" |sort)

strFlZ="GSK_ModMerger_AndMiniMods_FullBkp.zip"

ls -l "$strFlZ"&&:
trash -v "$strFlZ"&&:

zip -y9 "$strFlZ" "${astrFlList[@]}"
unzip -l "$strFlZ"
ls -l "$strFlZ"
