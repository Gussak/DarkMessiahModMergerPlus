#!/usr/bin/env python3

#  BSD 3-Clause License
#
#  Copyright (c) 2026, Gussak<https://github.com/Gussak>
#
#  Redistribution and use in source and binary forms, with or without
#  modification, are permitted provided that the following conditions are met:
#
#  1. Redistributions of source code must retain the above copyright notice, this
#     list of conditions and the following disclaimer.
#
#  2. Redistributions in binary form must reproduce the above copyright notice,
#     this list of conditions and the following disclaimer in the documentation
#     and/or other materials provided with the distribution.
#
#  3. Neither the name of the copyright holder nor the names of its
#     contributors may be used to endorse or promote products derived from
#     this software without specific prior written permission.
#
#  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
#  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
#  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
#  DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
#  FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
#  DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
#  SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
#  CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
#  OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
#  OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# example USAGE:
# ./keyValuePatcher.py --help
# ./keyValuePatcher.py create -o weapon_tweak.kvpatch.json base.qct modded.qct
# ./keyValuePatcher.py apply weapon_tweak.qct weapon_tweak.kvpatch.json
# ./keyValuePatcher.py create --help
# ./keyValuePatcher.py apply --help

import argparse
import json
import os
import re
import sys

# ==========================================
# REUSABLE PARSING LOGIC
# ==========================================

nesting_open = os.getenv("KEYVALUE_NESTING_OPEN", "{")
nesting_close = os.getenv("KEYVALUE_NESTING_CLOSE", "}")
ending = os.getenv("KEYVALUE_LINE_ENDING", '\r\n')

def strip_inline_comment(line):
    """Helper to remove inline comments safely for clean regex evaluation."""
    if "//" in line:
        return line.split("//", 1)[0].strip()
    return line.strip()

def parse_qct_to_dict(file_path):
    """Parses a Valve KeyValues .qct file into a nested Python dictionary."""
    with open(file_path, 'r', encoding='utf-8', errors='ignore', newline='') as f:
        lines = f.readlines()

    root = {}
    stack = [root]
    last_key = None

    kv_pattern = re.compile(r'^\s*"?([^"\s]+)"?\s+"?([^"\s//]+)"?')
    block_pattern = re.compile(r'^\s*"?([^"\s//]+)"?')

    for line in lines:
        stripped = line.strip()
        
        if not stripped or stripped.startswith("//"):
            continue

        clean_line = strip_inline_comment(line)
        if not clean_line:
            continue

        if clean_line == nesting_open:
            if last_key is not None:
                new_block = {}
                stack[-1][last_key] = new_block
                stack.append(new_block)
                last_key = None
            continue

        if clean_line == nesting_close:
            if len(stack) > 1:
                stack.pop()
            continue

        kv_match = kv_pattern.match(clean_line)
        if kv_match:
            key, val = kv_match.groups()
            stack[-1][key] = val
            last_key = None
            continue

        block_match = block_pattern.match(clean_line)
        if block_match:
            last_key = block_match.group(1).strip('"')

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

def append_nested_missing(lines, missing_patches):
    """
    Simulates tree parsing line-by-line to find the closest matching structural depth
    and inject missing key-values nested precisely under their correct parent blocks.
    """
    block_pattern = re.compile(r'^\s*"?([^"\s//{}]+)"?')
    
    for full_path, new_value in missing_patches.items():
        parts = full_path.split('.')
        key_name = parts[-1]
        target_hierarchy = parts[:-1]
        
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

            if clean_line == nesting_open:
                if last_block_key:
                    current_stack.append(last_block_key)
                    open_braces[tuple(current_stack)] = idx
                    last_block_key = None
                continue
                
            if clean_line == nesting_close:
                if current_stack:
                    close_braces[tuple(current_stack)] = idx
                    current_stack.pop()
                continue
                
            block_match = block_pattern.match(clean_line)
            if block_match:
                last_block_key = block_match.group(1).strip('"')
            else:
                last_block_key = None

        matched_depth = 0
        for depth in range(len(target_hierarchy), 0, -1):
            check_path = tuple(target_hierarchy[:depth])
            if check_path in open_braces and check_path in close_braces:
                matched_depth = depth
                break
                
        new_lines = []
        
        if matched_depth == 0:
            insert_idx = len(lines)
            for i, part in enumerate(target_hierarchy):
                tabs = "\t" * i
                new_lines.append(f'{tabs}"{part}"{ending}')
                new_lines.append(f'{tabs}{{{ending}')
                
            final_tabs = "\t" * len(target_hierarchy)
            new_lines.append(f'{final_tabs}"{key_name}"\t\t"{new_value}"{ending}')
            
            for i in range(len(target_hierarchy) - 1, -1, -1):
                tabs = "\t" * i
                new_lines.append(f'{tabs}}}{ending}')
        else:
            matched_path = tuple(target_hierarchy[:matched_depth])
            missing_structure = target_hierarchy[matched_depth:]
            
            insert_idx = close_braces[matched_path]
            base_tabs = len(matched_path)
            
            for i, part in enumerate(missing_structure):
                tabs = "\t" * (base_tabs + i)
                new_lines.append(f'{tabs}"{part}"{ending}')
                new_lines.append(f'{tabs}{{{ending}')
                
            final_tabs = "\t" * (base_tabs + len(missing_structure))
            new_lines.append(f'{final_tabs}"{key_name}"\t\t"{new_value}"{ending}')
            
            for i in range(len(missing_structure) - 1, -1, -1):
                tabs = "\t" * (base_tabs + i)
                new_lines.append(f'{tabs}}}{ending}')

        lines[insert_idx:insert_idx] = new_lines

    return lines

# ==========================================
# COMMAND IMPLEMENTATIONS
# ==========================================

def handle_create(args):
    """Generates a patch JSON file by comparing original and modified configs."""
    if not os.path.exists(args.original):
        print(f"Error: Original file '{args.original}' not found.")
        sys.exit(2)
    if not os.path.exists(args.modified):
        print(f"Error: Modified file '{args.modified}' not found.")
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
    if output_destination.startswith("patch.json"):
        output_destination = args.modified + ".kvpatch.json"

    with open(output_destination, 'w', encoding='utf-8', newline=ending) as f:
        json.dump(patch_data, f, indent=4)
        f.write(ending)
        
    print(f"\nSuccess! Found {len(patch_data)} changes. Saved to:\n '{output_destination}'")
    
    if len(patch_data) > 0: #changes found
        sys.exit(1)
    else:
        sys.exit(0) # no changes found, files are probably identical in final results. unless there is a second setting for the same var value with a different value and the final engine reading it overwrites the first value read with the last found. But that is a file manual preparation bug. TODO? but this patcher could create overrides by always appending even if there is a var there what would work but is overkill.


def handle_apply(args):
    """Applies a patch JSON file onto a target config file."""
    if not os.path.exists(args.target):
        print(f"Error: Target file '{args.target}' not found.")
        sys.exit(2)
    if not os.path.exists(args.patch):
        print(f"Error: Patch file '{args.patch}' not found.")
        sys.exit(2)

    with open(args.patch, 'r', encoding='utf-8') as f:
        patches = json.load(f)
        
    with open(args.target, 'r', encoding='utf-8', errors='ignore', newline='') as f:
        lines = f.readlines()

    current_stack = []
    output_lines = []
    applied_keys = set()
    
    kv_pattern = re.compile(r'^\s*"?([^"\s]+)"?\s+"?([^"\s]+)"?')
    block_pattern = re.compile(r'^\s*"?([^"\s]+)"?')

    print(f"Applying patches from '{args.patch}' onto '{args.target}'...")

    for line in lines:
        if line.endswith('\r\n'): #windows
            line = line.rstrip('\r\n')
        if line.endswith('\n'): #linux
            line = line.rstrip('\n')
        if line.endswith('\r'): #mac
            line = line.rstrip('\r')
        line = line + ending
        
        stripped = line.strip()
        clean_line = strip_inline_comment(line)
        
        if stripped == nesting_open:
            output_lines.append(line)
            continue
        elif stripped == nesting_close:
            if current_stack:
                current_stack.pop()
            output_lines.append(line)
            continue
        if not stripped or stripped.startswith("//"):
            output_lines.append(line)
            continue
            
        kv_match = kv_pattern.match(clean_line)
        if kv_match:
            key, val = kv_match.groups()
            full_path = ".".join(current_stack + [key])
            
            if full_path in patches:
                new_val = patches[full_path]
                
                if '"' in line:
                    line = re.sub(r'(\s*"[^"]*"\s+)("[^"]*")(.*)', r'\1"' + new_val + r'"\3', line) #values may have spaces
                else:
                    print(f"Error: keys and values shall be between double quotes.")
                    sys.exit(2)
                    #line = re.sub(r'(\s+)('+re.escape(val)+r')(\s*)$', r'\1' + new_val + r'\3', line) # this just seeks for the value and replaces it. may be enforce an exit 2 if there is no double quotes instead?
                
                applied_keys.add(full_path)
            output_lines.append(line)
        else:
            block_match = block_pattern.match(clean_line)
            if block_match:
                current_stack.append(block_match.group(1).strip('"'))
            output_lines.append(line)
    
    # PROCESS MATCH VERIFICATION
    requested_keys = set(patches.keys())
    missing_keys = requested_keys - applied_keys

    print("\n" + "="*40)
    print("PATCH EXECUTION SUMMARY")
    print("="*40)
    print(f"Total requested updates: {len(requested_keys)}")
    print(f"Successfully modified:  {len(applied_keys)}")
    print(f"Missing items:          {len(missing_keys)}")
    if len(applied_keys) == 0: # if this happens, this patcher may require improvement
        print(f"\n[WARNING] No successfully modified items may mean this patcher requires improvement. Or the files need manual or a pre-patch fixer for minor syntax issues.\n")
    
    if missing_keys:
        print("\nMissing items detected:")
        for key in missing_keys:
            print(f"  - {key}")
            
        if args.append_missing:
            print("\n[INFO] '--append-missing' flag is active. Injecting missing options...")
            missing_patches_dict = {k: patches[k] for k in missing_keys}
            output_lines = append_nested_missing(output_lines, missing_patches_dict)
            print(f"Successfully appended all {len(missing_keys)} missing options.")
        else:
            print("\n[CRITICAL ERROR] Operation aborted. No files were modified.", file=sys.stderr)
            print("To append these options instead of failing, rerun the command with the -a flag.", file=sys.stderr)
            sys.exit(2)

    # Save destination file with forced Windows CRLF line ending compatibility already fixed above
    output_destination = args.output if args.output else args.target
    with open(output_destination, 'w', encoding='utf-8', newline='') as f:
        f.writelines(output_lines)
        
    print(f"\nFinal Result: Saved perfectly to -> {output_destination}")


# ==========================================
# MAIN INTERFACE & SUBCOMMAND ROUTING
# ==========================================

if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Unified Windows-Compatible Patcher for Dark Messiah .qct files."
    )
    subparsers = parser.add_subparsers(dest="command", required=True, help="Subcommands")

    # 'create' subcommand setup
    parser_create = subparsers.add_parser("create", help="Generate a JSON patch by comparing two files")
    parser_create.add_argument("original", help="Path to original/vanilla file")
    parser_create.add_argument("modified", help="Path to your modified file 'PathToModified'")
    parser_create.add_argument("-o", "--output", default="patch.json", help="Output patch JSON name (default is to create a 'PathToModified.kvpatch.json' file)") # default="patch.json" is actually a hint for the better dynamic default
    parser_create.set_defaults(func=handle_create)

    # 'apply' subcommand setup
    parser_apply = subparsers.add_parser("apply", help="Apply a JSON patch to a target file")
    parser_apply.add_argument("target", help="The file you want to modify")
    parser_apply.add_argument("patch", help="The patch JSON file to use")
    parser_apply.add_argument("-o", "--output", help="Optional separate output path (default: overwrite target)")
    parser_apply.add_argument(
        "-a", "--append-missing", 
        action="store_true", 
        help="If option paths are missing from target config, append them instead of raising an error."
    )
    parser_apply.set_defaults(func=handle_apply)

    args = parser.parse_args()
    args.func(args)

