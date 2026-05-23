#!/usr/bin/env python3

#|#	BSD 3-Clause License
#|#
#|#	Copyright (c) 2026, Gussak<https://github.com/Gussak>
#|#
#|#	Redistribution and use in source and binary forms, with or without
#|#	modification, are permitted provided that the following conditions are met:
#|#
#|#	1. Redistributions of source code must retain the above copyright notice, this
#|#	 list of conditions and the following disclaimer.
#|#
#|#	2. Redistributions in binary form must reproduce the above copyright notice,
#|#	 this list of conditions and the following disclaimer in the documentation
#|#	 and/or other materials provided with the distribution.
#|#
#|#	3. Neither the name of the copyright holder nor the names of its
#|#	 contributors may be used to endorse or promote products derived from
#|#	 this software without specific prior written permission.
#|#
#|#	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
#|#	AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
#|#	IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
#|#	DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
#|#	FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
#|#	DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
#|#	SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
#|#	CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
#|#	OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
#|#	OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

"""
KeyValue Patcher for Dark Messiah .qct files

Example usage:
    ./keyValuePatcher.py create base.qct modded.qct -o weapon_tweak.kvpatch.json
    ./keyValuePatcher.py apply target.qct weapon_tweak.kvpatch.json
    ./keyValuePatcher.py create --help
    ./keyValuePatcher.py apply --help
"""

import argparse
import json
import os
import re
import sys
import traceback
from collections import defaultdict

# ==========================================
# CONFIGURATION & CONSTANTS
# ==========================================
NESTING_OPEN = os.getenv("KEYVALUE_NESTING_OPEN", "{")
NESTING_CLOSE = os.getenv("KEYVALUE_NESTING_CLOSE", "}")
LINE_ENDING = os.getenv("KEYVALUE_LINE_ENDING", '\r\n')
DEBUG = os.getenv("KEYVALUE_DEBUG", 'n')

# Verbosity levels
"""will show fail proof fixed error corrected data"""
VERBOSE_FIXED_STUFF = 10
"""will show tests to track bugs"""
VERBOSE_BUG_TRACKING = 20
"""will show data that helps to understand the tests"""
VERBOSE_HELPER_DATA = 30
"""will show everything being done (fully verbose)"""
VERBOSE_FULL = 1000

# Compiled regex patterns (reused across functions)
KV_PATTERN = re.compile(r'^("[^"]*")\s+("[^"]*")$')
BLOCK_PATTERN = re.compile(r'^\s*"?([^"\s//]+)"?\s*$')
BLOCK_PATTERN_EXTENDED = re.compile(r'^\s*"?([^"\s//{}]+)"?\s*$')

def get_verbosity_level():
	"""Parses KEYVALUE_VERBOSE env var into an integer level."""
	val = os.environ.get("KEYVALUE_VERBOSE", "").strip().lower()
	if not val or val == "false" or val == "0":
		return 0
	if val == "true" or val == "1":
		return 1
	try:
		return int(val)
	except ValueError:
		return 0  # Fallback for invalid non-numeric strings

"""The values below can be kept unchanged and others added in between TODO: it would be better to use strings, and check what kind of output we want, so we could mix them arbitrarily instead of showing all above a certain value."""
VERBOSE_LEVEL = get_verbosity_level()

# ==========================================
# HELPER FUNCTIONS
# ==========================================

def strip_inline_comment(line):
	"""Remove inline comments safely for clean regex evaluation."""
	if "//" in line:
		return line.split("//", 1)[0].strip()
	return line.strip()

class ValidationError(Exception):
	"""Raised when a line cannot be validated."""
	def __init__(self, file_path, line_num, line_content, message):
		self.file_path = file_path
		self.line_num = line_num
		self.line_content = line_content
		self.message = message
		super().__init__(f"{file_path}:{line_num}: {message}\n{line_content}")

def clean_and_validate_for_kv(file_path, line_num, line):
	"""
	Validates and cleans a key-value line.
	Returns cleaned line or raises ValidationError.
	"""
	# 1. Strip whitespace and handle comments/empty lines
	clean = line.strip()
	if not clean or clean.startswith('//'):
		if VERBOSE_LEVEL >= VERBOSE_FULL:
			print(f"[DIAGNOSTIC] Empty or fully commented line: '{line.strip()}'")
		return ""
	
	if '//' in clean:
		clean = clean.split('//', 1)[0].strip()
	
	# 2. Check if it already matches perfectly
	if KV_PATTERN.match(clean):
		if VERBOSE_LEVEL >= VERBOSE_FULL:
			print(f"[DIAGNOSTIC] Line is perfectly valid: {clean}")
		return clean
	
	# 3. AUTO-CLEANING ATTEMPT
	raw_text = clean.strip('" ;,')
	parts = [p.strip('" ;,') for p in re.split(r'[\s",;]+', raw_text) if p]
	
	# 4. RETRY if we isolated exactly two valid parts
	if len(parts) == 2:
		reconstructed = f'"{parts[0]}" "{parts[1]}"'
		if VERBOSE_LEVEL >= VERBOSE_FIXED_STUFF:
			print(f"{file_path}:{line_num}:\n{line}\n{reconstructed}")
		return reconstructed
	
	# 5. UNRECOVERABLE
	raise ValidationError(
		file_path, line_num, line,
		f"Unrecoverable format. Found {len(parts)} parts instead of 2"
	)

def parse_qct_to_dict(file_path):
	"""Parses a Valve KeyValues .qct file into a nested Python dictionary."""
	with open(file_path, 'r', encoding='utf-8', errors='ignore', newline='') as f:
		lines = f.readlines()

	root = {}
	stack = [root]
	last_block_key = None
	
	for line_num, line in enumerate(lines, 1):
		stripped = line.strip()
		if not stripped or stripped.startswith("//"):
			continue
		
		clean_line = strip_inline_comment(line)
		if not clean_line:
			continue
		
		if clean_line == NESTING_OPEN:
			if last_block_key is not None:
				new_block = {}
				stack[-1][last_block_key] = new_block
				stack.append(new_block)
				last_block_key = None
			continue
		
		if clean_line == NESTING_CLOSE:
			if len(stack) > 1:
				stack.pop()
			continue
		
		block_match = BLOCK_PATTERN.match(clean_line)
		if block_match:
			last_block_key = block_match.group(1).strip('"')
			continue
		
		try:
			clean_line_for_kv = clean_and_validate_for_kv(file_path, line_num, clean_line)
		except ValidationError as e:
			print("[STACK TRACE]", file=sys.stderr)
			traceback.print_exc(file=sys.stderr)
			sys.exit(2)
		
		kv_match = KV_PATTERN.match(clean_line_for_kv)
		if kv_match:
			key, val = kv_match.groups()
			stack[-1][key] = val
			last_block_key = None
			continue
	
	return root

def flatten_dict(d, current_path="", result=None):
	"""Flattens a nested dictionary into dot-notated absolute paths."""
	if result is None:
		result = {}
	for key, value in d.items():
		new_path = f"{current_path}.{key}" if current_path else key
		if isinstance(value, dict):
			flatten_dict(value, new_path, result)
		else:
			result[new_path] = value
	return result

def find_block_structure(lines):
	"""
	Scans file once to identify block positions.
	Returns dict mapping block paths to (open_index, close_index).
	"""
	current_stack = []
	last_block_key = None
	open_braces = {}
	close_braces = {}
	
	for idx, line in enumerate(lines):
		stripped = line.strip()
		if not stripped or stripped.startswith("//"):
			continue
		
		clean_line = strip_inline_comment(line)
		if not clean_line:
			continue
		
		if clean_line == NESTING_OPEN:
			if last_block_key is not None:
				current_stack.append(last_block_key)
				open_braces[tuple(current_stack)] = idx
				last_block_key = None
			continue
		
		if clean_line == NESTING_CLOSE:
			if current_stack:
				close_braces[tuple(current_stack)] = idx
				current_stack.pop()
			continue
		
		block_match = BLOCK_PATTERN_EXTENDED.match(clean_line)
		if block_match:
			last_block_key = block_match.group(1).strip('"')
		else:
			last_block_key = None
	
	return open_braces, close_braces

def append_nested_missing(lines, missing_patches):
	"""
	Groups and injects missing configurations by tracking structural depth.
	Prevents line index corruption when adding multiple options.
	"""
	# Group missing properties by their parent blocks
	grouped_patches = defaultdict(list)
	for full_path, new_value in missing_patches.items():
		parts = full_path.split('.')
		target_hierarchy = tuple(parts[:-1])
		key_name = parts[-1]
		grouped_patches[target_hierarchy].append((key_name, new_value))
	
	# Process group entries systematically
	for target_hierarchy, items in grouped_patches.items():
		open_braces, close_braces = find_block_structure(lines)
		
		# Find deepest matching block
		matched_depth = 0
		for depth in range(len(target_hierarchy), 0, -1):
			check_path = target_hierarchy[:depth]
			if check_path in open_braces and check_path in close_braces:
				matched_depth = depth
				break
		
		new_lines = []
		if matched_depth == 0:
			# No existing structure; create from scratch
			insert_idx = len(lines)
			for i, part in enumerate(target_hierarchy):
				tabs = "\t" * i
				new_lines.append(f'{tabs}"{part}"{LINE_ENDING}')
				new_lines.append(f'{tabs}{{{LINE_ENDING}')
			
			final_tabs = "\t" * len(target_hierarchy)
			for key_name, new_value in items:
				new_lines.append(f'{final_tabs}"{key_name}"\t\t"{new_value}"{LINE_ENDING}')
			
			for i in range(len(target_hierarchy) - 1, -1, -1):
				tabs = "\t" * i
				new_lines.append(f'{tabs}}}{LINE_ENDING}')
		else:
			# Extend existing structure
			matched_path = target_hierarchy[:matched_depth]
			missing_structure = target_hierarchy[matched_depth:]
			insert_idx = close_braces[matched_path]
			base_tabs = len(matched_path)
			
			for i, part in enumerate(missing_structure):
				tabs = "\t" * (base_tabs + i)
				new_lines.append(f'{tabs}"{part}"{LINE_ENDING}')
				new_lines.append(f'{tabs}{{{LINE_ENDING}')
			
			final_tabs = "\t" * (base_tabs + len(missing_structure))
			for key_name, new_value in items:
				new_lines.append(f'{final_tabs}"{key_name}"\t\t"{new_value}"{LINE_ENDING}')
			
			for i in range(len(missing_structure) - 1, -1, -1):
				tabs = "\t" * (base_tabs + i)
				new_lines.append(f'{tabs}}}{LINE_ENDING}')
		
		lines[insert_idx:insert_idx] = new_lines
	
	return lines

# ==========================================
# COMMAND IMPLEMENTATIONS
# ==========================================

def handle_create(args):
	"""Generates a patch JSON file by comparing original and modified configs."""
	if not os.path.exists(args.original):
		print(f"Error: Original file '{args.original}' not found.", file=sys.stderr)
		sys.exit(2)
	if not os.path.exists(args.modified):
		print(f"Error: Modified file '{args.modified}' not found.", file=sys.stderr)
		sys.exit(2)
	
	print(f"Parsing original: {args.original}")
	orig_tree = flatten_dict(parse_qct_to_dict(args.original))
	
	print(f"Parsing modified: {args.modified}")
	mod_tree = flatten_dict(parse_qct_to_dict(args.modified))
	
	patch_data = {}
	for path, mod_value in mod_tree.items():
		if path not in orig_tree or orig_tree[path] != mod_value:
			patch_data[path] = mod_value
	
	output_destination = args.output
	if output_destination == "patch.json" or output_destination.startswith("patch.json"):
		output_destination = args.modified + ".kvpatch.json"
	
	try:
		with open(output_destination, 'w', encoding='utf-8') as f:
			json.dump(patch_data, f, indent=4)
			f.write(LINE_ENDING)
	except IOError as e:
		print(f"Error writing output file: {e}", file=sys.stderr)
		sys.exit(2)
	
	print(f"\nSuccess! Found {len(patch_data)} changes. Saved to:\n '{output_destination}'")
	""">0 changes found; 0 no changes found, files are probably identical in final results. unless there is a second setting for the same var value with a different value and the final engine reading it overwrites the first value read with the last found. But that is a file manual preparation bug. TODO? but this patcher could create overrides by always appending even if there is a var there what would work but is overkill."""
	sys.exit(1 if len(patch_data) > 0 else 0)

def handle_apply(args):
	"""Applies a patch JSON file onto a target config file."""
	if not os.path.exists(args.target):
		print(f"Error: Target file '{args.target}' not found.", file=sys.stderr)
		sys.exit(2)
	if not os.path.exists(args.patch):
		print(f"Error: Patch file '{args.patch}' not found.", file=sys.stderr)
		sys.exit(2)
	
	try:
		with open(args.patch, 'r', encoding='utf-8') as f:
			patches = json.load(f)
	except json.JSONDecodeError as e:
		print(f"Error: Invalid JSON in patch file: {e}", file=sys.stderr)
		sys.exit(2)
	except IOError as e:
		print(f"Error reading patch file: {e}", file=sys.stderr)
		sys.exit(2)
	
	with open(args.target, 'r', encoding='utf-8', errors='ignore') as f:
		lines = f.readlines()
	
	current_stack = []
	output_lines = []
	applied_keys = set()
	
	last_block_key = None
	print(f"Applying patches from '{args.patch}' onto '{args.target}'...")
	
	if VERBOSE_LEVEL >= VERBOSE_HELPER_DATA:
		print(f"{patches}")
	
	for line_num, line in enumerate(lines, 1):
		# Normalize line endings
		line = line.rstrip('\r\n') + LINE_ENDING
		stripped = line.strip()
		
		if stripped == NESTING_OPEN:
			if last_block_key is not None:
				current_stack.append(last_block_key)
				if VERBOSE_LEVEL >= VERBOSE_HELPER_DATA:
					print(f"{current_stack} # CREATED BLOCK")
				last_block_key = None
			output_lines.append(line)
			continue
		
		elif stripped == NESTING_CLOSE:
			if current_stack:
				current_stack.pop()
				if VERBOSE_LEVEL >= VERBOSE_HELPER_DATA:
					print(f"{current_stack}")
			output_lines.append(line)
			continue
		
		if not stripped or stripped.startswith("//"):
			output_lines.append(line)
			continue
		
		clean_line = strip_inline_comment(stripped)
		
		block_match = BLOCK_PATTERN.match(clean_line)
		if block_match:
			last_block_key = block_match.group(1).strip('"')
			if VERBOSE_LEVEL >= VERBOSE_HELPER_DATA:
				# """it accepts matching empty name like in json that the top block has no name... but nested at least should all have block name otherwise it will be impossible to update the proper block/keyValue in case of conflicts (would update them all? that would be just a mess)"""
				print(f"{current_stack} # DETECTED POSSIBLE BLOCK")
		else:
			try:
				clean_line_for_kv = clean_and_validate_for_kv(args.target, line_num, clean_line)
			except ValidationError:
				output_lines.append(line)
				continue
			
			kv_match = KV_PATTERN.match(clean_line_for_kv)
			if kv_match:
				key, val = kv_match.groups()
				full_path = ".".join(current_stack + [key])
				
				if full_path in patches:
					new_val = patches[full_path]
					# Safely escape special regex characters in the new value
					escaped_val = re.escape(new_val)
					"""values may have spaces or be empty like """
					line = re.sub(
						r'(\s*"[^"]+"\s+)("[^"]*")(.*)',
						r'\1"' + escaped_val + r'"\3',
						line
					)
					applied_keys.add(full_path)
				else:
					if VERBOSE_LEVEL >= VERBOSE_BUG_TRACKING:
						print(f"{args.target}:{line_num}:\n{full_path}\n{line}\n{clean_line}\n{clean_line_for_kv}")
				last_block_key = None
		
		output_lines.append(line)
	
	requested_keys = set(patches.keys())
	missing_keys = requested_keys - applied_keys
	
	print("\n" + "="*50)
	print("PATCH EXECUTION SUMMARY")
	print("="*50)
	print(f"Total requested updates: {len(requested_keys)}")
	print(f"Successfully modified:   {len(applied_keys)}")
	print(f"Missing items:           {len(missing_keys)}")
	
	if len(applied_keys) == 0:
		print(f"\n[WARNING] No successfully modified items. This may indicate:")
		print("  - Patcher requires improvement")
		print("  - Files need manual fixes for syntax issues\n")
	
	if missing_keys:
		print("\nMissing items detected:")
		for key in sorted(missing_keys):
			print(f"  - {key}")
		
		if args.append_missing:
			print("\n[INFO] '--append-missing' flag active. Injecting missing options...")
			missing_patches_dict = {k: patches[k] for k in missing_keys}
			output_lines = append_nested_missing(output_lines, missing_patches_dict)
			print(f"Successfully appended all {len(missing_keys)} missing options.")
		else:
			print("\n[CRITICAL ERROR] Operation aborted. No files were modified.", file=sys.stderr)
			print("Rerun with the -a/--append-missing flag to inject missing options.", file=sys.stderr)
			sys.exit(2)
	
	output_destination = args.output if args.output else args.target
	try:
		with open(output_destination, 'w', encoding='utf-8') as f:
			f.writelines(output_lines)
	except IOError as e:
		print(f"Error writing output file: {e}", file=sys.stderr)
		sys.exit(2)
	
	print(f"\nFinal Result: Saved to -> {output_destination}")

# ==========================================
# MAIN INTERFACE & SUBCOMMAND ROUTING
# ==========================================

if __name__ == "__main__":
	parser = argparse.ArgumentParser(
		description="Unified Windows-Compatible Patcher for Dark Messiah .qct files.",
		epilog="""
Examples:
  %(prog)s create base.qct modded.qct -o weapon_tweak.kvpatch.json
  %(prog)s apply target.qct weapon_tweak.kvpatch.json
  %(prog)s apply target.qct weapon_tweak.kvpatch.json -a
		""",
		formatter_class=argparse.RawDescriptionHelpFormatter
	)
	subparsers = parser.add_subparsers(dest="command", required=True, help="Subcommands")

	# 'create' subcommand
	parser_create = subparsers.add_parser("create", help="Generate a JSON patch by comparing two files")
	parser_create.add_argument("original", help="Path to original/vanilla file")
	parser_create.add_argument("modified", help="Path to your modified file")
	"""default="patch.json" is actually a hint for the better dynamic default"""
	parser_create.add_argument("-o", "--output", default="patch.json",
		help="Output patch JSON name (default: <modified>.kvpatch.json)")
	parser_create.set_defaults(func=handle_create)

	# 'apply' subcommand
	parser_apply = subparsers.add_parser("apply", help="Apply a JSON patch to a target file")
	parser_apply.add_argument("target", help="The file you want to modify")
	parser_apply.add_argument("patch", help="The patch JSON file to apply")
	parser_apply.add_argument("-o", "--output", help="Optional separate output path (default: overwrite target)")
	parser_apply.add_argument("-a", "--append-missing", action="store_true",
		help="Append missing option paths instead of raising an error")
	parser_apply.set_defaults(func=handle_apply)
	
	args = parser.parse_args()
	args.func(args)
