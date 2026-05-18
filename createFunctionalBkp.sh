tar -cvf GSK_ModMerger_AndMiniMods_FullBkp.tar \
	--exclude='./.git' \
	--exclude='./tmp' \
	--exclude='./Extracted.Quick.TMP' \
	--exclude='./GSK_ModMerger_AndMiniMods_Release.tar.7z' \
	--exclude='./GSK_ModMerger_AndMiniMods_FullBkp.tar.7z' \
	.
	
ls -l GSK_ModMerger_AndMiniMods_FullBkp.tar
7z a GSK_ModMerger_AndMiniMods_FullBkp.tar.7z GSK_ModMerger_AndMiniMods_FullBkp.tar
ls -l GSK_ModMerger_AndMiniMods_FullBkp.tar.7z
trash GSK_ModMerger_AndMiniMods_FullBkp.tar
